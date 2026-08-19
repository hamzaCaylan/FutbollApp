import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class FootballPitch extends StatelessWidget {
  const FootballPitch({super.key, required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: AppColors.pitchGrass,
        child: SizedBox.expand(
          child: Image.asset(imagePath, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
