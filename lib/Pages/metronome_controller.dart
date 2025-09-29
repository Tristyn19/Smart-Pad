import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:flutter/scheduler.dart';

//troubleshoot timing of both iOS and Android
//check long term control
//reset after each bar length

class MetronomeController with ChangeNotifier{
  final AudioPlayer _audioPlayer = AudioPlayer();

  late final Ticker _ticker;
  late final Stopwatch _stopwatch;

  // User-configurable values
  int _bpm = 60; // b
  int _bar = 4;  // x
  int _beats = 4; // y
  int _clicks = 4; // z
  String _currentSound = 'sounds/metronome1.wav';

  // Calculated values based on equations
  double _beatDuration = 1.0;  // bd = 60 / b
  double _barLength = 4.0;     // bL = bd * x
  double _noteDuration = 1.0;  // nd = bL / y
  double _clickDuration = 1.0; // ct = nd / z
  double _barProgress = 0.0;

  bool _isPlaying = false;
  bool _soundEnabled = true;

  int _currentBeat = 1;
  int _clickCounter = 0;

  // Getters
  int get bpm => _bpm;
  int get bar => _bar;
  int get beats => _beats;
  int get clicks => _clicks;
  String get currentSound => _currentSound;
  bool get isPlaying => _isPlaying;
  int get currentBeat => _currentBeat;
  double get barProgress => _barProgress;
  double get barLength => _barLength;
  bool get isSoundEnabled => _soundEnabled;

  bool _isInitialized = false;

  void initialize(TickerProvider vsync) {
    if (_isInitialized) return;
    _ticker = vsync.createTicker(_onTick);
    _stopwatch = Stopwatch();
    _isInitialized = true;
  }

  /// **Recalculates timing values based on the equations**
  void _calculateTimings() {
    _beatDuration = 60.0 / _bpm;   // Beat duration
    _barLength = _beatDuration * _bar; // Total bar time
    _noteDuration = _barLength / _beats; // Time per beat
    _clickDuration = _noteDuration / _clicks; // Click interval
  }

  /// **Starts the metronome with separate timers for beats (visual) and clicks (sound).**
  void startMetronome() {
    if (_isPlaying) return;

    _isPlaying = true;
    _currentBeat = 1;
    _clickCounter = 0;
    _barProgress = 0;
    _stopwatch.reset();
    _stopwatch.start();

    _calculateTimings();
    _ticker.start();
    notifyListeners();
  }


  /// **Stops both timers and resets state.**
  void stopMetronome() {
    _ticker.stop();
    _stopwatch.stop();
    _isPlaying = false;
    _currentBeat = 1;
    _clickCounter = 0;
    _barProgress = 0;
    notifyListeners();
  }

  void _onTick(Duration elapsed) {
    final elapedSeconds = _stopwatch.elapsed.inMilliseconds / 1000.0;
    final barPos = elapedSeconds % _barLength;

    //update bar progress
    _barProgress = barPos / _barLength;

    //handle click logic
    double currentClickTime = _clickCounter * _clickDuration;
    if (barPos >= currentClickTime) {
      _clickCounter++;

      // Play sound
      _playSound();

      // Advance beat if click aligns with beat
      if (_clickCounter % _clicks == 0) {
        _currentBeat = (_currentBeat % _beats) + 1;
      }
      notifyListeners();
    }

    // Reset at end of bar
    if (barPos < (_clickCounter - 1) * _clickDuration) {
      _clickCounter = 0;
    }
  }

  /// **Plays the metronome sound.**
  Future<void> _playSound() async {
    if (!_soundEnabled) return;
    try {
      await _audioPlayer.stop(); // Ensure it's ready to play again
      await _audioPlayer.setSource(AssetSource(_currentSound));
      await _audioPlayer.resume(); // Start playback
    } catch (e) {
      print('🎵 Audio play error: $e');
    }
  }

  /// **Updates BPM and recalculates durations while running.**
  void setBpm(int bpm) {
    _bpm = bpm.clamp(40, 240);
    if (_isPlaying) {
      stopMetronome();
      startMetronome();
    }
    notifyListeners();
  }

  /// **Updates bar length and recalculates durations.**
  void setBar(int bar) {
    _bar = bar.clamp(1, 16);
    if (_isPlaying) {
      stopMetronome();
      startMetronome();
    }
    notifyListeners();
  }

  /// **Updates beats per bar and recalculates durations.**
  void setBeats(int beats) {
    _beats = beats.clamp(1, 16);
    if (_isPlaying) {
      stopMetronome();
      startMetronome();
    }
    notifyListeners();
  }

  /// **Updates clicks per beat and recalculates durations.**
  void setClicks(int clicks) {
    _clicks = clicks.clamp(1, 16);
    if (_isPlaying) {
      stopMetronome();
      startMetronome();
    }
    notifyListeners();
  }

  void toggleSound(bool enabled) {
    _soundEnabled = enabled;
    notifyListeners();
  }

  /// **Selects the metronome sound file.**
  void selectSound(String soundPath) {
    _currentSound = soundPath;
    notifyListeners();
  }
}

