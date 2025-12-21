import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class TownService {
  // Resources
  int gold = 0;
  int wood = 0;
  int stone = 0;

  // Building Levels
  int kitchenLevel = 1; // Increases feeding efficiency
  int incubatorLevel = 1; // Increases starting stats of new pets
  int gymLevel = 1; // Increases max potential stats

  // Lineage
  int currentGeneration = 1;

  static final TownService _instance = TownService._internal();
  factory TownService() => _instance;
  TownService._internal();

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('town_data');
    if (data != null) {
      Map<String, dynamic> map = jsonDecode(data);
      gold = map['gold'] ?? 0;
      wood = map['wood'] ?? 0;
      stone = map['stone'] ?? 0;
      kitchenLevel = map['kitchenLevel'] ?? 1;
      incubatorLevel = map['incubatorLevel'] ?? 1;
      gymLevel = map['gymLevel'] ?? 1;
      currentGeneration = map['currentGeneration'] ?? 1;
    }
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> map = {
      'gold': gold,
      'wood': wood,
      'stone': stone,
      'kitchenLevel': kitchenLevel,
      'incubatorLevel': incubatorLevel,
      'gymLevel': gymLevel,
      'currentGeneration': currentGeneration,
    };
    await prefs.setString('town_data', jsonEncode(map));
  }

  // --- UPGRADE LOGIC ---

  int getUpgradeCost(String building) {
    // Simple logic: Cost = Level * 50 Gold + Level * 20 Wood
    int level = 0;
    if (building == 'kitchen') level = kitchenLevel;
    if (building == 'incubator') level = incubatorLevel;
    if (building == 'gym') level = gymLevel;

    return level * 100; // Simplified to just Gold for now
  }

  bool tryUpgrade(String building) {
    int cost = getUpgradeCost(building);
    if (gold >= cost) {
      gold -= cost;
      if (building == 'kitchen') kitchenLevel++;
      if (building == 'incubator') incubatorLevel++;
      if (building == 'gym') gymLevel++;
      saveData();
      return true;
    }
    return false;
  }

  void addResources(int g, int w, int s) {
    gold += g;
    wood += w;
    stone += s;
    saveData();
  }

  // --- SHOP LOGIC ---
  List<ShopItem> dailyShop = [];
  DateTime? lastShopRefresh;

  // Call this when loading data or returning from dungeon
  void refreshShop() {
    final random = Random();
    dailyShop.clear();

    // 1. Guaranteed Food (Stat Up)
    dailyShop.add(ShopItem(
        id: 'protein_shake',
        name: 'Protein Shake',
        description: '+1 STR (Permanent)',
        cost: 150,
        effectStat: 'strength',
        effectAmount: 1
    ));

    // 2. Random Crystal (Evolution Item)
    List<String> stats = ['dexterity', 'intelligence', 'wisdom', 'constitution'];
    String randomStat = stats[random.nextInt(stats.length)];
    dailyShop.add(ShopItem(
        id: 'crystal_$randomStat',
        name: '${randomStat.substring(0,3).toUpperCase()} Crystal',
        description: '+2 $randomStat (Permanent)',
        cost: 300,
        effectStat: randomStat,
        effectAmount: 2
    ));

    // 3. Expensive Relic
    dailyShop.add(ShopItem(
      id: 'golden_apple',
      name: 'Golden Apple',
      description: 'Fully Heal + Max Hunger',
      cost: 500,
      isConsumable: true,
    ));

    // Save/Load this logic if you want shop to persist between app closes
  }

  bool buyItem(ShopItem item) {
    if (gold >= item.cost) {
      gold -= item.cost;
      dailyShop.remove(item); // Remove from shelf
      saveData();
      return true;
    }
    return false;
  }
}

class ShopItem {
  final String id;
  final String name;
  final String description;
  final int cost;
  final String? effectStat;
  final int? effectAmount;
  final bool isConsumable;

  ShopItem({required this.id, required this.name, required this.description, required this.cost, this.effectStat, this.effectAmount, this.isConsumable = false});
}