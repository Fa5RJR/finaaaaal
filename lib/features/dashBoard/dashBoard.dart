import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:al_sharif/core/routes/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum _Period { today, week, month, year }

enum _ChartKind { bar, line }

/// A single appointment row joined with its user.
class BookingItem {
  final int id;
  final String name;
  final String phone;
  final bool isHome;
  final String service;
  final String? address;
  final String? notes;
  final String status;
  final DateTime createdAt;
  final DateTime? bookingDate;

  const BookingItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.isHome,
    required this.service,
    required this.address,
    required this.notes,
    required this.status,
    required this.createdAt,
    required this.bookingDate,
  });

  /// The date used for all counts and charts.
  /// Change to `bookingDate ?? createdAt` to count by appointment date instead.
  DateTime get statDate => createdAt;

  factory BookingItem.fromMap(Map<String, dynamic> m) {
    final u = m['user'] as Map<String, dynamic>?;
    final bookingAddress = (m['address'] as String?)?.trim();
    final userAddress = (u?['address'] as String?)?.trim();
    final notes = (m['notes'] as String?)?.trim();

    final dateStr = m['appointment_date'] as String?;
    final timeStr = (m['appointment_time'] as String?) ?? '00:00:00';
    final appointment =
    dateStr == null ? null : DateTime.tryParse('${dateStr}T$timeStr');

    return BookingItem(
      id: (m['id'] as num).toInt(),
      name: (u?['name'] as String?) ?? '-',
      phone: (u?['phone'] as String?) ?? '-',
      isHome: m['visit_type'] == 'home',
      service: (m['service'] as String?) ?? '',
      address: (bookingAddress != null && bookingAddress.isNotEmpty)
          ? bookingAddress
          : userAddress,
      notes: (notes == null || notes.isEmpty) ? null : notes,
      status: (m['status'] as String?) ?? 'pending',
      createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
      bookingDate: appointment,
    );
  }
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryNavy = Color(0xFF123653);
  static const Color primaryTeal = Color(0xFF20A6A0);

  final SupabaseClient _client = Supabase.instance.client;
  late final TabController _tabController;

  bool _loading = true;
  bool _isAdmin = false;
  String? _error;
  List<BookingItem> _all = [];

  _Period _period = _Period.week;
  _ChartKind _chartKind = _ChartKind.bar;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await _client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.signin, (route) => false);
  }

  // ───────────────────────── Data ─────────────────────────

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      // Server-side check (see the SQL: public.is_admin()).
      final admin = (await _client.rpc('is_admin')) == true;
      if (!admin) {
        if (!mounted) return;
        setState(() {
          _isAdmin = false;
          _loading = false;
        });
        return;
      }

      final data = await _client
          .from('appointments')
          .select(
        'id, visit_type, service, appointment_date, appointment_time, '
            'address, notes, status, created_at, '
            'user:user_id(name, phone, address)',
      )
          .order('created_at', ascending: false);

      final items = (data as List)
          .map((e) => BookingItem.fromMap(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() {
        _isAdmin = true;
        _all = items;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Dashboard load error: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _periodStart {
    final now = DateTime.now();
    switch (_period) {
      case _Period.today:
        return _today;
      case _Period.week:
        return _today.subtract(const Duration(days: 6));
      case _Period.month:
        return _today.subtract(const Duration(days: 29));
      case _Period.year:
        return DateTime(now.year, now.month - 11, 1);
    }
  }

  String get _periodLabel {
    switch (_period) {
      case _Period.today:
        return 'اليوم'.tr();
      case _Period.week:
        return 'آخر 7 أيام'.tr();
      case _Period.month:
        return 'آخر 30 يوم'.tr();
      case _Period.year:
        return 'آخر 12 شهر'.tr();
    }
  }

  // Future-dated rows are ignored until their date arrives.
  List<BookingItem> get _filtered {
    final now = DateTime.now();
    return _all
        .where((b) =>
    !b.statDate.isBefore(_periodStart) && !b.statDate.isAfter(now))
        .toList();
  }

  int _countSince(DateTime start) {
    final now = DateTime.now();
    return _all
        .where((b) => !b.statDate.isBefore(start) && !b.statDate.isAfter(now))
        .length;
  }

  List<MapEntry<String, int>> _buckets() {
    final now = DateTime.now();
    final f = _filtered;

    switch (_period) {
      case _Period.today:
        return List.generate(
          24,
              (h) => MapEntry('$h', f.where((b) => b.statDate.hour == h).length),
        );
      case _Period.week:
      case _Period.month:
        final days = _period == _Period.week ? 7 : 30;
        return List.generate(days, (i) {
          final d = _today.subtract(Duration(days: days - 1 - i));
          final c = f
              .where((b) =>
          b.statDate.year == d.year &&
              b.statDate.month == d.month &&
              b.statDate.day == d.day)
              .length;
          return MapEntry('${d.day}/${d.month}', c);
        });
      case _Period.year:
        return List.generate(12, (i) {
          final m = DateTime(now.year, now.month - 11 + i, 1);
          final c = f
              .where((b) =>
          b.statDate.year == m.year && b.statDate.month == m.month)
              .length;
          return MapEntry('${m.month}/${m.year % 100}', c);
        });
    }
  }

  // ───────────────────────── UI ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final showTabs = !_loading && _isAdmin && _error == null;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        title: Text(
          'لوحة التحكم'.tr(),
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loading ? null : () => _load(),
          ),
          IconButton(
            tooltip: 'تسجيل الخروج'.tr(),
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: _logout,
          ),
        ],
        bottom: showTabs
            ? TabBar(
          controller: _tabController,
          indicatorColor: primaryTeal,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
                icon: const Icon(Icons.view_list_rounded),
                text: 'القائمة'.tr()),
            Tab(
                icon: const Icon(Icons.dashboard_rounded),
                text: 'الإحصائيات'.tr()),
            Tab(
                icon: const Icon(Icons.show_chart_rounded),
                text: 'الرسم البياني'.tr()),
          ],
        )
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: primaryTeal));
    }
    if (!_isAdmin) {
      return _messageView(
          Icons.lock_outline, 'غير مصرح لك بالدخول لهذه الصفحة.'.tr());
    }
    if (_error != null) {
      return _messageView(Icons.error_outline, 'تعذر تحميل البيانات.'.tr(),
          retry: true);
    }

    return Column(
      children: [
        _buildPeriodChips(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildListTab(),
              _buildCardsTab(),
              _buildChartTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _messageView(IconData icon, String text, {bool retry = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16)),
            if (retry) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _load(),
                child: Text('إعادة المحاولة'.tr()),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChips() {
    final items = <_Period, String>{
      _Period.today: 'اليوم'.tr(),
      _Period.week: 'آخر 7 أيام'.tr(),
      _Period.month: 'آخر 30 يوم'.tr(),
      _Period.year: 'آخر 12 شهر'.tr(),
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          for (final e in items.entries)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: Text(e.value),
                selected: _period == e.key,
                selectedColor: primaryTeal,
                labelStyle: TextStyle(
                  color: _period == e.key ? Colors.white : null,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => setState(() => _period = e.key),
              ),
            ),
        ],
      ),
    );
  }

  // ───────────────────────── Tab 1: list ─────────────────────────

  Widget _buildListTab() {
    final list = _filtered;

    return RefreshIndicator(
      color: primaryTeal,
      onRefresh: () => _load(silent: true),
      child: list.isEmpty
          ? ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          _messageView(Icons.event_busy_outlined,
              'لا توجد حجوزات في هذه الفترة.'.tr()),
        ],
      )
          : ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: list.length,
        itemBuilder: (context, i) => _buildBookingCard(list[i]),
      ),
    );
  }

  String _serviceLabel(String service) {
    switch (service) {
      case 'measurement':
        return 'قياس'.tr();
      case 'consultation':
        return 'استشارة'.tr();
      case 'followup':
        return 'متابعة'.tr();
      case 'fitting':
        return 'تركيب'.tr();
      default:
        return service;
    }
  }

  (String, Color) _statusInfo(String status) {
    switch (status) {
      case 'confirmed':
        return ('مؤكد'.tr(), Colors.green);
      case 'completed':
        return ('مكتمل'.tr(), Colors.blueGrey);
      case 'cancelled':
        return ('ملغي'.tr(), Colors.red);
      default:
        return ('قيد الانتظار'.tr(), Colors.orange);
    }
  }

  Widget _buildBookingCard(BookingItem b) {
    final (statusText, statusColor) = _statusInfo(b.status);
    final date = b.bookingDate ?? b.createdAt;
    final dateText = DateFormat('yyyy/MM/dd  hh:mm a', context.locale.languageCode)
        .format(date);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: primaryNavy,
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    b.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _infoRow(Icons.phone_outlined, b.phone, selectable: true),
            _infoRow(
              b.isHome ? Icons.home_outlined : Icons.local_hospital_outlined,
              b.isHome ? 'زيارة منزلية'.tr() : 'حجز داخل المركز'.tr(),
            ),
            if (b.isHome)
              _infoRow(
                Icons.location_on_outlined,
                (b.address == null || b.address!.isEmpty)
                    ? 'لا يوجد عنوان'.tr()
                    : b.address!,
                selectable: true,
              ),
            if (b.service.isNotEmpty)
              _infoRow(Icons.medical_services_outlined, _serviceLabel(b.service)),
            _infoRow(Icons.event_outlined, dateText),
            if (b.notes != null) _infoRow(Icons.notes_outlined, b.notes!),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {bool selectable = false}) {
    final style = const TextStyle(fontSize: 14, height: 1.3);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: primaryTeal),
          const SizedBox(width: 8),
          Expanded(
            child: selectable
                ? SelectableText(text, style: style)
                : Text(text, style: style),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Tab 2: cards + donut ─────────────────────────

  Widget _buildCardsTab() {
    final f = _filtered;
    final home = f.where((b) => b.isHome).length;
    final center = f.length - home;

    return RefreshIndicator(
      color: primaryTeal,
      onRefresh: () => _load(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _cardsRow(
            _statCard(Icons.today_rounded, 'حجوزات اليوم'.tr(),
                _countSince(_today), primaryTeal),
            _statCard(
                Icons.date_range_rounded,
                'حجوزات آخر 7 أيام'.tr(),
                _countSince(_today.subtract(const Duration(days: 6))),
                primaryNavy),
          ),
          const SizedBox(height: 12),
          _cardsRow(
            _statCard(
                Icons.calendar_month_rounded,
                'حجوزات آخر 30 يوم'.tr(),
                _countSince(_today.subtract(const Duration(days: 29))),
                const Color(0xFF3F7CAC)),
            _statCard(Icons.bookmark_rounded, 'إجمالي الحجوزات'.tr(),
                _all.length, const Color(0xFFE08E45)),
          ),
          const SizedBox(height: 16),
          Card(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'توزيع الحجوزات حسب النوع'.tr(),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(_periodLabel,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 16),
                  _buildDonut(home, center),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardsRow(Widget a, Widget b) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: a),
          const SizedBox(width: 12),
          Expanded(child: b),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String title, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.75)],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            '$value',
            style: const TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDonut(int home, int center) {
    final total = home + center;
    if (total == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('لا توجد حجوزات في هذه الفترة.'.tr())),
      );
    }

    PieChartSectionData section(int v, Color c) => PieChartSectionData(
      value: v.toDouble(),
      color: c,
      radius: 30,
      title: v == 0 ? '' : '${(v * 100 / total).round()}%',
      titleStyle: const TextStyle(
          color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
    );

    return Row(
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 48,
                  sections: [
                    section(home, primaryNavy),
                    section(center, primaryTeal),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$total',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('إجمالي'.tr(), style: const TextStyle(fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _legend(primaryNavy, 'زيارة منزلية'.tr(), home),
              const SizedBox(height: 10),
              _legend(primaryTeal, 'حجز داخل المركز'.tr(), center),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legend(Color color, String label, int value) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ───────────────────────── Tab 3: charts ─────────────────────────

  Widget _buildChartTab() {
    final data = _buckets();
    final total = _filtered.length;

    return RefreshIndicator(
      color: primaryTeal,
      onRefresh: () => _load(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'عدد الحجوزات'.tr(),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$_periodLabel • $total',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      ToggleButtons(
                        borderRadius: BorderRadius.circular(10),
                        constraints:
                        const BoxConstraints(minHeight: 36, minWidth: 40),
                        selectedColor: Colors.white,
                        fillColor: primaryTeal,
                        isSelected: [
                          _chartKind == _ChartKind.bar,
                          _chartKind == _ChartKind.line,
                        ],
                        onPressed: (i) => setState(() => _chartKind =
                        i == 0 ? _ChartKind.bar : _ChartKind.line),
                        children: const [
                          Icon(Icons.bar_chart_rounded, size: 20),
                          Icon(Icons.show_chart_rounded, size: 20),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (total == 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                          child: Text('لا توجد حجوزات في هذه الفترة.'.tr())),
                    )
                  else
                    SizedBox(
                      height: 260,
                      // Time always flows left to right, even in Arabic.
                      child: Directionality(
                        textDirection: ui.TextDirection.ltr,
                        child: _chartKind == _ChartKind.bar
                            ? _buildBarChart(data)
                            : _buildLineChart(data),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _maxY(List<MapEntry<String, int>> data) {
    final maxVal = data.fold<int>(0, (m, e) => e.value > m ? e.value : m);
    return (maxVal < 4 ? 4 : maxVal + 1).toDouble();
  }

  FlTitlesData _titles(List<MapEntry<String, int>> data) {
    final maxY = _maxY(data);
    final step = math.max(1, (data.length / 6).ceil());

    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          interval: maxY <= 8 ? 1 : (maxY / 5).ceilToDouble(),
          getTitlesWidget: (v, meta) => Text(
            v.toInt().toString(),
            style: const TextStyle(fontSize: 10),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          interval: 1,
          getTitlesWidget: (value, meta) {
            final i = value.toInt();
            if (i < 0 || i >= data.length || i % step != 0) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(data[i].key, style: const TextStyle(fontSize: 10)),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBarChart(List<MapEntry<String, int>> data) {
    return BarChart(
      BarChartData(
        maxY: _maxY(data),
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: _titles(data),
        barGroups: [
          for (var i = 0; i < data.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[i].value.toDouble(),
                  color: primaryTeal,
                  width: data.length > 15 ? 6 : 14,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<MapEntry<String, int>> data) {
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
        maxY: _maxY(data),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: _titles(data),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < data.length; i++)
                FlSpot(i.toDouble(), data[i].value.toDouble()),
            ],
            isCurved: true,
            color: primaryTeal,
            barWidth: 3,
            dotData: FlDotData(show: data.length <= 12),
            belowBarData: BarAreaData(
              show: true,
              color: primaryTeal.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}