import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../core/constants.dart';

class HomeLoadingShimmer extends StatelessWidget {
  const HomeLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.cardDark
        : Colors.grey.shade300;
    final highlightColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF333333)
        : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: const [
          _ShimmerBox(height: 52, horizontal: 20, radius: 12),
          SizedBox(height: 16),
          _ShimmerBox(height: 160, horizontal: 20, radius: 20),
          SizedBox(height: 12),
          _ShimmerBox(height: 96, horizontal: 20, radius: 20),
          SizedBox(height: 24),
          _ShimmerBox(height: 24, horizontal: 20, widthFactor: 0.5, radius: 8),
          SizedBox(height: 12),
          _ShimmerBox(height: 84, horizontal: 20, radius: 14),
          SizedBox(height: 10),
          _ShimmerBox(height: 84, horizontal: 20, radius: 14),
          SizedBox(height: 10),
          _ShimmerBox(height: 84, horizontal: 20, radius: 14),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double height;
  final double horizontal;
  final double radius;
  final double? widthFactor;

  const _ShimmerBox({
    required this.height,
    required this.horizontal,
    required this.radius,
    this.widthFactor,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal),
      child: widthFactor == null
          ? child
          : FractionallySizedBox(widthFactor: widthFactor, child: child),
    );
  }
}
