import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/capsule_model.dart';
import '../services/audio_record_service.dart';
import '../services/capsule_provider.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';

class CapsuleDetailScreen extends StatefulWidget {
  final CapsuleModel capsule;

  const CapsuleDetailScreen({super.key, required this.capsule});

  @override
  State<CapsuleDetailScreen> createState() => _CapsuleDetailScreenState();
}

class _CapsuleDetailScreenState extends State<CapsuleDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _summaryController;
  late TextEditingController _transcriptController;
  late TextEditingController _tagsController;
  late List<String> _actionItems;
  late bool _isProcessed;

  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.capsule.title);
    _summaryController = TextEditingController(text: widget.capsule.summary);
    _transcriptController = TextEditingController(text: widget.capsule.rawTranscript);
    _tagsController = TextEditingController(text: widget.capsule.tags.join(', '));
    _actionItems = List<String>.from(widget.capsule.actionItems);
    _isProcessed = widget.capsule.isProcessed;

    _setupAudioListeners();
  }

  void _setupAudioListeners() {
    final audio = AudioRecordService.instance;
    audio.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _currentPosition = pos);
    });
    audio.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _totalDuration = dur);
    });
    audio.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.name == 'playing';
        });
      }
    });
  }

  @override
  void dispose() {
    AudioRecordService.instance.stopAudio();
    _titleController.dispose();
    _summaryController.dispose();
    _transcriptController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final provider = Provider.of<CapsuleProvider>(context, listen: false);
    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final updated = widget.capsule.copyWith(
      title: _titleController.text.trim().isEmpty ? '未命名靈感' : _titleController.text.trim(),
      summary: _summaryController.text.trim(),
      rawTranscript: _transcriptController.text.trim(),
      actionItems: _actionItems,
      tags: tags,
      isProcessed: _isProcessed,
    );

    provider.updateCapsule(updated);
  }

  void _showExportMenu() {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    l10n.exportFormat,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                ...ExportFormat.values.map((fmt) {
                  return ListTile(
                    leading: Icon(
                      fmt == ExportFormat.markdown
                          ? Icons.code
                          : (fmt == ExportFormat.plainText
                              ? Icons.text_snippet_outlined
                              : Icons.description_outlined),
                      color: AppTheme.inkBlue,
                    ),
                    title: Text(fmt.label),
                    onTap: () {
                      Navigator.pop(ctx);
                      _saveChanges();
                      final currentCapsule = widget.capsule.copyWith(
                        title: _titleController.text.trim(),
                        summary: _summaryController.text.trim(),
                        rawTranscript: _transcriptController.text.trim(),
                        actionItems: _actionItems,
                        isProcessed: _isProcessed,
                      );
                      final content = ExportService.instance.formatCapsule(currentCapsule, fmt);
                      ExportService.instance.handleExportWithMonetization(
                        context: context,
                        content: content,
                        title: currentCapsule.title,
                        format: fmt,
                        successMessage: l10n.exportSuccess,
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteCapsule() async {
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<CapsuleProvider>(context, listen: false);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteCapsuleTitle),
        content: Text(l10n.deleteCapsuleMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.confirmDelete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      provider.deleteCapsule(widget.capsule.id);
      if (mounted) Navigator.pop(context);
    }
  }

  void _showAddActionDialog() {
    final l10n = AppLocalizations.of(context)!;
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addNewAction),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.addActionHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  _actionItems.add(text);
                });
                _saveChanges();
              }
              Navigator.pop(ctx);
            },
            child: Text(l10n.addAction),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateStr = DateFormat.yMMMEd(Localizations.localeOf(context).toString())
        .add_jm()
        .format(widget.capsule.createdAt);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) _saveChanges();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.capsuleDetailTitle),
          actions: [
            IconButton(
              tooltip: l10n.exportCapsule,
              icon: const Icon(Icons.ios_share_rounded, size: 20),
              onPressed: _showExportMenu,
            ),
            IconButton(
              tooltip: _isProcessed ? l10n.markAsPending : l10n.markAsDone,
              icon: Icon(
                _isProcessed ? Icons.check_circle : Icons.radio_button_unchecked,
                color: _isProcessed ? AppTheme.inkBlue : null,
              ),
              onPressed: () {
                setState(() => _isProcessed = !_isProcessed);
                _saveChanges();
              },
            ),
            IconButton(
              tooltip: l10n.deleteCapsuleTitle,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _deleteCapsule,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              Text(
                dateStr,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  color: isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _titleController,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '標題...',
                ),
                onChanged: (_) => _saveChanges(),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _tagsController,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '標籤 (逗號分隔)...',
                ),
                onChanged: (_) => _saveChanges(),
              ),
              const SizedBox(height: 16),
              if (widget.capsule.audioPath != null) ...[
                _buildAudioPlayerCard(isDark),
                const SizedBox(height: 20),
              ],
              _buildSectionHeader('💡 提煉重點摘要'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight,
                  ),
                ),
                child: TextField(
                  controller: _summaryController,
                  maxLines: null,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '摘要...',
                  ),
                  onChanged: (_) => _saveChanges(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader('📌 行動清單'),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    onPressed: _showAddActionDialog,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight,
                  ),
                ),
                child: _actionItems.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          l10n.noActionItemsHint,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary,
                          ),
                        ),
                      )
                    : Column(
                        children: _actionItems.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final text = entry.value;
                          return ListTile(
                            leading: const Icon(Icons.check_box_outline_blank, size: 20),
                            title: Text(text, style: const TextStyle(fontSize: 14)),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () {
                                setState(() {
                                  _actionItems.removeAt(idx);
                                });
                                _saveChanges();
                              },
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('🎙️ 語音轉錄原文'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight,
                  ),
                ),
                child: TextField(
                  controller: _transcriptController,
                  maxLines: null,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '原始語音逐字稿...',
                  ),
                  onChanged: (_) => _saveChanges(),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildAudioPlayerCard(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    final audio = AudioRecordService.instance;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.nightHighlight : AppTheme.inkHighlightLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.inkBlue,
                  foregroundColor: Colors.white,
                ),
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () {
                  if (_isPlaying) {
                    audio.pauseAudio();
                  } else {
                    audio.playAudio(widget.capsule.audioPath!);
                  }
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.audioRecordTitle,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatDuration(_currentPosition)} / ${_formatDuration(_totalDuration)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_totalDuration.inMilliseconds > 0)
            Slider(
              value: _currentPosition.inMilliseconds
                  .clamp(0, _totalDuration.inMilliseconds)
                  .toDouble(),
              max: _totalDuration.inMilliseconds.toDouble(),
              activeColor: AppTheme.inkBlue,
              onChanged: (val) {
                audio.seekAudio(Duration(milliseconds: val.toInt()));
              },
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes.toString().padLeft(2, '0');
    final secs = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}
