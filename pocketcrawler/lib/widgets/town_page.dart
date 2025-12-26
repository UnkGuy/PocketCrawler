import 'package:flutter/material.dart';
import '../../petsim/pet_game_manager.dart';
import '../../petsim/town_service.dart';

class TownPage extends StatefulWidget {
  final PetGameManager manager;
  const TownPage({super.key, required this.manager});

  @override
  State<TownPage> createState() => _TownPageState();
}

class _TownPageState extends State<TownPage> {

  // --- NPC STATES ---
  String _merchantSpeech = "New wares in stock!";
  String _builderSpeech = "Need an upgrade?";

  // Update speech for a few seconds
  void _setTempSpeech(bool isMerchant, String message) {
    setState(() {
      if (isMerchant) {
        _merchantSpeech = message;
      } else {
        _builderSpeech = message;
      }
    });
    // Reset after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if(mounted) {
        setState(() {
          if (isMerchant) _merchantSpeech = "New wares in stock!";
          else _builderSpeech = "Need an upgrade?";
        });
      }
    });
  }

  // --- MENUS ---
  void _openShopMenu() {
    _setTempSpeech(true, "Take a look!");
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildResponsiveSheet(
        title: "General Store",
        child: ListView(
          shrinkWrap: true,
          children: [
            if (widget.manager.townService.dailyShop.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("Sold Out!", style: TextStyle(color: Colors.brown, fontSize: 18, fontFamily: 'Pixelify')),
              )),
            ...widget.manager.townService.dailyShop.map((item) => _shopTile(item)),
          ],
        ),
      ),
    );
  }

  void _openBuilderMenu() {
    _setTempSpeech(false, "Let's build!");
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildResponsiveSheet(
        title: "The Architect",
        child: ListView(
          shrinkWrap: true,
          children: [
            _upgradeTile("Kitchen", "Food heals more.", widget.manager.townService.kitchenLevel, 'kitchen'),
            _upgradeTile("Incubator", "Better birth stats.", widget.manager.townService.incubatorLevel, 'incubator'),
            _upgradeTile("Gym", "Higher stat cap.", widget.manager.townService.gymLevel, 'gym'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder ensures we know how much space we have
    return LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // No Background Image here! (Handled by PetScreen)

              // --- MERCHANT (Left) ---
              Positioned(
                bottom: constraints.maxHeight * 0.15, // Responsive positioning
                left: 20,
                child: _npcWidget(
                  asset: 'assets/npcs/merchant.png',
                  label: "Shop",
                  dialogue: _merchantSpeech,
                  glowColor: Colors.amber,
                  onTap: _openShopMenu,
                ),
              ),

              // --- BUILDER (Right) ---
              Positioned(
                bottom: constraints.maxHeight * 0.15,
                right: 20,
                child: _npcWidget(
                  asset: 'assets/npcs/builder.png',
                  label: "Build",
                  dialogue: _builderSpeech,
                  glowColor: Colors.blueGrey,
                  onTap: _openBuilderMenu,
                ),
              ),
            ],
          );
        }
    );
  }

  Widget _npcWidget({
    required String asset,
    required String label,
    required String dialogue,
    required Color glowColor,
    required VoidCallback onTap
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          // Speech Bubble
          Container(
            constraints: const BoxConstraints(maxWidth: 120),
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 5),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)]
            ),
            child: Text(
                dialogue,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold)
            ),
          ),

          // Character
          Container(
            height: 140, // Fixed height for NPC sprite
            width: 100,
            decoration: BoxDecoration(
              image: DecorationImage(image: AssetImage(asset), fit: BoxFit.contain),
              boxShadow: [BoxShadow(color: glowColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 1)],
            ),
            // Fallback icon
            child: (asset.contains("merchant"))
                ? Icon(Icons.storefront, size: 50, color: Colors.white.withOpacity(0.5))
                : const SizedBox(),
          ),

          // Label Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
                color: const Color(0xFF3E2723),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF8D6E63))
            ),
            child: Text(label, style: TextStyle(color: glowColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // Responsive Bottom Sheet
  Widget _buildResponsiveSheet({required String title, required Widget child}) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3E5AB), // Parchment
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            border: Border.all(color: const Color(0xFF5D4037), width: 4),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20)],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(title, style: const TextStyle(color: Color(0xFF3E2723), fontSize: 24, fontFamily: 'Pixelify')),
              const Divider(color: Color(0xFF5D4037), thickness: 2),
              Expanded(child: child), // Content scrolls inside
            ],
          ),
        );
      },
    );
  }

  // Reuse your tile widgets here, but update the onTap logic to trigger speech
  Widget _shopTile(ShopItem item) {
    return Card(
      color: Colors.white38,
      child: ListTile(
        leading: const Icon(Icons.star, color: Colors.amber),
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(item.description),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D4037)),
          onPressed: () {
            if (widget.manager.townService.buyItem(item)) {
              // SUCCESS LOGIC
              if (item.effectStat != null) widget.manager.myPet.modifyStat(item.effectStat!, item.effectAmount!);
              if (item.isConsumable) { widget.manager.myPet.heal(999); widget.manager.hunger = 0; }
              widget.manager.forceSave();

              // TRIGGER NPC REACTION
              _setTempSpeech(true, "Great choice! Heh heh.");

              setState((){});
              Navigator.pop(context);
            } else {
              _setTempSpeech(true, "You need more gold!");
            }
          },
          child: Text("${item.cost} G", style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  // (Include _upgradeTile similarly, calling _setTempSpeech(false, "Upgrade complete!"))
  Widget _upgradeTile(String title, String desc, int level, String key) {
    int cost = widget.manager.townService.getUpgradeCost(key);
    bool canAfford = widget.manager.townService.gold >= cost;
    return Card(
      color: Colors.white38,
      child: ListTile(
        title: Text("$title (Lvl $level)", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(desc),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: canAfford ? const Color(0xFF5D4037) : Colors.grey),
          onPressed: canAfford ? () {
            if (widget.manager.townService.tryUpgrade(key)) {
              setState((){});
              _setTempSpeech(false, "Building complete!");
            }
          } : null,
          child: Text("$cost G", style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}