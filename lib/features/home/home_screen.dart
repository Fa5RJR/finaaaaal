import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:al_sharif/features/ai_estimator/ai_screen.dart';
import 'package:al_sharif/features/booking/home_visit_booking_screen.dart';
import 'package:al_sharif/features/booking/center_booking_screen.dart';
import 'package:al_sharif/features/profile/profile.dart';
import 'package:al_sharif/features/rehab_videos/rehab_videos_screen.dart';
import 'package:al_sharif/features/details/detalis.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color primaryTeal = Color(0xFF20A6A0);

  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeDashboardContent(),
    const RehabVideosScreen(),
    const CenterBookingScreen(),
    const HomeVisitBookingScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'مركز الشريف للأطراف الصناعية'.tr(),
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: primaryTeal,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 13,
        unselectedFontSize: 11,
        onTap: (index) async {
          if (await Vibration.hasVibrator()) {
            Vibration.vibrate(duration: 40);
          }
          setState(() => _currentIndex = index);
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            label: 'الرئيسية'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.self_improvement),
            label: 'التأهيل النفسي'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.event_available),
            label: 'حجز موعد'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_work_outlined),
            label: 'زيارة منزلية'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_2_outlined),
            label: 'الملف الشخصي'.tr(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryTeal,
        child: const Icon(Icons.auto_awesome_outlined, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SmartAssistantScreen()),
          );
        },
      ),
    );
  }
}

class HomeDashboardContent extends StatefulWidget {
  const HomeDashboardContent({super.key});

  @override
  State<HomeDashboardContent> createState() => _HomeDashboardContentState();
}

class _HomeDashboardContentState extends State<HomeDashboardContent> {
  static const Color primaryTeal = Color(0xFF20A6A0);

  bool isGridView = true;
  late Future<List> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProductsFromSupabase();
  }

  Future<List> _fetchProductsFromSupabase() async {
    final response = await Supabase.instance.client
        .from('products')
        .select()
        .order('id');

    return List.from(response);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الأطراف الصناعية'.tr(),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.primary),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.grid_view,
                      color: isGridView ? primaryTeal : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        isGridView = true;
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.list,
                      color: !isGridView ? primaryTeal : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        isGridView = false;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'استعراض الأنواع الرئيسية للأطراف الصناعية المتاحة داخل المركز.'.tr(),
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          FutureBuilder<List>(
            future: _productsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SkeletonLoader(isGrid: isGridView);
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'حدث خطأ أثناء تحميل المنتجات: {}'.tr(args: [snapshot.error.toString()]),
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              final products = snapshot.data ?? [];
              if (products.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Text(
                      'لا توجد منتجات حالياً'.tr(),
                      style: TextStyle(fontSize: 15, color: cs.primary),
                    ),
                  ),
                );
              }

              return isGridView
                  ? GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.68,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _buildCard(
                    product: product,
                    title: product['name'] ?? '',
                    desc: product['description'] ?? '',
                    isGrid: true,
                  );
                },
              )
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildCard(
                      product: product,
                      title: product['name'] ?? '',
                      desc: product['description'] ?? '',
                      isGrid: false,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  /// صورة الكارت: من الـ assets لو المسار مش رابط، أو من النت لو رابط.
  Widget _cardImage(String url) {
    const fallback = Icon(
      Icons.accessibility_new_rounded,
      size: 44,
      color: Colors.grey,
    );

    if (url.isEmpty) return const Center(child: fallback);

    if (!url.startsWith('http')) {
      return SvgPicture.asset(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Center(child: fallback),
      );
    }

    if (url.toLowerCase().contains('.svg')) {
      return SvgPicture.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Center(child: fallback),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Center(child: fallback),
    );
  }

  Widget _buildCard({
    required Map product,
    required String title,
    required String desc,
    required bool isGrid,
  }) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(16);
    final imageUrl = product['images_url']?.toString() ?? '';

    // صفحة التفاصيل بتعرض أول صورة بس، فنفس الشيء هنا
    final firstImage = imageUrl.split(',').first.trim();

    Widget heroImage() => Hero(
      tag: ProductDetailsScreen.heroTagFor(product),
      child: _cardImage(firstImage),
    );

    final titleWidget = Text(
      title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: isGrid ? 14 : 16,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
    );

    final descWidget = Text(
      desc,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.3),
    );

    return Material(
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: theme.dividerColor),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: radius),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(product: product),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: isGrid
          // عرض الشبكة: الصورة فوق والنص تحتها
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 90,
                width: double.infinity,
                child: heroImage(),
              ),
              const SizedBox(height: 10),
              titleWidget,
              const SizedBox(height: 6),
              Expanded(child: descWidget),
            ],
          )
              : Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: heroImage(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    titleWidget,
                    const SizedBox(height: 6),
                    descWidget,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SkeletonLoader extends StatefulWidget {
  final bool isGrid;
  final int itemCount;

  const SkeletonLoader({super.key, required this.isGrid, this.itemCount = 6});

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(begin: 0.4, end: 1.0)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _bar(BuildContext context, {required double height, required double widthFactor}) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(25),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  Widget _skeletonCard(BuildContext context, {required bool isGrid}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isGrid) ...[
            _bar(context, height: 80, widthFactor: 1.0),
            const SizedBox(height: 10),
          ],
          _bar(context, height: isGrid ? 14 : 16, widthFactor: 0.6),
          const SizedBox(height: 10),
          _bar(context, height: 10, widthFactor: 1.0),
          const SizedBox(height: 6),
          _bar(context, height: 10, widthFactor: 0.85),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: widget.isGrid
          ? GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.68,
        ),
        itemCount: widget.itemCount,
        itemBuilder: (context, _) => _skeletonCard(context, isGrid: true),
      )
          : ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.itemCount,
        itemBuilder: (context, _) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _skeletonCard(context, isGrid: false),
        ),
      ),
    );
  }
}