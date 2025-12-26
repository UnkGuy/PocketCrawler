import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class TownService {
  int gold = 0;
  int wood = 0;
  int stone = 0;

  int kitchenLevel = 1;
  int incubatorLevel = 1;
  int gymLevel = 1;

  int currentGeneration = 1;
  List<ShopItem> dailyShop = [];

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

      if (map['dailyShop'] != null) {
        dailyShop = (map['dailyShop'] as List).map((i) => ShopItem.fromJson(i)).toList();
      }
    }

    if (dailyShop.isEmpty) refreshShop();
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
      'dailyShop': dailyShop.map((i) => i.toJson()).toList(),
    };
    await prefs.setString('town_data', jsonEncode(map));
  }

  int getUpgradeCost(String building) {
    int level = 0;
    if (building == 'kitchen') level = kitchenLevel;
    if (building == 'incubator') level = incubatorLevel;
    if (building == 'gym') level = gymLevel;
    return level * 100;
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
    gold += g; wood += w; stone += s;
    saveData();
  }

  void refreshShop() {
    final random = Random();
    dailyShop.clear();

    dailyShop.add(ShopItem(id: 'protein_shake', name: 'Protein Shake', description: '+1 STR (Perm)', cost: 150, effectStat: 'strength', effectAmount: 1));

    List<String> stats = ['dexterity', 'intelligence', 'wisdom', 'constitution'];
    String randomStat = stats[random.nextInt(stats.length)];
    dailyShop.add(ShopItem(
        id: 'crystal_$randomStat',
        name: '${randomStat.substring(0,3).toUpperCase()} Crystal',
        description: '+2 $randomStat (Perm)',
        cost: 300,
        effectStat: randomStat,
        effectAmount: 2
    ));

    dailyShop.add(ShopItem(id: 'golden_apple', name: 'Golden Apple', description: 'Heal Full HP', cost: 500, isConsumable: true));
  }

  bool buyItem(ShopItem item) {
    if (gold >= item.cost) {
      gold -= item.cost;
      dailyShop.remove(item);
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

  // --- JSON SERIALIZATION (FIXED) ---
  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'description': description, 'cost': cost,
    'effectStat': effectStat, 'effectAmount': effectAmount, 'isConsumable': isConsumable
  };

  factory ShopItem.fromJson(Map<String, dynamic> json) {
    return ShopItem(
      id: json['id'], name: json['name'], description: json['description'], cost: json['cost'],
      effectStat: json['effectStat'], effectAmount: json['effectAmount'], isConsumable: json['isConsumable'] ?? false,
    );
  }
}