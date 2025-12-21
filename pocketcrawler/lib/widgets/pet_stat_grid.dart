import 'package:flutter/material.dart';
import '../../pet.dart'; // Import Pet class

class PetStatGrid extends StatelessWidget {
  final Pet pet;

  const PetStatGrid({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    final stats = ['Strength', 'Dexterity', 'Constitution', 'Intelligence', 'Wisdom', 'Charisma'];

    return Container(
      color: const Color(0xFFECF0F1),
      padding: const EdgeInsets.all(10),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: stats.length,
        itemBuilder: (c, i) => _buildStatCard(stats[i]),
      ),
    );
  }

  Widget _buildStatCard(String stat) {
    int val = pet.getTotalStat(stat);
    int mod = ((val - 10) / 2).floor();

    return Card(
      elevation: 2,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(val.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(stat.substring(0,3).toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(mod >= 0 ? "+$mod" : "$mod", style: TextStyle(color: mod >= 0 ? Colors.green : Colors.red)),
        ],
      ),
    );
  }
}