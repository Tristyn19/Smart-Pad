import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'metronome_controller.dart';


class MetronomePage extends StatefulWidget {
  const MetronomePage({super.key});

  @override
  State<MetronomePage> createState() => _MetronomePageState();
}

class _MetronomePageState extends State<MetronomePage>
    with TickerProviderStateMixin {

  @override
  void initState() {
    super.initState();
    final metronomeController = Provider.of<MetronomeController>(context, listen: false);
    metronomeController.initialize(this); // Provide TickerProvider to controller
  }

  @override
  Widget build(BuildContext context) {
    final metronomeController = Provider.of<MetronomeController>(context);

    return Scaffold(
      body: SingleChildScrollView(  // Enables vertical scrolling
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // **🔵 Beat Circle Visuals 🔵**
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(metronomeController.beats, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: metronomeController.currentBeat == index + 1
                          ? Colors.blue  // Highlight current beat
                          : Colors.grey, // Inactive beat
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              // **🔴 Sliding Bar Circle (Moves Across Bar) 🔴**
              //verify accuracy
              Container(
                width: 300, // Bar width
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 16), // 60 FPS updates
                      transform: Matrix4.translationValues(metronomeController.barProgress * 280, 0, 0),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // **📌 BPM Selector**
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: SizedBox(
                  width: 120,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'BPM',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final bpm = int.tryParse(value);
                      if (bpm != null) {
                        metronomeController.setBpm(bpm);
                      }
                    },
                  ),
                ),
              ),


              // **📌 Bar Length Selector**
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Bar Length:', style: TextStyle(fontSize: 18)),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () => metronomeController.setBar(metronomeController.bar - 1),
                  ),
                  Text('${metronomeController.bar}', style: const TextStyle(fontSize: 18)),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => metronomeController.setBar(metronomeController.bar + 1),
                  ),
                ],
              ),

              // **📌 Beats per Bar Selector**
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Beats per Bar:', style: TextStyle(fontSize: 18)),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () => metronomeController.setBeats(metronomeController.beats - 1),
                  ),
                  Text('${metronomeController.beats}', style: const TextStyle(fontSize: 18)),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => metronomeController.setBeats(metronomeController.beats + 1),
                  ),
                ],
              ),

              // **📌 Clicks per Beat Selector**
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Clicks per Beat:', style: TextStyle(fontSize: 18)),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () => metronomeController.setClicks(metronomeController.clicks - 1),
                  ),
                  Text('${metronomeController.clicks}', style: const TextStyle(fontSize: 18)),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => metronomeController.setClicks(metronomeController.clicks + 1),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // **📌 Sound Selection**
              DropdownButton<String>(
                value: metronomeController.currentSound,
                items: const [
                  DropdownMenuItem(value: 'sounds/metronome1.wav', child: Text('Sound 1')),
                  DropdownMenuItem(value: 'sounds/metronome2.wav', child: Text('Sound 2')),
                  DropdownMenuItem(value: 'sounds/metronome3.wav', child: Text('Sound 3')),
                ],
                onChanged: (value) {
                  if (value != null) metronomeController.selectSound(value);
                },
                isExpanded: true,
              ),

              const SizedBox(height: 20),

              // **📌 Start & Stop Buttons**
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: metronomeController.isPlaying ? null : metronomeController.startMetronome,
                    child: const Text('Start'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: metronomeController.isPlaying ? metronomeController.stopMetronome : null,
                    child: const Text('Stop'),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              SwitchListTile(
                title: const Text("Enable Sound"),
                value: metronomeController.isSoundEnabled,
                onChanged: (value) => metronomeController.toggleSound(value),
              ),
              // Bottom spacing for scroll
            ],
          ),
        ),
      ),
    );
  }

}
