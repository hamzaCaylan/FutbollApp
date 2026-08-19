import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Trimmed-down top bar: just the back button (left) and "Yeni Plan"
/// (right). Everything else that used to live here (Kaydet/Paylaş/Geri Al/
/// Yinele/JSON Dışa-İçe Aktar/Tam Ekran/dizliş seçici/plan adı) moved into
/// the Araçlar panel and the Diziliş/Kayıtlar side panels so no feature was
/// dropped, just relocated.
class PitchTopBar extends StatelessWidget {
  const PitchTopBar({super.key, required this.onBack, required this.onNewPlan});

  final VoidCallback onBack;
  final VoidCallback onNewPlan;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: AppColors.panelDark,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(onPressed: onBack, icon: const Icon(Icons.chevron_left)),
          OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Takımlarım'),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: onNewPlan,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Yeni Plan'),
          ),
        ],
      ),
    );
  }
}
