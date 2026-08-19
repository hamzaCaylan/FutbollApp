import 'package:flutter/material.dart';

/// A fixed-size framed container overlaid on the pitch - used for the
/// broadcaster ad banners (top/bottom-center) and the channel icon
/// (top-left). Shows [imageUrl] via [Image.network] when set, otherwise a
/// dashed placeholder naming the reserved slot so it stays visible/
/// discoverable even before an image is configured in Ayarlar.
class PitchImageOverlay extends StatelessWidget {
  const PitchImageOverlay({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    required this.placeholderLabel,
    this.borderRadius = 8,
  });

  final String? imageUrl;
  final double width;
  final double height;
  final String placeholderLabel;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white24),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? Center(
              child: Text(
                placeholderLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            )
          : Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Text(
                  placeholderLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
            ),
    );
  }
}
