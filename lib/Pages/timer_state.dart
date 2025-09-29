import 'package:flutter/material.dart';
import 'dart:async';

class TimerState with ChangeNotifier {
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;

  int get seconds => _seconds;
  bool get isRunning => _isRunning;

  void startTimer() {
    if (_isRunning) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _seconds++;
      notifyListeners();  // Notify listeners to update the UI
    });
    _isRunning = true;
    notifyListeners();
  }

  void pauseTimer() {
    if (_isRunning) {
      _timer?.cancel();
      _isRunning = false;
      notifyListeners();
    }
  }

  void stopTimer() {
    if (_isRunning) {
      _timer?.cancel();
      _seconds = 0;
      _isRunning = false;
      notifyListeners();
    }
  }

  String formatTime() {
    final int hours = _seconds ~/ 3600;
    final int minutes = (_seconds % 3600) ~/ 60;
    final int remainingSeconds = _seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }
}


