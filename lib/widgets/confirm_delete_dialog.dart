import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

class ConfirmDeleteDialog extends StatelessWidget {
  final String title;
  final String message;

  const ConfirmDeleteDialog({
    super.key,
    required this.title,
    required this.message,
  });

  static Future<bool> show(
    BuildContext context, {
    String? title,
    required String message,
  }) async {
    final s = AppStrings.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmDeleteDialog(
        title: title ?? s.confirmDeleteTitle,
        message: message,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final s = AppStrings.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.divider),
      ),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colors.accent, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: TextStyle(
          fontSize: 15,
          height: 1.4,
          color: colors.textSecondary,
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(s.cancel, style: const TextStyle(fontSize: 15)),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(s.confirmDeleteTodo, style: const TextStyle(fontSize: 15)),
        ),
      ],
    );
  }
}
