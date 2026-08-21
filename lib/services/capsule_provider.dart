import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/capsule_model.dart';

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
        _capsules = rawData
            .map((item) => CapsuleModel.fromJson(item))
            .toList();
      } else {
        _capsules = _getInitialSampleCapsules();
        await _saveToPreferences();
      }
    } catch (e) {
      debugPrint('Error loading capsules: ');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveToPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stringList = _capsules.map((c) => c.toJson()).toList();
      await prefs.setStringList(_storageKey, stringList);
      await prefs.setBool(_themeModeKey, _isDarkMode);
    } catch (e) {
      debugPrint('Error saving capsules: ');
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

  Future<void> addCapsule({
    required String title,
    required String rawTranscript,
    String summary = '',
    List<String> actionItems = const [],
    List<String> tags = const [],
    bool isProcessed = false,
  }) async {
    final newCapsule = CapsuleModel(
      id: _uuid.v4(),
      title: title,
      rawTranscript: rawTranscript,
      summary: summary,
      actionItems: actionItems,
      createdAt: DateTime.now(),
      isProcessed: isProcessed,
      tags: tags,
    );

    _capsules.insert(0, newCapsule);
    notifyListeners();
    await _saveToPreferences();
  }

  Future<void> updateCapsule(CapsuleModel updated) async {
    final index = _capsules.indexWhere((c) => c.id == updated.id);
    if (index != -1) {
      _capsules[index] = updated;
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
    _capsules.removeWhere((c) => c.id == id);
    notifyListeners();
    await _saveToPreferences();
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
          '長按底部按鈕體驗錄音波紋動效',
          '點擊卡片右上角標記處理狀態',
          '點擊右上角切換深淺墨水屏主題'
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
        actionItems: [
          '評估語音轉文字 API 延遲',
          '設計離線語音快取機制'
        ],
        createdAt: now.subtract(const Duration(hours: 3)),
        isProcessed: true,
        tags: ['工作', 'AI規劃'],
      ),
    ];
  }
}
