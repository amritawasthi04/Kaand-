import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants.dart';

class UserProvider extends ChangeNotifier {
  String _name = '';
  String get name => _name;

  bool get isOnboarded => _name.isNotEmpty;

  UserProvider() {
    _loadName();
  }

  void _loadName() {
    final box = Hive.box(Constants.hiveUserBox);
    _name = box.get('username', defaultValue: '') as String;
    notifyListeners();
  }

  Future<void> saveName(String userName) async {
    final box = Hive.box(Constants.hiveUserBox);
    await box.put('username', userName.trim());
    _name = userName.trim();
    notifyListeners();
  }

  Future<void> clearName() async {
    final box = Hive.box(Constants.hiveUserBox);
    await box.delete('username');
    _name = '';
    notifyListeners();
  }
}
