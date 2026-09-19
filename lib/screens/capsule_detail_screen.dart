import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/capsule_model.dart';
import '../services/ai_summary_service.dart';
import '../services/audio_record_service.dart';
import '../services/capsule_provider.dart';
import '../services/export_service.dart';
import '../services/locale_provider.dart';
import '../services/local_whisper_transcription_service.dart';
import '../services/todo_provider.dart';
import '../services/transcription_service.dart';
import '../theme/app_theme_capsule.dart';
import '../widgets/todo_edit_dialog.dart';

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

  bool _isTranscribing = false;
  String? _transcriptionError;
  TranscriptionPhase? _transcriptionPhase;
  int _transcriptionPercent = 0;
  bool _offerSummaryAfterTranscribe = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.capsule.title);
    _summaryController = TextEditingController(text: widget.capsule.summary);
    _transcriptController =
        TextEditingController(text: widget.capsule.rawTranscript);
    _tagsController =
        TextEditingController(text: widget.capsule.tags.join(', '));
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

    // copyWith keeps existing audioPath when not passed — never wipe audio.
    final updated = widget.capsule.copyWith(
      title: _titleController.text,
      summary: _summaryController.text,
      rawTranscript: _transcriptController.text,
      actionItems: _actionItems,
      tags: tags,
      isProcessed: _isProcessed,
    );
    provider.updateCapsule(updated);
  }

  Future<void> _runTranscription() async {
    final l10n = AppLocalizations.of(context)!;
    final path = widget.capsule.audioPath;
    final previousTranscript = _transcriptController.text;

    if (path == null || path.isEmpty) {
      setState(() {
        _transcriptionError = l10n.audioFileMissing;
      });
      return;
    }

    final exists = await AudioRecordService.instance.audioFileExists(path);
    if (!exists) {
      if (!mounted) return;
      setState(() {
        _transcriptionError = l10n.audioFileMissing;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.audioFileMissing)),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isTranscribing = true;
      _transcriptionError = null;
      _transcriptionPhase = TranscriptionPhase.preparing;
      _transcriptionPercent = 0;
      _offerSummaryAfterTranscribe = false;
    });

    final localeTag =
        Provider.of<LocaleProvider>(context, listen: false).transcriptionLocale;
    final service = TranscriptionServiceLocator.instance;

    try {
      final text = await service.transcribe(
        audioPath: path,
        locale: localeTag,
        onStatus: (status) {
          if (!mounted) return;
          setState(() {
            _transcriptionPhase = status.phase;
            if (status.percent != null) {
              _transcriptionPercent = status.percent!;
            }
          });
        },
      );

      if (!mounted) return;

      // Only write text after success; keep prior text + audioPath on write fail.
      try {
        setState(() {
          _transcriptController.text = text;
          _isTranscribing = false;
          _transcriptionError = null;
          _transcriptionPhase = TranscriptionPhase.completed;
          _offerSummaryAfterTranscribe = true;
        });
        _saveChanges();
      } catch (e) {
        debugPrint('Write transcript failed (audio+old text kept): $e');
        if (!mounted) return;
        setState(() {
          _transcriptController.text = previousTranscript;
          _isTranscribing = false;
          _transcriptionError = l10n.transcriptionFailed;
          _transcriptionPhase = TranscriptionPhase.failed;
        });
      }
    } on TranscriptionCancelledException {
      if (!mounted) return;
      setState(() {
        _isTranscribing = false;
        _transcriptionPhase = TranscriptionPhase.cancelled;
        _transcriptionError = l10n.transcriptionCancelled;
      });
    } on TranscriptionModelMissingException {
      if (!mounted) return;
      setState(() {
        _isTranscribing = false;
        _transcriptionPhase = TranscriptionPhase.failed;
        _transcriptionError = l10n.transcriptionModelMissing;
      });
    } on TranscriptionNotConfiguredException {
      if (!mounted) return;
      setState(() {
        _isTranscribing = false;
        _transcriptionPhase = TranscriptionPhase.failed;
        _transcriptionError = l10n.transcriptionNotConfigured;
      });
    } catch (e) {
      debugPrint('Transcription failed (audio preserved): $e');
      if (!mounted) return;
      setState(() {
        _isTranscribing = false;
        _transcriptionPhase = TranscriptionPhase.failed;
        _transcriptionError = l10n.transcriptionFailed;
      });
    }
  }

  void _cancelTranscription() {
    final service = TranscriptionServiceLocator.instance;
    if (service is LocalWhisperTranscriptionService) {
      service.cancel();
    }
  }

  Future<void> _runLocalSummary() async {
    final l10n = AppLocalizations.of(context)!;
    final text = _transcriptController.text.trim();
    if (text.isEmpty) return;

    final previousSummary = _summaryController.text;
    final previousTitle = _titleController.text;
    final previousActions = List<String>.from(_actionItems);

    try {
      final result =
          await AiSummaryService.instance.structureTranscript(text);
      if (!mounted) return;
      setState(() {
        if (_titleController.text.trim().isEmpty ||
            _titleController.text == l10n.audioRecordingDefaultTitle) {
          _titleController.text = result.title;
        }
        _summaryController.text = result.summary;
        if (_actionItems.isEmpty) {
          _actionItems = List<String>.from(result.actionItems);
        }
        _offerSummaryAfterTranscribe = false;
      });
      _saveChanges();
    } catch (e) {
      debugPrint('Local summary failed (text+audio preserved): $e');
      if (!mounted) return;
      setState(() {
        _summaryController.text = previousSummary;
        _titleController.text = previousTitle;
        _actionItems = previousActions;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.transcriptionFailed)),
      );
    }
  }

  void _clearTranscript() {
    setState(() {
      _transcriptController.text = '';
      _transcriptionError = null;
      _offerSummaryAfterTranscribe = false;
    });
    _saveChanges();
  }

  String _statusLabel(AppLocalizations l10n) {
    switch (_transcriptionPhase) {
      case TranscriptionPhase.preparing:
        return l10n.transcriptionPreparing;
      case TranscriptionPhase.converting:
        return l10n.transcriptionConverting;
      case TranscriptionPhase.transcribing:
        return l10n.transcriptionProgress(_transcriptionPercent);
      case TranscriptionPhase.completing:
      case TranscriptionPhase.completed:
        return l10n.transcriptionCompleted;
      case TranscriptionPhase.cancelled:
        return l10n.transcriptionCancelled;
      case TranscriptionPhase.failed:
        return _transcriptionError ?? l10n.transcriptionFailed;
      case null:
        return l10n.transcribing;
    }
  }

  void _addNewActionItem() {
    final l10n = AppLocalizations.of(context)!;
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addNewAction),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.addActionHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                setState(() {
                  _actionItems.add(textController.text.trim());
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

  void _convertAllToTodos() async {
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
    final titles = <String>[
      ..._actionItems.map((t) => t.trim()).where((t) => t.isNotEmpty),
    ];
    if (titles.isEmpty) {
      final fallback = _titleController.text.trim();
      if (fallback.isNotEmpty) titles.add(fallback);
    }
    if (titles.isEmpty) return;

    var created = 0;
    final now = DateTime.now();
    final notes = '來自記事：${_titleController.text.trim()}';
    for (final title in titles) {
      await todoProvider.createTodo(
        title: title,
        notes: notes,
        scheduledDate: now,
      );
      created++;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已成功建立 $created 則待辦事項！')),
      );
    }
  }

  void _convertSingleActionToTodo(String actionText) {
    final notes = '來自記事：${_titleController.text.trim()}';
    TodoEditDialog.show(
      context,
      defaultDate: DateTime.now(),
      draftTitle: actionText,
      draftNotes: notes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dateStr =
        DateFormat('yyyy/MM/dd HH:mm').format(widget.capsule.createdAt);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.capsuleDetailTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task),
            tooltip: l10n.convertToTodo,
            onPressed: _convertAllToTodos,
          ),
          IconButton(
            icon: Icon(
                _isProcessed ? Icons.task_alt : Icons.radio_button_unchecked),
            tooltip: _isProcessed ? l10n.markAsPending : l10n.markAsDone,
            onPressed: () {
              setState(() {
                _isProcessed = !_isProcessed;
              });
              _saveChanges();
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: l10n.exportModalTitle,
            onPressed: () {
              ExportService.instance
                  .showExportModal(context, capsule: widget.capsule);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.deleteCapsuleTitle,
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.deleteCapsuleTitle),
                  content: Text(l10n.deleteCapsuleMessage),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l10n.cancel),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.redAccent),
                      onPressed: () {
                        Provider.of<CapsuleProvider>(context, listen: false)
                            .deleteCapsule(widget.capsule.id);
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      child: Text(l10n.confirmDelete),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '輸入標題...',
              ),
              onChanged: (_) => _saveChanges(),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time,
                    size: 14,
                    color: isDark
                        ? AppTheme.nightSecondary
                        : AppTheme.inkSecondary),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const Divider(height: 24),
            if (widget.capsule.audioPath != null) ...[
              _buildAudioPlayerCard(context),
              const SizedBox(height: 16),
            ],
            _buildSectionHeader(context, Icons.lightbulb_outline, '💡 AI 核心摘要'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight,
                ),
              ),
              child: TextField(
                controller: _summaryController,
                maxLines: null,
                onChanged: (_) => _saveChanges(),
                style: theme.textTheme.bodyLarge,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '輸入重點摘要...',
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader(
                    context, Icons.check_circle_outline, '✅ 行動項目清單'),
                Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.add_task, size: 16),
                      label: Text(l10n.convertAllToTodos,
                          style: const TextStyle(fontSize: 12)),
                      onPressed: _convertAllToTodos,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      onPressed: _addNewActionItem,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (_actionItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n.noActionItemsHint,
                  style: theme.textTheme.bodyMedium,
                ),
              )
            else
              ...List.generate(_actionItems.length, (index) {
                final item = _actionItems[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    leading: const Icon(Icons.arrow_right_alt,
                        color: AppTheme.inkBlue),
                    title: Text(item),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add_task,
                              size: 18, color: AppTheme.inkBlue),
                          tooltip: l10n.convertToTodo,
                          onPressed: () => _convertSingleActionToTodo(item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              size: 18, color: Colors.redAccent),
                          onPressed: () {
                            setState(() {
                              _actionItems.removeAt(index);
                            });
                            _saveChanges();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader(context, Icons.mic_none, '🎙️ 語音轉譯原文'),
                if (widget.capsule.audioPath != null)
                  TextButton(
                    onPressed: _isTranscribing ? null : _clearTranscript,
                    child: Text(l10n.clearTranscript),
                  ),
              ],
            ),
            if (widget.capsule.audioPath != null) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (_isTranscribing) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Text(_statusLabel(l10n), style: const TextStyle(fontSize: 13)),
                    ),
                    if (_transcriptionPhase ==
                            TranscriptionPhase.transcribing ||
                        _transcriptionPhase == TranscriptionPhase.converting)
                      SizedBox(
                        width: 120,
                        child: LinearProgressIndicator(
                          value: _transcriptionPhase ==
                                  TranscriptionPhase.transcribing
                              ? (_transcriptionPercent / 100.0)
                              : null,
                        ),
                      ),
                    TextButton(
                      onPressed: _cancelTranscription,
                      child: Text(l10n.cancelTranscription),
                    ),
                  ] else ...[
                    FilledButton.tonalIcon(
                      onPressed: _runTranscription,
                      icon: Icon(
                        _transcriptController.text.trim().isEmpty
                            ? Icons.text_fields
                            : Icons.refresh,
                        size: 18,
                      ),
                      label: Text(
                        _transcriptController.text.trim().isEmpty
                            ? l10n.transcribeToText
                            : l10n.retranscribe,
                      ),
                    ),
                    if (_offerSummaryAfterTranscribe &&
                        _transcriptController.text.trim().isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: _runLocalSummary,
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: Text(l10n.runLocalSummary),
                      ),
                  ],
                ],
              ),
              if (_transcriptionError != null && !_isTranscribing) ...[
                const SizedBox(height: 8),
                Text(
                  _transcriptionError!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.nightHighlight
                    : AppTheme.inkHighlightLight.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _transcriptController,
                maxLines: null,
                onChanged: (_) => _saveChanges(),
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: l10n.noTranscriptYetHint,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionHeader(context, Icons.tag, '🏷️ 分類標籤'),
            const SizedBox(height: 8),
            TextField(
              controller: _tagsController,
              onChanged: (_) => _saveChanges(),
              decoration: InputDecoration(
                hintText: l10n.tagsLabel,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.inkBlue),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildAudioPlayerCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final audio = AudioRecordService.instance;
    final path = widget.capsule.audioPath!;

    final currentSeconds = _currentPosition.inSeconds;
    final totalSeconds =
        _totalDuration.inSeconds > 0 ? _totalDuration.inSeconds : 1;

    final curMin = _currentPosition.inMinutes.toString();
    final curSec = (_currentPosition.inSeconds % 60).toString().padLeft(2, '0');
    final totMin = _totalDuration.inMinutes.toString();
    final totSec = (_totalDuration.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.inkBlue,
                  foregroundColor: Colors.white,
                ),
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () async {
                  if (_isPlaying) {
                    await audio.pauseAudio();
                    return;
                  }
                  final played = await audio.playAudio(path);
                  if (!played && context.mounted) {
                    final l10n = AppLocalizations.of(context)!;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.audioFileMissing)),
                    );
                  }
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.audioRecordTitle,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: currentSeconds
                            .toDouble()
                            .clamp(0.0, totalSeconds.toDouble()),
                        max: totalSeconds.toDouble(),
                        onChanged: (val) {
                          audio.seekAudio(Duration(seconds: val.toInt()));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$curMin:$curSec',
                  style: const TextStyle(fontSize: 11),
                ),
                Text(
                  '$totMin:$totSec',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
