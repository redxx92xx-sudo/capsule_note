import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MonetizationProvider extends ChangeNotifier {
  static const String _proKey = 'capsule_is_pro_user';
  static const String _bonusQuotaKey = 'capsule_bonus_quota';
  static const String _lastDateKey = 'capsule_last_quota_date';

  static const int dailyBaseQuota = 5;

  late final Future<void> initialized;
  bool _isPro = false;
  int _bonusQuota = 0;
  int _usedToday = 0;
  bool _isLoading = true;

  bool get isPro => _isPro;
  int get bonusQuota => _bonusQuota;
  int get usedToday => _usedToday;
  bool get isLoading => _isLoading;

  int get remainingDailyQuota {
    if (_isPro) return 999;
    final baseRemaining = (dailyBaseQuota - _usedToday).clamp(0, dailyBaseQuota);
    return baseRemaining + _bonusQuota;
  }

  MonetizationProvider() {
    initialized = _loadState();
  }

  Future<void> _loadState() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _isPro = prefs.getBool(_proKey) ?? false;
      _bonusQuota = prefs.getInt(_bonusQuotaKey) ?? 0;

      final todayStr = _getTodayDateString();
      final lastDate = prefs.getString(_lastDateKey);

      if (lastDate != todayStr) {
        _usedToday = 0;
        await prefs.setString(_lastDateKey, todayStr);
      } else {
        _usedToday = prefs.getInt('capsule_used_today') ?? 0;
      }
    } catch (e) {
      debugPrint('Error loading monetization: ');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _getTodayDateString() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_proKey, _isPro);
      await prefs.setInt(_bonusQuotaKey, _bonusQuota);
      await prefs.setInt('capsule_used_today', _usedToday);
      await prefs.setString(_lastDateKey, _getTodayDateString());
    } catch (e) {
      debugPrint('Error saving monetization: ');
    }
  }

  Future<void> setProStatus(bool pro) async {
    _isPro = pro;
    notifyListeners();
    await _saveState();
  }

  Future<void> addRewardQuota(int count) async {
    _bonusQuota += count;
    notifyListeners();
    await _saveState();
  }

  bool consumeQuota() {
    if (_isPro) return true;
    if (remainingDailyQuota <= 0) return false;

    if (_usedToday < dailyBaseQuota) {
      _usedToday++;
    } else if (_bonusQuota > 0) {
      _bonusQuota--;
    }
    notifyListeners();
    _saveState();
    return true;
  }
}
