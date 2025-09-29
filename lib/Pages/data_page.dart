import 'package:flutter/material.dart';
import 'package:practice_pad/Pages/graph_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'SavedTimeProvider.dart';
import 'dart:convert';
import 'dart:io';

class DataPage extends StatefulWidget {
  const DataPage({super.key});

  @override
  _DataPageState createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  List<String> savedSessions = [];
  List<DataPoint> selectedData = [];
  String _selectedFilter = 'A-Z'; // Default filter

  double _bpm = 0;

  // zoom and pan behavior
  late ZoomPanBehavior _zoomPanBehavior;

  @override
  void initState() {
    super.initState();
    _loadSessions();

    // ✅ Initialize ZoomPanBehavior
    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
      enablePanning: true,
      enableDoubleTapZooming: true,
      zoomMode: ZoomMode.xy, // ✅ Zoom on both X and Y axes
    );
  }

  // Load all session keys from SharedPreferences
  Future<void> _loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedSessions = prefs.getStringList('sessions') ?? [];
    });
  }

  // Load the session data from SharedPreferences
  Future<void> _loadSessionData(String sessionKey) async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonData = prefs.getString(sessionKey);

    if (jsonData == null) return;

    final List<dynamic> dataList = jsonDecode(jsonData);
    setState(() {
      selectedData = dataList.map((data) {
        return DataPoint(
          (data['x'] as num).toDouble(),
          (data['y'] as num).toDouble(),
        );
      }).toList();
    });
  }

  // Delete session from SharedPreferences
  Future<void> _deleteSession(String sessionKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(sessionKey); // Remove the data

    setState(() {
      savedSessions.remove(sessionKey);
      prefs.setStringList('sessions', savedSessions);
      selectedData.clear(); // Clear the graph if the session is deleted
    });
  }

  // Sort sessions based on the selected filter
  List<String> _applyFilter() {
    List<String> sortedSessions = List.from(savedSessions);

    switch (_selectedFilter) {
      case 'A-Z':
        sortedSessions.sort();
        break;
      case 'Z-A':
        sortedSessions.sort((a, b) => b.compareTo(a));
        break;
      case 'Shortest - Longest':
        sortedSessions.sort((a, b) => a.length.compareTo(b.length));
        break;
      case 'Longest - Shortest':
        sortedSessions.sort((a, b) => b.length.compareTo(a.length));
        break;
    }

    return sortedSessions;
  }

  // Export the session to CSV
  Future<String?> _exportSessionToCSV(String sessionKey) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString(sessionKey);

    if (jsonData == null) return null;

    final List<dynamic> dataList = jsonDecode(jsonData);
    final List<DataPoint> dataPoints = dataList.map((data) {
      return DataPoint(
        (data['x'] as num).toDouble(),
        (data['y'] as num).toDouble(),
      );
    }).toList();

    String csvData = 'Time (s), Force (N)\n';
    for (var point in dataPoints) {
      csvData += '${point.x},${point.y}\n';
    }

    try {
      // ✅ Get app's document directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$sessionKey.csv';

      // ✅ Write CSV data to file
      final file = File(filePath);
      await file.writeAsString(csvData);

      print("✅ CSV exported to: $filePath");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ CSV exported to $filePath")),
      );

      return filePath; // ✅ Return path for sharing
    } catch (e) {
      print("❌ Error exporting CSV: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to export CSV")),
      );
      return null;
    }
  }

  Future<void> requestStoragePermission() async {
    if (await Permission.manageExternalStorage.request().isGranted) {
      print("✅ Storage permission granted");
    } else {
      print("❌ Storage permission denied");
    }
  }

  Future<void> _shareCSV(String sessionKey) async {
    final filePath = await _exportSessionToCSV(sessionKey);

    if (filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ No CSV file found. Export first!")),
      );
      return;
    }
    try {
      // ✅ Share the file using SharePlus
      final file = XFile(filePath);
      await Share.shareXFiles([file], text: "📎 Here is the exported CSV file.");
    } catch (e) {
      print("❌ Error sharing CSV: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to share CSV")),
      );
    }
  }

  List<PlotBand> _generateBpmPlotBands() {
    final List<PlotBand> bands = [];
    if (selectedData.isEmpty || _bpm <= 0) return bands;

    double interval = 60 / _bpm;
    double start = selectedData.first.x;
    double end = selectedData.last.x;

    for (double i = start; i <= end; i += interval) {
      bands.add(
        PlotBand(
          isVisible: true,
          start: i,
          end: i + 0.01,
          borderWidth: 1,
          borderColor: Colors.red,
          shouldRenderAboveSeries: true,
        ),
      );
    }

    return bands;
  }

  @override
  Widget build(BuildContext context) {
    final sortedSessions = _applyFilter();

    return Scaffold(
      //appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Dropdown for filtering options
              DropdownButton<String>(
                value: _selectedFilter,
                items: [
                  'A-Z',
                  'Z-A',
                  'Shortest - Longest',
                  'Longest - Shortest',
                ].map((filter) {
                  return DropdownMenuItem<String>(
                    value: filter,
                    child: Text(filter),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                },
              ),
              const SizedBox(height: 20),
              // Display the filtered and sorted list
              SizedBox(
                height: 250, // Set height instead of Expanded
                child: ListView.builder(
                  itemCount: sortedSessions.length,
                  itemBuilder: (context, index) {
                    final sessionKey = sortedSessions[index];
                    return ListTile(
                      title: Text(sessionKey),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _loadSessionData(sessionKey),
                            icon: const Icon(Icons.replay, color: Colors.blue),
                          ),
                          IconButton(
                            onPressed: () => _exportSessionToCSV(sessionKey),
                            icon: const Icon(Icons.download, color: Colors.green),
                          ),
                          IconButton(
                            onPressed: () => _shareCSV(sessionKey),
                            icon: const Icon(Icons.share, color: Colors.purple),
                          ),
                          IconButton(
                            onPressed: () => _deleteSession(sessionKey),
                            icon: const Icon(Icons.delete, color: Colors.red),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              // Show Graph for Selected Session
              //add pinch to zoom graphic
              // BPM input field
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Enter BPM',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _bpm = double.tryParse(value) ?? 60;
                  });
                },
              ),

              const SizedBox(height: 20),
              // ✅ Show Graph for Selected Session with Zoom + Pan
              if (selectedData.isNotEmpty)
                SizedBox(
                  height: 300,
                  child: SfCartesianChart(
                    primaryXAxis: NumericAxis(title: AxisTitle(text: 'Time (s)'),
                    plotBands: _generateBpmPlotBands(),
                    ),
                    primaryYAxis: NumericAxis(title: AxisTitle(text: 'Force (N)')),
                    zoomPanBehavior: _zoomPanBehavior, // ✅ Zoom and Pan Enabled
                    series: <LineSeries<DataPoint, double>>[
                      LineSeries<DataPoint, double>(
                        dataSource: selectedData,
                        xValueMapper: (DataPoint data, _) => data.x,
                        yValueMapper: (DataPoint data, _) => data.y,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),

    );
  }
}

// DataPoint Model
class DataPoint {
  final double x;
  final double y;
  DataPoint(this.x, this.y);
}

