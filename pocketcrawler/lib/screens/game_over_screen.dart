import 'package:flutter/material.dart';
import '../dungeon/game_state.dart';
import 'home_screen.dart';

class GameOverScreen extends StatelessWidget {
  final RunSummary summary;

  const GameOverScreen({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Run Complete'),
        backgroundColor: Colors.deepPurple,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              summary.isDungeonCleared ? Icons.emoji_events : Icons.dangerous,
              size: 100,
              color: summary.isDungeonCleared ? Colors.amber : Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              summary.isDungeonCleared ? 'DUNGEON CLEARED!' : 'GAME OVER',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Statistics',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 20),
                    _buildStatRow('Floors Reached', '${summary.floorsReached}'),
                    _buildStatRow('Choices Made', '${summary.choicesMade}'),
                    _buildStatRow('Items Found', '${summary.itemsFound}'),
                    _buildStatRow('Floors Skipped', '${summary.floorsSkipped}'),
                    _buildStatRow('Floors Lost', '${summary.floorsLost}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stat Changes',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 20),
                    ...summary.statChanges.entries.map((entry) {
                      final change = entry.value;
                      final color = change > 0 ? Colors.green : change < 0 ? Colors.red : Colors.white70;
                      final prefix = change > 0 ? '+' : '';
                      return _buildStatRow(
                        entry.key.toUpperCase(),
                        '$prefix$change',
                        valueColor: color,
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                      (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.deepPurple,
              ),
              child: const Text('RETURN TO MENU', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 18)),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}