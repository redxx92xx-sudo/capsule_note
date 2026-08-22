import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  void _copyAsMarkdown() {
    final l10n = AppLocalizations.of(context)!;
    final timeStr = DateFormat('yyyy-MM-dd HH:mm').format(widget.capsule.createdAt);
    final buffer = StringBuffer();

    final title = _titleController.text.trim();
    final tags = _tagsController.text.trim();
    final summary = _summaryController.text.trim();
    final transcript = _transcriptController.text.trim();

    buffer.writeln('# $title');
    buffer.writeln('📅 **建立時間**：$timeStr');
    if (tags.isNotEmpty) {
      buffer.writeln('🏷️ **標籤**：$tags');
    }
    buffer.writeln();
    buffer.writeln('## 💡 核心摘要');
    buffer.writeln(summary);
    buffer.writeln();
    if (_actionItems.isNotEmpty) {
      buffer.writeln('## ✅ 行動清單');
      for (final item in _actionItems) {
        buffer.writeln('- [ ] $item');
      }
      buffer.writeln();
    }
    if (transcript.isNotEmpty) {
      buffer.writeln('## 🎙️ 語音轉譯原文');
      buffer.writeln('> $transcript');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.copyMarkdownSuccess),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteCapsule() {
    final provider = Provider.of<CapsuleProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除膠囊'),
        content: const Text('確定要永久刪除此靈感便籤嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteCapsule(widget.capsule.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('確認刪除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _addNewActionItem() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新增行動項目'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '輸入待辦或執行事項...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _actionItems.add(controller.text.trim());
                });
                _saveChanges();
              }
              Navigator.pop(ctx);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final timeStr = DateFormat('yyyy-MM-dd HH:mm').format(widget.capsule.createdAt);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) _saveChanges();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('便籤詳情'),
          actions: [
            IconButton(
              tooltip: '多格式匯出',
              icon: const Icon(Icons.ios_share_outlined),
              onPressed: () {
                _saveChanges();
                ExportService.instance.showExportModal(context, capsule: widget.capsule);
              },
            ),
            IconButton(
              tooltip: '複製 Markdown 格式',
              icon: const Icon(Icons.copy_all_outlined),
              onPressed: _copyAsMarkdown,
            ),
            IconButton(
              tooltip: '刪除膠囊',
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _deleteCapsule,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          children: [
            TextField(
              controller: _titleController,
              onChanged: (_) => _saveChanges(),
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '輸入便籤標題...',
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  timeStr,
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 12),
                ),
                FilterChip(
                  label: Text(_isProcessed ? '已整理' : '待整理'),
                  selected: _isProcessed,
                  onSelected: (val) {
                    setState(() => _isProcessed = val);
                    _saveChanges();
                  },
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
                  color: isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight,
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
                _buildSectionHeader(context, Icons.check_circle_outline, '✅ 行動項目清單'),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  onPressed: _addNewActionItem,
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (_actionItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '暫無行動項目，點擊右上角「+」新增',
                  style: theme.textTheme.bodyMedium,
                ),
              )
            else
              ...List.generate(_actionItems.length, (index) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    leading: const Icon(Icons.arrow_right_alt, color: AppTheme.inkBlue),
                    title: Text(_actionItems[index]),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.redAccent),
                      onPressed: () {
                        setState(() {
                          _actionItems.removeAt(index);
                        });
                        _saveChanges();
                      },
                    ),
                  ),
                );
              }),
            const SizedBox(height: 20),
            _buildSectionHeader(context, Icons.mic_none, '🎙️ 語音轉譯原文'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.nightHighlight : AppTheme.inkHighlightLight.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _transcriptController,
                maxLines: null,
                onChanged: (_) => _saveChanges(),
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '原始轉譯文字內容...',
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
                hintText: '標籤（以逗號分隔）',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, IconData icon, String title) {
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
    final totalSeconds = _totalDuration.inSeconds > 0 ? _totalDuration.inSeconds : 1;

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
                onPressed: () {
                  if (_isPlaying) {
                    audio.pauseAudio();
                  } else {
                    audio.playAudio(path);
                  }
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '語音錄音記錄',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: currentSeconds.toDouble().clamp(0.0, totalSeconds.toDouble()),
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
