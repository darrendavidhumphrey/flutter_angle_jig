import 'package:flutter/material.dart';

class FrameCounterModel extends ChangeNotifier {
  int _count = 0;

  int get count => _count;

  void increment() {
    _count++;
    notifyListeners(); // Notify listeners to rebuild dependent widgets
  }
}