// lib/services/haptic_service.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();
  bool _initialized = false;
  bool? _hasVibrator;

  Future<void> vibrateSelection() async {
    await HapticFeedback.selectionClick();
  }

  // Other common haptic types you might want
  Future<void> vibrateSuccess() async {
    await HapticFeedback.lightImpact();
  }

  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      _hasVibrator = await Vibration.hasVibrator();
      _initialized = true;
      debugPrint('✅ Haptic service initialized. Has vibrator: $_hasVibrator');
    } catch (e) {
      debugPrint('❌ Failed to initialize haptic service: $e');
      _hasVibrator = false;
    }
  }

  // For correct answer feedback
  Future<void> vibrateCorrect() async {
    if (!await _canVibrate()) return;
    
    try {
      // Quick success feedback
      await Vibration.vibrate(pattern: [50, 100]); // Quick double buzz
    } catch (e) {
      debugPrint('❌ Vibration error: $e');
    }
  }

  // For incorrect answer feedback
  Future<void> vibrateIncorrect() async {
    if (!await _canVibrate()) return;
    
    try {
      // Single long buzz for wrong answer
      await Vibration.vibrate(duration: 300);
    } catch (e) {
      debugPrint('❌ Vibration error: $e');
    }
  }

  // For achievement unlocks
  Future<void> vibrateAchievement() async {
    if (!await _canVibrate()) return;
    
    try {
      // Celebration pattern: buzz, pause, buzz buzz!
      await Vibration.vibrate(pattern: [100, 100, 100, 200, 100]);
    } catch (e) {
      debugPrint('❌ Vibration error: $e');
    }
  }

  // For completing an exam
  Future<void> vibrateExamComplete() async {
    if (!await _canVibrate()) return;
    
    try {
      // Triumph pattern: three quick buzzes
      await Vibration.vibrate(pattern: [100, 100, 100, 100, 100]);
    } catch (e) {
      debugPrint('❌ Vibration error: $e');
    }
  }

  // For navigation/button taps (light feedback)
  Future<void> vibrateTap() async {
    if (!await _canVibrate()) return;
    
    try {
      await Vibration.vibrate(duration: 20); // Very short buzz
    } catch (e) {
      debugPrint('❌ Vibration error: $e');
    }
  }

  // Cancel any ongoing vibration
  Future<void> cancel() async {
    try {
      await Vibration.cancel();
    } catch (e) {
      debugPrint('❌ Cancel vibration error: $e');
    }
  }

  // Check if device can vibrate
  Future<bool> _canVibrate() async {
    if (!_initialized) await initialize();
    
    if (_hasVibrator != true) {
      return false;
    }

    try {
      return await Vibration.hasVibrator();
    } catch (e) {
      return false;
    }
  }
}