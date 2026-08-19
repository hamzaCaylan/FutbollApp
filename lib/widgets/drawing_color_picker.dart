import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The thickness presets offered next to the color swatches - "ince" (thin),
/// "orta" (medium, the default new shapes start with) and "kalın" (thick).
const List<double> thicknessPresets = [2, 4, 7];

class DrawingColorPicker extends StatelessWidget {
  const DrawingColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
    required this.selectedThickness,
    required this.onThicknessChanged,
    this.showColorSwatches = true,
  });

  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;

  final double selectedThickness;
  final ValueChanged<double> onThicknessChanged;

  /// False for tools with their own fixed palette (e.g. the heat map's
  /// red-to-yellow gradient) - only the thickness dots show, since picking
  /// a color wouldn't do anything for them.
  final bool showColorSwatches;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.panelDark.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showColorSwatches) ...[
            for (final color in AppColors.drawingPalette)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: GestureDetector(
                  onTap: () => onColorChanged(color),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.toARGB32() == selectedColor.toARGB32()
                            ? Colors.white
                            : Colors.black26,
                        width: color.toARGB32() == selectedColor.toARGB32()
                            ? 2.5
                            : 1,
                      ),
                    ),
                  ),
                ),
              ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: SizedBox(
                width: 22,
                child: Divider(color: Colors.white24, height: 1),
              ),
            ),
          ],
          for (final thickness in thicknessPresets)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: GestureDetector(
                onTap: () => onThicknessChanged(thickness),
                child: Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: thickness == selectedThickness
                          ? Colors.white
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Container(
                    width: thickness + 6,
                    height: thickness + 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
