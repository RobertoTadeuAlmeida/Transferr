import 'package:flutter/material.dart';
import '../config/demo_config.dart';

class DemoModeProvider extends ChangeNotifier {
  bool _isDemo = DemoConfig.isDemoMode;

  bool get isDemo => _isDemo;

  void enable() {
    _set(true);
  }

  void disable() {
    _set(false);
  }

  Future<void> toggle() async {
    await _set(!_isDemo);
  }

  Future<void> _set(bool value) async {
    if (_isDemo == value) return;
    _isDemo = value;
    await DemoConfig.setDemo(value);
    notifyListeners();
  }
}
