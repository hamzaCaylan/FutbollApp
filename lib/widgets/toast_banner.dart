import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The small bottom-left feedback toast shown after user actions
/// (e.g. "Plan kaydedildi.").
class ToastBanner extends StatelessWidget {
  const ToastBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.panelDark.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }
}
