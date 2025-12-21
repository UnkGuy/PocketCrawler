import 'dart:convert';
import 'package:flutter/services.dart';
import 'scenario.dart';

class ScenarioLoader {
  static List<Scenario> _cachedScenarios = [];

  /// Loads scenarios from JSON asset
  static Future<List<Scenario>> loadScenarios() async {
    if (_cachedScenarios.isNotEmpty) return _cachedScenarios;

    try {
      final String response = await rootBundle.loadString('assets/data/scenarios.json');
      final List<dynamic> data = json.decode(response);
      _cachedScenarios = data.map((json) => Scenario.fromJson(json)).toList();
      return _cachedScenarios;
    } catch (e) {
      print("Error loading scenarios: $e");
      return []; // Return empty list on error
    }
  }
}