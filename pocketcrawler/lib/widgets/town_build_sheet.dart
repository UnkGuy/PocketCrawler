import 'package:flutter/material.dart';
import '../../petsim/town_service.dart';

class TownBuildSheet extends StatefulWidget {
  final TownService townService;
  final VoidCallback onUpgrade; // Callback to refresh parent screen

  const TownBuildSheet({super.key, required this.townService, required this.onUpgrade});

  @override
  State<TownBuildSheet> createState() => _TownBuildSheetState();
}

class _TownBuildSheetState extends State<TownBuildSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF1E272E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Sanctuary Upgrades", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber),
                  Text(" ${widget.townService.gold}", style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),

          Expanded(
            child: ListView(
              children: [
                _buildUpgradeTile("Kitchen", "Food restores more hunger.", widget.townService.kitchenLevel, 'kitchen'),
                _buildUpgradeTile("Incubator", "New pets start with higher stats.", widget.townService.incubatorLevel, 'incubator'),
                _buildUpgradeTile("Gym", "Increases max potential stats.", widget.townService.gymLevel, 'gym'),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildUpgradeTile(String name, String desc, int level, String key) {
    int cost = widget.townService.getUpgradeCost(key);
    bool canAfford = widget.townService.gold >= cost;

    return Card(
      color: Colors.white10,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: const BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle),
          child: Center(child: Text("$level", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ),
        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(desc, style: const TextStyle(color: Colors.grey)),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: canAfford ? Colors.green : Colors.grey[700],
            foregroundColor: Colors.white,
          ),
          onPressed: canAfford ? () {
            if (widget.townService.tryUpgrade(key)) {
              setState(() {}); // Refresh local sheet
              widget.onUpgrade(); // Refresh parent screen
            }
          } : null,
          child: Text(canAfford ? "Upgrade ($cost G)" : "Need $cost G"),
        ),
      ),
    );
  }
}