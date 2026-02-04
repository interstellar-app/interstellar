import 'dart:async';

import 'package:flutter/material.dart';
import 'package:interstellar/src/api/api.dart';
import 'package:interstellar/src/controller/controller.dart';

class NotificationCountController with ChangeNotifier {
  int _value = 0;
  int get value => _value;

  String? _account;
  late API _api;
  Timer? _timer;

  void updateAppController(AppController ac) {
    _api = ac.api;

    final newAccount = ac.isLoggedIn ? ac.selectedAccount : null;

    if (_account != newAccount) {
      _account = newAccount;

      reload();
    }
  }

  Future<void> reload() async {
    _timer?.cancel();

    if (_account != null) {
      _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
        _update();
      });
    }

    _update();
  }

  Future<void> _update() async {
    try {
      final newValue = _account == null
          ? 0
          : await _api.notifications.getCount();

      if (_value != newValue) {
        _value = newValue;
        notifyListeners();
      }
    } catch (_) {
      // Do not throw error if unsuccessful due to the spam of pop ups received
      // when going from background to foreground visibility
    }
  }

  @override
  void dispose() {
    _timer?.cancel();

    super.dispose();
  }
}
