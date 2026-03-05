import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedProvider extends ChangeNotifier {
  Set<String> _savedIds = {};

  Set<String> get savedIds => _savedIds;

  SavedProvider() { _load(); }

  bool isSaved(String id) => _savedIds.contains(id);

  Future<void> toggle(String id) async {
    if (_savedIds.contains(id)) {
      _savedIds.remove(id);
    } else {
      _savedIds.add(id);
    }
    notifyListeners();
    await _save();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _savedIds = (prefs.getStringList('saved_jobs') ?? []).toSet();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_jobs', _savedIds.toList());
  }
}
