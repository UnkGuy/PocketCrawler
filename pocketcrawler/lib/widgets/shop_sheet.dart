import 'package:flutter/material.dart';
import '../../petsim/pet_game_manager.dart';
import '../../petsim/town_service.dart';

class ShopSheet extends StatefulWidget {
  final PetGameManager manager;

  const ShopSheet({super.key, required this.manager});

  @override
  State<ShopSheet> createState() => _ShopSheetState();
}

class _ShopSheetState extends State<ShopSheet> {

  void _buy(ShopItem item) {
    if (widget.manager.townService.buyItem(item)) {
      // Apply Effects Immediately
      if (item.effectStat != null) {
        widget.manager.myPet.modifyStat(item.effectStat!, item.effectAmount!);
      }
      if (item.isConsumable) {
        widget.manager.myPet.heal(999);
        widget.manager.hunger = 0;
      }
      widget.manager.forceSave(); // Helper method you should add to manager
      setState(() {}); // Refresh UI

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Bought ${item.name}!")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Not enough Gold!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // If shop is empty, refresh it (logic usually handled in manager, but failsafe here)
    if (widget.manager.townService.dailyShop.isEmpty) {
      widget.manager.townService.refreshShop();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.brown[900],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Traveling Merchant", style: TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold)),
              Chip(
                backgroundColor: Colors.amber,
                label: Text("${widget.manager.townService.gold} G", style: const TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const Divider(color: Colors.amberAccent),
          Expanded(
            child: ListView.builder(
              itemCount: widget.manager.townService.dailyShop.length,
              itemBuilder: (context, index) {
                final item = widget.manager.townService.dailyShop[index];
                return Card(
                  color: Colors.brown[800],
                  child: ListTile(
                    leading: const Icon(Icons.stars, color: Colors.white),
                    title: Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(item.description, style: const TextStyle(color: Colors.white70)),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                      onPressed: () => _buy(item),
                      child: Text("${item.cost} G", style: const TextStyle(color: Colors.black)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}