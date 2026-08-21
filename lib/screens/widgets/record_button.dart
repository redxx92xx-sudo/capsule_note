import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class RecordButton extends StatelessWidget {
  final bool isRecording;
  final AnimationController rippleController;
  final VoidCallback onRecordStart;
  final VoidCallback onRecordEnd;

  const RecordButton({
    super.key,
    required this.isRecording,
    required this.rippleController,
    required this.onRecordStart,
    required this.onRecordEnd,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isRecording)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.nightCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.4, 1.4),
                      duration: 600.ms,
                    ),
                const SizedBox(width: 8),
                Text(
                  l10n.recordingListening,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.nightText : AppTheme.inkBlack,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.2, end: 0),

        Stack(
          alignment: Alignment.center,
          children: [
            if (isRecording)
              AnimatedBuilder(
                animation: rippleController,
                builder: (context, child) {
                  final value = rippleController.value;
                  return Container(
                    width: 72 + (value * 50),
                    height: 72 + (value * 50),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (isDark ? const Color(0xFF6B8CAE) : AppTheme.inkBlue)
                            .withValues(alpha: (1.0 - value).clamp(0.0, 1.0)),
                        width: 2.0,
                      ),
                    ),
                  );
                },
              ),

            GestureDetector(
              onLongPressStart: (_) => onRecordStart(),
              onLongPressEnd: (_) => onRecordEnd(),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.tapToRecordHint),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isRecording ? 76 : 68,
                height: isRecording ? 76 : 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRecording
                      ? (isDark ? const Color(0xFF8FA8BF) : AppTheme.inkBlue)
                      : (isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard),
                  border: Border.all(
                    color: isDark ? const Color(0xFF4A6572) : AppTheme.inkBlue,
                    width: 2.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.black : AppTheme.inkBlue).withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isRecording ? Icons.mic : Icons.mic_none_outlined,
                    size: isRecording ? 34 : 30,
                    color: isRecording
                        ? Colors.white
                        : (isDark ? AppTheme.nightText : AppTheme.inkBlue),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
