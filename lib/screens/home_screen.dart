import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/capsule_model.dart';
import '../services/capsule_provider.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  void _onRecordStart() {
    setState(() {
      _isRecording = true;
    });
    _rippleController.repeat();
  }

  void _onRecordEnd() {
    if (!_isRecording) return;
    setState(() {
      _isRecording = false;
    });
    _rippleController.stop();
    _rippleController.reset();

    // 模擬錄音完成並生成一則新靈感膠囊
    _showRecordingCompletedDialog();
  }

  void _showRecordingCompletedDialog() {
    final provider = Provider.of<CapsuleProvider>(context, listen: false);
    final isDark = provider.isDarkMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final titleController = TextEditingController(text: '快速語音靈感膠囊');
        final transcriptController = TextEditingController(text: '今天下午要確認墨水屏調色盤對比度，並測試音訊錄音擴散波紋反饋。');
        final tagController = TextEditingController(text: '靈感, 待辦');

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.nightHighlight : AppTheme.inkHighlightLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.mic, size: 20, color: AppTheme.inkBlue),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '語音轉化完成',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: '膠囊標題',
                  labelStyle: const TextStyle(fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: transcriptController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: '語音轉譯內容',
                  labelStyle: const TextStyle(fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tagController,
                decoration: InputDecoration(
                  labelText: '標籤 (逗號分隔)',
                  labelStyle: const TextStyle(fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF4A6572) : AppTheme.inkBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    final tags = tagController.text
                        .split(',')
                        .map((t) => t.trim())
                        .where((t) => t.isNotEmpty)
                        .toList();

                    provider.addCapsule(
                      title: titleController.text.trim().isEmpty ? '語音記錄' : titleController.text.trim(),
                      rawTranscript: transcriptController.text.trim(),
                      summary: transcriptController.text.trim(),
                      actionItems: ['確認錄音項目', '回顧筆記重點'],
                      tags: tags.isEmpty ? ['語音靈感'] : tags,
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    '儲存為膠囊便籤',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDateChinese(DateTime date) {
    const weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    return DateFormat('M月d日 ').format(date) + weekdays[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CapsuleProvider>(context);
    final theme = Theme.of(context);
    final isDark = provider.isDarkMode;
    final now = DateTime.now();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 頂部導航與狀態列
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDateChinese(now),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '膠囊靈感',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.nightHighlight : AppTheme.inkHighlightLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              ' 則待整理',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppTheme.nightText : AppTheme.inkBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: isDark ? '切換淺色墨水屏' : '切換墨黑夜間',
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? AppTheme.nightHighlight : AppTheme.inkHighlightLight,
                        ),
                        icon: Icon(
                          isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                          size: 20,
                        ),
                        onPressed: () => provider.toggleTheme(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 標籤篩選橫向滾動條
            if (provider.allTags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildTagFilterChip(
                        context,
                        label: '全部 ()',
                        isSelected: provider.selectedTag == null,
                        onTap: () => provider.setSelectedTag(null),
                      ),
                      ...provider.allTags.map(
                        (tag) => _buildTagFilterChip(
                          context,
                          label: tag,
                          isSelected: provider.selectedTag == tag,
                          onTap: () => provider.setSelectedTag(
                            provider.selectedTag == tag ? null : tag,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const Divider(height: 12),

            // 中央便籤列表
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : provider.filteredCapsules.isEmpty
                      ? _buildEmptyState(context)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                          itemCount: provider.filteredCapsules.length,
                          itemBuilder: (context, index) {
                            final capsule = provider.filteredCapsules[index];
                            return _buildCapsuleCard(context, capsule, index)
                                .animate()
                                .fadeIn(duration: 300.ms, delay: (index * 40).ms)
                                .slideY(begin: 0.05, end: 0, duration: 300.ms);
                          },
                        ),
            ),
          ],
        ),
      ),

      // 底部中央大型長按錄音膠囊按鈕
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildRecordFloatingButton(context),
    );
  }

  Widget _buildTagFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF4A6572) : AppTheme.inkBlue)
                : (isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : (isDark ? AppTheme.nightBorder : AppTheme.inkBorderLight),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppTheme.nightText : AppTheme.inkBlack),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCapsuleCard(BuildContext context, CapsuleModel capsule, int index) {
    final provider = Provider.of<CapsuleProvider>(context, listen: false);
    final theme = Theme.of(context);
    final isDark = provider.isDarkMode;
    final timeStr = DateFormat('MM/dd HH:mm').format(capsule.createdAt);

    return Dismissible(
      key: Key(capsule.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      onDismissed: (_) => provider.deleteCapsule(capsule.id),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.nightCard : AppTheme.paperWhiteCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: capsule.isProcessed
                ? (isDark ? AppTheme.nightBorder.withValues(alpha: 0.5) : AppTheme.inkBorderLight.withValues(alpha: 0.6))
                : (isDark ? const Color(0xFF4A6572) : AppTheme.inkBlue.withValues(alpha: 0.35)),
            width: capsule.isProcessed ? 1.0 : 1.4,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 卡片標頭列
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          capsule.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            decoration: capsule.isProcessed ? TextDecoration.lineThrough : null,
                            color: capsule.isProcessed
                                ? (isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary)
                                : (isDark ? AppTheme.nightText : AppTheme.inkBlack),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeStr,
                          style: theme.textTheme.labelSmall?.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    iconSize: 22,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: capsule.isProcessed ? '標記為未整理' : '標記為已整理',
                    icon: Icon(
                      capsule.isProcessed ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: capsule.isProcessed
                          ? (isDark ? const Color(0xFF6B8CAE) : AppTheme.inkBlue)
                          : (isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary),
                    ),
                    onPressed: () => provider.toggleProcessed(capsule.id),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // 摘要 / 原文
              Text(
                capsule.summary.isNotEmpty ? capsule.summary : capsule.rawTranscript,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppTheme.nightText.withValues(alpha: 0.85) : AppTheme.inkBlack.withValues(alpha: 0.85),
                  fontSize: 13.5,
                  height: 1.45,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // 行動項目（若有）
              if (capsule.actionItems.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.nightHighlight : AppTheme.inkHighlightLight.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: capsule.actionItems
                        .take(2)
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.arrow_right_alt,
                                  size: 14,
                                  color: isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppTheme.nightText : AppTheme.inkBlack,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],

              // 標籤 Chip
              if (capsule.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: capsule.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.nightHighlight : AppTheme.inkHighlightLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.draw_outlined,
              size: 56,
              color: isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '尚無靈感膠囊',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.nightText : AppTheme.inkBlack,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '長按下方按鈕隨時記錄語音與想法',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.nightSecondary : AppTheme.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordFloatingButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isRecording)
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
                  '正在聆聽錄音中... 鬆開即完成',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.nightText : AppTheme.inkBlack,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.2, end: 0),

        // 長按按鈕與微動效外環波紋
        Stack(
          alignment: Alignment.center,
          children: [
            // 動態外擴波紋
            if (_isRecording)
              AnimatedBuilder(
                animation: _rippleController,
                builder: (context, child) {
                  final value = _rippleController.value;
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

            // 主膠囊按鈕
            GestureDetector(
              onLongPressStart: (_) => _onRecordStart(),
              onLongPressEnd: (_) => _onRecordEnd(),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('請長按按鈕進行語音錄製'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _isRecording ? 76 : 68,
                height: _isRecording ? 76 : 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording
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
                    _isRecording ? Icons.mic : Icons.mic_none_outlined,
                    size: _isRecording ? 34 : 30,
                    color: _isRecording
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
