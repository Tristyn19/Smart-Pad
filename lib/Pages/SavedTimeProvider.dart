import 'package:flutter/material.dart';

class SavedTimeProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _savedTimes = [];

  List<Map<String, dynamic>> get savedTimes => List.unmodifiable(_savedTimes);

  void addSavedTime(String name, int duration) {
    _savedTimes.add({'name' : name, 'duration' : duration});
    notifyListeners();
  }

  void clearSavedTimes() {
    _savedTimes.clear();
    notifyListeners();
  }
}