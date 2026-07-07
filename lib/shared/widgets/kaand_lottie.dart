import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:dotlottie_flutter/dotlottie_flutter.dart';
import 'loading_indicator.dart';

class KaandLottie extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final bool loop;
  final bool autoplay;

  const KaandLottie({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.loop = true,
    this.autoplay = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDotLottie = assetPath.toLowerCase().endsWith('.lottie');

    if (isDotLottie) {
      return SizedBox(
        width: width,
        height: height,
        child: DotLottieView(
          source: assetPath,
          sourceType: 'asset',
          autoplay: autoplay,
          loop: loop,
        ),
      );
    } else {
      return Lottie.asset(
        assetPath,
        width: width,
        height: height,
        repeat: loop,
        animate: autoplay,
        errorBuilder: (context, error, stackTrace) {
          return const LoadingIndicator(size: 40);
        },
      );
    }
  }
}
