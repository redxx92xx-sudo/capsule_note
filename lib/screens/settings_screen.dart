import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/alarm_port.dart';
import '../services/backup_service.dart';
import '../services/notification_port.dart';
import '../services/todo_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsAllowed = true;

  Future<void> _selectDailySummaryTime(TodoProvider provider) async {
    final parts = provider.dailySummaryTime.split(':');
    final initialHour = int.tryParse(parts.first) ?? 9;
    final initialMin = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMin),
    );

    if (picked != null) {
      final newTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      await provider.setDailySummaryTime(newTime);
    }
  }

  Future<void> _handleExport(BuildContext context) async {
    final s = AppStrings.of(context);
    try {
      final path = await BackupService.instance.exportBackup();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.exportedPathMsg(path))));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.exportFailedMsg(e))));
    }
  }

  Future<void> _handleImport(BuildContext context) async {
    final s = AppStrings.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final loc = AppStrings.of(ctx);
        return AlertDialog(
          title: Text(loc.importBackup),
          content: Text(loc.importConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(loc.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(loc.restore),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final success = await BackupService.instance.importBackup();
      if (!context.mounted) return;
      if (success) {
        await context.read<TodoProvider>().loadTodos();
        if (!context.mounted) return;
        final previousSource =
            context.read<TodoProvider>().alarmSoundSource;
        final soundOk =
            await context.read<TodoProvider>().syncAlarmSoundAfterRestore();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.importSuccess)));
        if (!soundOk) {
          final hint = previousSource == AlarmSoundSource.system
              ? s.alarmSoundSystemInvalidHint
              : s.alarmSoundMissingHint;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(hint)),
          );
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.importFailedMsg(e))));
    }
  }

  void _showInfo(String title, String body) {
    showDialog(
      context: context,
      builder: (ctx) {
        final s = AppStrings.of(ctx);
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(s.gotIt),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickTheme(TodoProvider provider) async {
    final selected = await showModalBottomSheet<AppThemePreference>(
      context: context,
      backgroundColor: AppColors.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final colors = AppColors.of(ctx);
        final s = AppStrings.of(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    s.theme,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
              ...AppThemePreference.values.map((pref) {
                final active = provider.themePreference == pref;
                return ListTile(
                  title: Text(pref.localizedName(s)),
                  trailing: active
                      ? Icon(Icons.check, color: colors.accent)
                      : null,
                  onTap: () => Navigator.of(ctx).pop(pref),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (selected != null) {
      await provider.setThemePreference(selected);
    }
  }

  Future<void> _pickLanguage(TodoProvider provider) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final colors = AppColors.of(ctx);
        final s = AppStrings.of(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    s.language,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
              ...AppLocaleOption.all.map((pref) {
                final active = provider.localePreference == pref;
                return ListTile(
                  title: Text(s.languageLabel(pref)),
                  trailing: active
                      ? Icon(Icons.check, color: colors.accent)
                      : null,
                  onTap: () => Navigator.of(ctx).pop(pref),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (selected != null) {
      await provider.setLocalePreference(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TodoProvider>();
    final colors = AppColors.of(context);
    final s = AppStrings.of(context);

    final notifOk = _notificationsAllowed;
    final exactOk = provider.exactAlarmsAllowed;
    final fsiOk = provider.fullScreenIntentAllowed;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                s.settings,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _SettingsGroup(
              title: s.systemReminders,
              children: [
                _SettingsRow(
                  icon: Icons.notifications_outlined,
                  title: s.notifications,
                  status: notifOk ? s.enabled : null,
                  showBadge: !notifOk,
                  onTap: () async {
                    final granted = await NotificationPort.instance
                        .requestPermissions();
                    if (!mounted) return;
                    setState(() => _notificationsAllowed = granted);
                    if (!granted) {
                      _showInfo(s.notifications, s.notificationsDeniedHint);
                    }
                  },
                ),
                _SettingsRow(
                  icon: Icons.alarm_outlined,
                  title: s.alarmsAndReminders,
                  status: exactOk ? s.enabled : null,
                  showBadge: !exactOk,
                  onTap: () async {
                    if (!exactOk && AlarmPort.isConfigured) {
                      await AlarmPort.instance.openExactAlarmSettings();
                    } else {
                      _showInfo(
                        s.alarmsAndReminders,
                        exactOk
                            ? s.exactAlarmGrantedHint
                            : s.exactAlarmDeniedHint,
                      );
                    }
                  },
                ),
                _SettingsRow(
                  icon: Icons.smartphone_outlined,
                  title: s.fullScreenReminder,
                  status: fsiOk ? s.enabled : null,
                  showBadge: !fsiOk,
                  onTap: () async {
                    if (!fsiOk && AlarmPort.isConfigured) {
                      await AlarmPort.instance.openFullScreenIntentSettings();
                    } else {
                      _showInfo(
                        s.fullScreenReminder,
                        fsiOk
                            ? s.fullScreenGrantedHint
                            : s.fullScreenDeniedHint,
                      );
                    }
                  },
                ),
                _SettingsRow(
                  icon: Icons.battery_saver_outlined,
                  title: s.batteryBackground,
                  showBadge: true,
                  onTap: () => _showInfo(
                    s.batteryBackground,
                    s.batteryBackgroundHint,
                  ),
                ),
                _SettingsRow(
                  icon: Icons.summarize_outlined,
                  title: s.dailySummary,
                  status: provider.dailySummaryEnabled
                      ? provider.dailySummaryTime
                      : s.disabled,
                  trailing: Switch(
                    value: provider.dailySummaryEnabled,
                    onChanged: provider.setDailySummaryEnabled,
                  ),
                  showChevron: false,
                  onTap: () async {
                    if (!provider.dailySummaryEnabled) {
                      await provider.setDailySummaryEnabled(true);
                    }
                    if (!mounted) return;
                    await _selectDailySummaryTime(provider);
                  },
                ),
                _SettingsRow(
                  icon: Icons.timelapse_outlined,
                  title: s.persistentReminder,
                  status: s.intervalLabel(provider.persistentIntervalMinutes),
                  onTap: () => _pickPersistentDefaults(provider),
                ),
                _SettingsRow(
                  icon: Icons.music_note_outlined,
                  title: s.alarmSound,
                  status: provider.hasCustomAlarmSound
                      ? (provider.alarmSoundDisplayName ?? s.alarmSoundDefault)
                      : s.alarmSoundDefault,
                  onTap: () => _pickAlarmSoundOptions(provider),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SettingsGroup(
              title: s.dataSection,
              children: [
                _SettingsRow(
                  icon: Icons.upload_outlined,
                  title: s.exportBackup,
                  onTap: () => _handleExport(context),
                ),
                _SettingsRow(
                  icon: Icons.download_outlined,
                  title: s.importBackup,
                  onTap: () => _handleImport(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SettingsGroup(
              title: s.appearanceLanguage,
              children: [
                _SettingsRow(
                  icon: Icons.palette_outlined,
                  title: s.theme,
                  status: provider.themePreference.localizedName(s),
                  onTap: () => _pickTheme(provider),
                ),
                _SettingsRow(
                  icon: Icons.language_outlined,
                  title: s.language,
                  status: s.languageLabel(provider.localePreference),
                  onTap: () => _pickLanguage(provider),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SettingsGroup(
              title: s.aboutSection,
              children: [
                _SettingsRow(
                  icon: Icons.info_outline,
                  title: s.version,
                  status: '1.0.2+3',
                  showChevron: false,
                ),
                _SettingsRow(
                  icon: Icons.alarm_on_outlined,
                  title: s.testAlarm,
                  onTap: () async {
                    if (!AlarmPort.isConfigured) return;
                    await AlarmPort.instance.previewAlarm(
                      title: s.previewAlarmTitle,
                      notes: s.previewAlarmNotes,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s.testAlarmScheduled)),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPersistentDefaults(TodoProvider provider) async {
    final colors = AppColors.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final s = AppStrings.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.persistentReminder,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  s.defaultInterval,
                  style: TextStyle(color: colors.textSecondary),
                ),
                DropdownButton<int>(
                  value: provider.persistentIntervalMinutes,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(value: 30, child: Text(s.minutes30)),
                    DropdownMenuItem(value: 60, child: Text(s.hour1)),
                    DropdownMenuItem(value: 180, child: Text(s.hours3)),
                    DropdownMenuItem(value: 1440, child: Text(s.daily)),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      provider.setPersistentIntervalMinutes(val);
                      Navigator.of(ctx).pop();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAlarmSoundOptions(TodoProvider provider) async {
    final colors = AppColors.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final s = AppStrings.of(ctx);
        final current = provider.hasCustomAlarmSound
            ? (provider.alarmSoundDisplayName ?? s.alarmSoundDefault)
            : s.alarmSoundDefault;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Text(
                    s.alarmSound,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Text(
                    current,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.alarm_outlined),
                  title: Text(s.alarmSoundPickSystem),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    try {
                      final ok = await provider.pickSystemRingtone();
                      if (!mounted || !ok) return;
                    } catch (_) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.alarmSoundPreviewFailed)),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.folder_open_outlined),
                  title: Text(s.alarmSoundPickFile),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    try {
                      final ok = await provider.pickAlarmSound();
                      if (!mounted || !ok) return;
                    } catch (_) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.alarmSoundCopyFailed)),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.play_arrow_outlined),
                  title: Text(s.alarmSoundPreview),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final played = await provider.previewAlarmSound();
                    if (!mounted) return;
                    if (!played) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.alarmSoundPreviewFailed)),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.restart_alt_outlined),
                  title: Text(s.alarmSoundReset),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await provider.clearAlarmSound();
                  },
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      provider.stopAlarmSoundPreview();
    });
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 52,
                    endIndent: 0,
                    color: colors.divider,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsBadge extends StatelessWidget {
  const _SettingsBadge();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final s = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.badgeBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        s.needsSetup,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.badgeForeground,
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? status;
  final bool showBadge;
  final bool showChevron;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    this.status,
    this.showBadge = false,
    this.showChevron = true,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: colors.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ),
            if (showBadge) ...[
              const _SettingsBadge(),
              const SizedBox(width: 8),
            ] else if (status != null) ...[
              Text(
                status!,
                style: TextStyle(fontSize: 14, color: colors.textSecondary),
              ),
              const SizedBox(width: 8),
            ],
            if (trailing != null) trailing!,
            if (showChevron && trailing == null)
              Icon(Icons.chevron_right, size: 20, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}
