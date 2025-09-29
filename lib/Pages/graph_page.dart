import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'ble_manager.dart';
import 'metronome_controller.dart';

class DataPoint {
  final double x;
  final double y;
  DataPoint(this.x, this.y);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
}

class GraphPage extends StatefulWidget {
  final BLEManager bleManager;

  const GraphPage({required this.bleManager, super.key});

  @override
  _GraphPageState createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  List<DataPoint> dataPoints = [];
  bool isRecording = false;
  double bpm = 60;
  double elapsedSeconds = 0;

  Timer? _updateTimer;
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _setupBLEListeners();
  }

  void _setupBLEListeners() {
    widget.bleManager.clearListeners();

    widget.bleManager.onYDataReceived = (double y) {
      if (isRecording) {
        elapsedSeconds += 0.09375;
        _updateGraph(elapsedSeconds, y);
      }
    };
  }

  void _updateGraph(double x, double y) {
    if (mounted) {
      setState(() {
        dataPoints.add(DataPoint(x, y));

        // ✅ Keep last 10 seconds of data in the graph
        //dataPoints.removeWhere((point) => x - point.x > 10);
      });
    }
  }

  // 🎯 Fast Timer for More Frequent Graph Updates
  void _startUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(milliseconds: 8), (_) {
      if (isRecording) {
        setState(() {
          elapsedSeconds += 0.00833; // Increment every 16ms (~60 FPS)
        });
      }
    });
  }

  void _stopUpdateTimer() {
    _updateTimer?.cancel();
    elapsedSeconds = 0;
  }

  // 🎯 Timer Functions for Session Duration
  void _startTimer() {
    if (_isRunning) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
    });
    setState(() => _isRunning = true);
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _seconds = 0;
      _isRunning = false;
    });
  }

  String _formatTime(int seconds) {
    final int hours = seconds ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // 🎯 Start Recording
  void _startRecording() {
    setState(() {
      isRecording = true;
      dataPoints.clear();
      elapsedSeconds = 0;
    });
    _startUpdateTimer();
    _startTimer();
  }

  // 🎯 Stop Recording
  void _stopRecording() async {
    setState(() {
      isRecording = false;
    });
    _stopUpdateTimer();
    _stopTimer();
    await _saveSession();
  }

  // 🎯 Pause Recording
  void _pauseRecording() {
    _pauseTimer();
    setState(() => isRecording = false);
  }

  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();

    String inputName = '';
    await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save Session'),
          content: TextField(
            onChanged: (value) => inputName = value,
            decoration: const InputDecoration(hintText: 'Enter session name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (inputName.trim().isEmpty) return;
                String jsonData = jsonEncode(
                    dataPoints.map((point) => point.toJson()).toList());

                prefs.setString(inputName, jsonData);

                List<String> sessions = prefs.getStringList('sessions') ?? [];
                sessions.add(inputName);
                prefs.setStringList('sessions', sessions);

                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showEnlargedGraph(List<DataPoint> dataPoints, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(
                height: 400,
                child: SfCartesianChart(
                  primaryXAxis: NumericAxis(),
                  primaryYAxis: NumericAxis(),
                  series: <LineSeries<DataPoint, double>>[
                    LineSeries<DataPoint, double>(
                      dataSource: dataPoints,
                      xValueMapper: (DataPoint data, _) => data.x,
                      yValueMapper: (DataPoint data, _) => data.y,
                      dataLabelSettings: const DataLabelSettings(isVisible: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metronomeState = Provider.of<MetronomeController>(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // 🎯 Timer Display
            Text(
              _formatTime(_seconds),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            // 🎯 Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: _startRecording, child: const Text('Start')),
                const SizedBox(width: 10),
                ElevatedButton(onPressed: _pauseRecording, child: const Text('Pause')),
                const SizedBox(width: 10),
                ElevatedButton(onPressed: _stopRecording, child: const Text('Stop')),
              ],
            ),

            const SizedBox(height: 20),

            // 🎯 Metronome Visual
            Text(
              'Beat: ${metronomeState.currentBeat}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(metronomeState.beats, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor:
                    metronomeState.currentBeat == index + 1
                        ? Colors.blue
                        : Colors.grey,
                  ),
                );
              }),
            ),

            const SizedBox(height: 20),

            // 🎯 Graph Display
            GestureDetector(
              onTap: () => _showEnlargedGraph(dataPoints, 'Graph1'),
              child: SizedBox(
                height: 300,
                child: SfCartesianChart(
                  primaryXAxis: NumericAxis(
                    title: AxisTitle(text: 'Time (s)'),
                    // ✅ Limit X-axis to last 10 seconds of data
                    minimum: dataPoints.isNotEmpty ? dataPoints.last.x - 10 : 0,
                    maximum: dataPoints.isNotEmpty ? dataPoints.last.x : 10,
                  ),
                  primaryYAxis: NumericAxis(title: AxisTitle(text: 'Force (N)')),
                  series: <LineSeries<DataPoint, double>>[
                    LineSeries<DataPoint, double>(
                      dataSource: dataPoints,
                      xValueMapper: (DataPoint data, _) => data.x,
                      yValueMapper: (DataPoint data, _) => data.y,
                    ),
                  ],
                ),
              ),
            ),


            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
