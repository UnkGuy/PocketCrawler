import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
}