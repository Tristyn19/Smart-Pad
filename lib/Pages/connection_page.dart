import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:practice_pad/main.dart';
import 'package:url_launcher/url_launcher.dart';

class connectionPage extends StatelessWidget {
  const connectionPage({super.key});

  Future<void> _launchWebsite() async {
    Uri uri = Uri.parse('https://creative-performance.github.io/Smart-Pad/user-manual.html');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } else {
      throw 'Could not launch $uri';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    // Define available accent colors
    final List<Map<String, dynamic>> accentColors = [
      {'name': 'Blue', 'color': const Color(0xFF6772B1)},
      {'name': 'Red', 'color': const Color(0xFFD63A57)},
      {'name': 'Green', 'color': const Color(0xFF33844A)},
      {'name': 'Orange', 'color': const Color(0xFF9C6A36)},
      {'name': 'Purple', 'color': const Color(0xFF8A65A7)},
    ];

    // Validate if the current accent color is in the list
    bool isAccentColorValid(Color color) {
      return accentColors.any((element) => element['color'] == color);
    }

    // Reset to default color if current accentColor is invalid
    if (!isAccentColorValid(themeNotifier.accentColor)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        themeNotifier.changeAccentColor(accentColors.first['color']);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Dark Mode Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Turn Dark Mode on: '),
                Switch(
                  value: themeNotifier.isDarkMode,
                  onChanged: (value) {
                    themeNotifier.toggleTheme();
                  },
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Accent Color Dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Accent Color: '),
                DropdownButton<Color>(
                  value: isAccentColorValid(themeNotifier.accentColor)
                      ? themeNotifier.accentColor
                      : accentColors.first['color'],
                  onChanged: (Color? newColor) {
                    if (newColor != null) {
                      themeNotifier.changeAccentColor(newColor);
                    }
                  },
                  items: accentColors.map((colorData) {
                    return DropdownMenuItem<Color>(
                      value: colorData['color'] as Color,
                      child: Text(colorData['name']),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 40),

            ElevatedButton.icon(
              icon: const Icon(Icons.menu_book),
              label: const Text('View Instruction Manual'),
              onPressed: _launchWebsite,
            ),
          ],
        ),
      ),
    );
  }
}
