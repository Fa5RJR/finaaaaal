import 'package:al_sharif/core/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProductDetailsScreen extends StatelessWidget {
  final Map product;

  const ProductDetailsScreen({super.key, required this.product});

  static const Color primaryTeal = Color(0xFF20A6A0);

  static String heroTagFor(Map product) =>
      'product_image_${product['id'] ?? product['name']}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final String name = product['name']?.toString() ?? '';
    final String description = product['description']?.toString() ?? '';
    final String imageUrl =
    (product['images_url']?.toString() ?? '').split(',').first.trim();

    final num? price = product['price'] as num?;
    final String? priceText = price == null
        ? null
        : (price % 1 == 0 ? price.toInt() : price).toString();

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          name,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: heroTagFor(product),
              child: Container(
                width: double.infinity,
                height: 260,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: _buildImage(imageUrl),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              name,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: cs.primary),
            ),
            if (priceText != null) ...[
              const SizedBox(height: 6),
              Text(
                'يبدأ من {} جنيه'.tr(args: [priceText]),
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: primaryTeal),
              ),
            ],
            const SizedBox(height: 16),
            Text('الوصف'.tr(),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cs.primary)),
            const SizedBox(height: 8),
            Text(description,
                style: const TextStyle(
                    fontSize: 14, height: 1.6, color: Colors.grey)),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.calculate_outlined),
              label: Text('احسب التكلفة التقديرية'.tr(),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.priceEstimation,
                  arguments: product,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String url) {
    if (url.isEmpty) return _fallback();

    const loader = Center(
      child: CircularProgressIndicator(color: primaryTeal),
    );

    // صورة من الـ assets (المسار مش بيبدأ بـ http)
    if (!url.startsWith('http')) {
      return SvgPicture.asset(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    // SVG من النت
    if (url.toLowerCase().contains('.svg')) {
      return SvgPicture.network(
        url,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => loader,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    // صورة عادية png/jpg من النت
    return Image.network(
      url,
      fit: BoxFit.contain,
      loadingBuilder: (_, child, progress) =>
      progress == null ? child : loader,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() => const Center(
    child: Icon(Icons.accessibility_new_rounded,
        size: 90, color: Colors.grey),
  );
}