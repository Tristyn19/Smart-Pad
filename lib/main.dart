import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_ble/universal_ble.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Pages/timer_state.dart';
import 'Pages/graph_page.dart';
import 'Pages/SavedTimeProvider.dart';
import 'Pages/metronome_page.dart';
import 'Pages/metronome_controller.dart';
import 'Pages/settings_page.dart';
import 'Pages/connection_page.dart';
import 'Pages/data_page.dart';
import 'Pages/ble_manager.dart';

void main() async {
  //where the code always run
  WidgetsFlutterBinding.ensureInitialized();
  BLEManager().initialize();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final themeNotifier = ThemeNotifier();
  await themeNotifier.loadThemePreference();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => MetronomeController()),
          ChangeNotifierProvider(create: (_) => TimerState()),
          ChangeNotifierProvider(create: (_) => SavedTimeProvider()),
          ChangeNotifierProvider(create: (context) => ThemeNotifier()),
        ],
        child: const SmartPad(),
      ),
    );
  }


class ThemeNotifier with ChangeNotifier {
  bool _isDarkMode = false;
  Color _accentColor = Colors.blue;

  bool get isDarkMode => _isDarkMode;
  Color get accentColor => _accentColor;

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
  }
  
  Future<void> changeAccentColor(Color newColor) async {
    _accentColor = newColor;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accentColor', newColor.value);
  }
  
  // Load saved theme preference
  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _accentColor = Color(prefs.getInt('accentColor') ?? Colors.blue.value);
    notifyListeners();
  }

}

class SmartPad extends StatefulWidget {
  const SmartPad({super.key});

  @override
  _SmartPadState createState() => _SmartPadState();
}

class _SmartPadState extends State<SmartPad> {
  late BLEManager bleManager;
  BleDevice? selectedDevice;

  @override
  void initState() {
    super.initState();
    bleManager = BLEManager();
  }

  void selectDevice(BleDevice device) {
    setState(() {
      selectedDevice = device;
      bleManager = BLEManager();
    });

    bleManager.connectToDevice(device.deviceId);
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      title: 'Smart Practice Pad',
      theme: ThemeData(
        brightness: themeNotifier.isDarkMode ? Brightness.dark : Brightness.light,
        primaryColor: themeNotifier.accentColor,
          colorScheme: ColorScheme.fromSeed(
            seedColor: themeNotifier.accentColor,
            brightness: themeNotifier.isDarkMode ? Brightness.dark : Brightness.light,
          ),
      ),
      home: HomePage(bleManager: bleManager, selectedDevice: selectedDevice),
    );
  }
}

class HomePage extends StatefulWidget {
  final BLEManager bleManager;
  final BleDevice? selectedDevice;

  const HomePage({required this.bleManager, this.selectedDevice, Key? key})
      : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  late BLEManager bleManager;
  BleDevice? selectedDevice;

  @override
  void initState() {
    super.initState();
    bleManager = widget.bleManager;
    selectedDevice = widget.selectedDevice;
  }

  void updateBleManager(BLEManager newManager) {
    setState(() {
      bleManager = newManager; // ✅ Now setState() works!
    });
    print("HomePage updated with new BLEmanager deviceID: ${bleManager.connectedDeviceId}");
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Smart Practice Pad'),
          bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.show_chart), text: 'Graph'),
                Tab(icon: Icon(Icons.music_note), text: 'Metronome'),
                Tab(icon: Icon(Icons.data_object), text: 'Data'),
              ],
          ),
          actions: [
            DropdownButton<String>(
                onChanged: (String? value) {
                  if (value == 'Bluetooth') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SettingsPage(
                            bleManager: bleManager,
                            onBleManagerUpdated: (newManager) {
                              setState(() {
                                bleManager = newManager;
                              });
                            }
                          ),
                      ),
                    );
                  } else if (value == 'Settings') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const connectionPage()),
                    );
                  }
                },
            underline: const SizedBox(),
            icon: const Icon(Icons.more_vert, color: Colors.blue),
            items: const [
              DropdownMenuItem(
                  value: 'Bluetooth',
                  child: Text('Bluetooth'),
              ),
              DropdownMenuItem(
                  value: 'Settings',
                  child: Text('Settings')
              ),
            ],
            ),
          ],
        ),
        body: TabBarView(
            children: [
              GraphPage(bleManager: bleManager),
              const MetronomePage(),
              DataPage(),
            ],
        ),
      )
    );
  }
}





