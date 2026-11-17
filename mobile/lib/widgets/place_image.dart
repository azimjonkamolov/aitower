import 'package:flutter/material.dart';
import '../models/attraction.dart';
import '../theme.dart';

/// Joy rasmi (APK ichida, oflayn). Rasm bo'lmasa — toifa rangidagi gradient va belgi.
class PlaceImage extends StatelessWidget {
  final Attraction a;
  final BoxFit fit;
  const PlaceImage(this.a, {super.key, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final s = CatStyle.of(a.category);
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [s.bg, Color.lerp(s.bg, s.fg, 0.35)!], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Center(child: Icon(s.icon, size: 44, color: s.fg.withValues(alpha: 0.55))),
    );
    if (a.image == null) return fallback;
    return Image.asset('assets/photos/${a.image}', fit: fit, errorBuilder: (_, __, ___) => fallback);
  }
}
