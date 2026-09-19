import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/capsule_model.dart';
import 'ai_summary_service.dart';
import 'audio_record_service.dart';

class CapsuleProvider extends ChangeNotifier {
  static const String _storageKey = 'capsule_notes_data';
  static const String _themeModeKey = 'capsule_is_dark_mode';

  final _uuid = const Uuid();
  List<CapsuleModel> _capsules = [];
  bool _isDarkMode = false;
  bool _isLoading = true;
  String? _selectedTag;
  String _searchQuery = '';

  List<CapsuleModel> get capsules => _capsules;
  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _isLoading;
  String? get selectedTag => _selectedTag;
  String get searchQuery => _searchQuery;

  int get unprocessedCount => _capsules.where((c) => !c.isProcessed).length;
  int get totalCount => _capsules.length;

  List<String> get allTags {
    final tags = <String>{};
    for (final c in _capsules) {
      tags.addAll(c.tags);
    }
    return tags.toList()..sort();
  }

  List<CapsuleModel> get filteredCapsules {
    return _capsules.where((c) {
      final matchesTag = _selectedTag == null || c.tags.contains(_selectedTag);
      final matchesSearch = _searchQuery.isEmpty ||
          c.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.summary.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.rawTranscript.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesTag && matchesSearch;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  CapsuleProvider() {
    _loadFromPreferences();
  }

  Future<void> _loadFromPreferences() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeModeKey) ?? false;

      final rawData = prefs.getStringList(_storageKey);
      if (rawData != null && rawData.isNotEmpty) {
        _capsules = rawData.map((item) => CapsuleModel.fromJson(item)).toList();
      } else {
        _capsules = _getInitialSampleCapsules();
        await _saveToPreferences();
      }

      await _migrateLegacyTempAudioPaths();
    } catch (e) {
      debugPrint('Error loading capsules: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Move any capsule audio still under the old temp folder into documents.
  Future<void> _migrateLegacyTempAudioPaths() async {
    var changed = false;
    for (var i = 0; i < _capsules.length; i++) {
      final capsule = _capsules[i];
      final path = capsule.audioPath;
      if (path == null || path.isEmpty) continue;

      final migrated =
          await AudioRecordService.instance.migrateTempAudioIfNeeded(path);
      if (migrated != null && migrated != path) {
        _capsules[i] = capsule.copyWith(audioPath: migrated);
        changed = true;
      }
    }
    if (changed) {
      await _saveToPreferences();
    }
  }

  Future<void> _saveToPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stringList = _capsules.map((c) => c.toJson()).toList();
      await prefs.setStringList(_storageKey, stringList);
      await prefs.setBool(_themeModeKey, _isDarkMode);
    } catch (e) {
      debugPrint('Error saving capsules: $e');
    }
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveToPreferences();
    notifyListeners();
  }

  void setSelectedTag(String? tag) {
    _selectedTag = tag;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<CapsuleModel> addCapsule({
    String? title,
    String rawTranscript = '',
    String? summary,
    List<String>? actionItems,
    List<String>? tags,
    String? audioPath,
    bool isProcessed = false,
  }) async {
    String finalTitle = title ?? '';
    String finalSummary = summary ?? '';
    List<String> finalActions = actionItems ?? [];
    List<String> finalTags = tags ?? [];

    // Text/summary failures must never delete or discard audio.
    // Audio-only capsules: no demo transcript, skip AI structuring.
    try {
      if (rawTranscript.trim().isEmpty) {
        if (finalTitle.isEmpty) finalTitle = '語音錄音記事';
        if (finalSummary.isEmpty) finalSummary = '（僅錄音，尚無文字）';
        if (finalTags.isEmpty) finalTags = ['錄音'];
        // Keep actionItems empty until user adds or transcribes.
      } else if (finalTitle.isEmpty ||
          finalSummary.isEmpty ||
          finalActions.isEmpty ||
          finalTags.isEmpty) {
        final aiResult =
            await AiSummaryService.instance.structureTranscript(rawTranscript);
        if (finalTitle.isEmpty) finalTitle = aiResult.title;
        if (finalSummary.isEmpty) finalSummary = aiResult.summary;
        if (finalActions.isEmpty) finalActions = aiResult.actionItems;
        if (finalTags.isEmpty) finalTags = aiResult.tags;
      }
    } catch (e) {
      debugPrint('AI summary failed (audio preserved): $e');
      if (finalTitle.isEmpty) {
        finalTitle = rawTranscript.isEmpty ? '語音錄音記事' : '未命名靈感膠囊';
      }
      if (finalSummary.isEmpty) {
        finalSummary = rawTranscript.isEmpty ? '（僅錄音，尚無文字）' : rawTranscript;
      }
      if (finalTags.isEmpty) finalTags = ['錄音'];
    }

    final id = _uuid.v4();
    final boundPath = await AudioRecordService.instance.bindAudioToCapsuleId(
      capsuleId: id,
      sourcePath: audioPath,
    );

    final newCapsule = CapsuleModel(
      id: id,
      title: finalTitle,
      rawTranscript: rawTranscript,
      summary: finalSummary,
      actionItems: finalActions,
      createdAt: DateTime.now(),
      isProcessed: isProcessed,
      tags: finalTags,
      audioPath: boundPath ?? audioPath,
    );

    _capsules.insert(0, newCapsule);
    notifyListeners();
    await _saveToPreferences();
    return newCapsule;
  }

  Future<void> updateCapsule(CapsuleModel updated) async {
    final index = _capsules.indexWhere((c) => c.id == updated.id);
    if (index != -1) {
      final existing = _capsules[index];
      // Never replace a valid audio path with null from an incomplete update.
      final merged = updated.audioPath == null && existing.audioPath != null
          ? updated.copyWith(audioPath: existing.audioPath)
          : updated;
      _capsules[index] = merged;
      notifyListeners();
      await _saveToPreferences();
    }
  }

  Future<void> toggleProcessed(String id) async {
    final index = _capsules.indexWhere((c) => c.id == id);
    if (index != -1) {
      final current = _capsules[index];
      _capsules[index] = current.copyWith(isProcessed: !current.isProcessed);
      notifyListeners();
      await _saveToPreferences();
    }
  }

  Future<void> deleteCapsule(String id) async {
    final index = _capsules.indexWhere((c) => c.id == id);
    String? audioPath;
    if (index != -1) {
      audioPath = _capsules[index].audioPath;
    }
    _capsules.removeWhere((c) => c.id == id);
    notifyListeners();
    await _saveToPreferences();

    // Only delete this capsule's audio file — never the whole directory.
    if (audioPath != null) {
      final stillReferenced = _capsules.any((c) => c.audioPath == audioPath);
      if (!stillReferenced) {
        await AudioRecordService.instance.deleteAudioFile(audioPath);
      }
    }
  }

  List<CapsuleModel> _getInitialSampleCapsules() {
    final now = DateTime.now();
    return [
      CapsuleModel(
        id: _uuid.v4(),
        title: '歡迎使用 Capsule Note',
        rawTranscript: '語音膠囊筆記：透過極簡墨水屏介面，隨時長按錄音記錄靈感，讓思緒化為清晰的行動便籤。',
        summary: '極簡墨水屏靈感膠囊筆記，長按底部按鈕即可快速紀錄語音並自動整理。',
        actionItems: [
          '長按底部按鈕體驗真實音訊錄音',
          '點擊便籤卡片進入詳情與編輯頁',
          '點擊右上角切換深淺墨水屏主題',
        ],
        createdAt: now.subtract(const Duration(minutes: 15)),
        isProcessed: false,
        tags: ['入門指南', '靈感'],
      ),
      CapsuleModel(
        id: _uuid.v4(),
        title: '產品架構迭代規劃',
        rawTranscript: '討論第二階段要串接本地 Whisper 語音模型與大語言模型做自動摘要整理。',
        summary: '規劃整合 AI 模型進行語音自動轉文字與重點行動項目提取。',
        actionItems: ['評估語音轉文字 API 延遲', '設計離線語音快取機制'],
        createdAt: now.subtract(const Duration(hours: 3)),
        isProcessed: true,
        tags: ['工作', '技術'],
      ),
    ];
  }
}
