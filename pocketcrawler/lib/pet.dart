import 'dart:math';
import 'package:flutter/material.dart';

import 'dungeon/dice_roller.dart';
// IMPORT SCENARIO TO GET THE STATUS EFFECT CLASSES
import 'dungeon/scenario.dart';

/// Represents a pet with DND-style ability scores and health system
class Pet {
  String name;
  int generation; // <--- NEW FIELD

  // ... existing stats ...
  int strength;
  int dexterity;
  int constitution;
  int intelligence;
  int wisdom;
  int charisma;
  int currentHealth;
  int maxHealth;

  List<StatusEffect> activeEffects;
  Map<String, int> tempStatModifiers;

  Pet({
    required this.name,
    this.generation = 1, // <--- Default to 1
    required this.strength,
    required this.dexterity,
    required this.constitution,
    required this.intelligence,
    required this.wisdom,
    required this.charisma,
  })  : maxHealth = _calculateMaxHealth(constitution),
        currentHealth = _calculateMaxHealth(constitution),
        activeEffects = [],
        tempStatModifiers = {
          'strength': 0,
          'dexterity': 0,
          'constitution': 0,
          'intelligence': 0,
          'wisdom': 0,
          'charisma': 0,
        };

  factory Pet.rollStats(String name) {
    final stats = DiceRoller.rollStatArray();
    return Pet(
      name: name,
      generation: 1, // <--- Default
      strength: stats[0],
      dexterity: stats[1],
      constitution: stats[2],
      intelligence: stats[3],
      wisdom: stats[4],
      charisma: stats[5],
    );
  }

  // ... (Keep your getters, setters, and modifiers exactly as they were) ...

  int getTotalStat(String statName) {
    int baseStat = _getBaseStat(statName);
    return baseStat + (tempStatModifiers[statName.toLowerCase()] ?? 0);
  }

  int getStatModifier(String statName) {
    return DiceRoller.getModifier(getTotalStat(statName));
  }

  void modifyStat(String statName, int amount) {
    int currentBase = _getBaseStat(statName);
    int newBase = (currentBase + amount).clamp(1, 30);
    _setBaseStat(statName, newBase);
  }

  void applyTempModifier(String statName, int amount) {
    String stat = statName.toLowerCase();
    if (tempStatModifiers.containsKey(stat)) {
      tempStatModifiers[stat] = (tempStatModifiers[stat] ?? 0) + amount;
    }
  }

  void swapStats(String stat1, String stat2) {
    int val1 = _getBaseStat(stat1);
    int val2 = _getBaseStat(stat2);
    _setBaseStat(stat1, val2);
    _setBaseStat(stat2, val1);
  }

  static int _calculateMaxHealth(int constitution) {
    int conModifier = DiceRoller.getModifier(constitution);
    return max(1, 10 + conModifier);
  }

  void takeDamage(int damage) {
    currentHealth = (currentHealth - damage).clamp(0, maxHealth);
  }

  void heal(int amount) {
    currentHealth = (currentHealth + amount).clamp(0, maxHealth);
  }

  void _recalculateHealthOnConChange() {
    int oldMax = maxHealth;
    maxHealth = _calculateMaxHealth(constitution);
    if (oldMax > 0) {
      currentHealth = ((currentHealth.toDouble() / oldMax) * maxHealth).round();
    } else {
      currentHealth = maxHealth;
    }
  }

  // ============================================================================
  // STATUS EFFECTS LOGIC
  // ============================================================================

  void addStatusEffect(StatusEffect effect) {
    // We create a copy so we don't modify the original constant from the scenario library
    StatusEffect newEffect = effect.copyWith();

    if(newEffect.canStack){
      activeEffects.add(newEffect);
      return;
    }

    final existingIndex = activeEffects.indexWhere((e) => e.name == newEffect.name);
    if (existingIndex != -1) {
      // Refresh duration using our copyWith method
      activeEffects[existingIndex] = activeEffects[existingIndex].copyWith(duration: newEffect.duration);
    } else {
      activeEffects.add(newEffect);
    }
  }

  bool hasEffect(StatusEffectType type) {
    return activeEffects.any((effect) => effect.type == type);
  }

  void decrementEffectDurations() {
    // We iterate backwards or create a new list to safely remove items while iterating
    for (int i = activeEffects.length - 1; i >= 0; i--) {
      // Create a copy with reduced duration
      var current = activeEffects[i];
      activeEffects[i] = current.copyWith(duration: current.duration - 1);

      if (activeEffects[i].duration <= 0) {
        activeEffects.removeAt(i);
      }
    }
  }

  // ... (Rest of your helpers like _getBaseStat, _setBaseStat, etc.) ...

  int _getBaseStat(String statName) {
    switch (statName.toLowerCase()) {
      case 'strength': return strength;
      case 'dexterity': return dexterity;
      case 'constitution': return constitution;
      case 'intelligence': return intelligence;
      case 'wisdom': return wisdom;
      case 'charisma': return charisma;
      default: return 0;
    }
  }

  void _setBaseStat(String statName, int value) {
    switch (statName.toLowerCase()) {
      case 'strength': strength = value; break;
      case 'dexterity': dexterity = value; break;
      case 'constitution': constitution = value; _recalculateHealthOnConChange(); break;
      case 'intelligence': intelligence = value; break;
      case 'wisdom': wisdom = value; break;
      case 'charisma': charisma = value; break;
    }
  }

  bool get isAlive => currentHealth > 0;

  void resetForNewRun() {
    currentHealth = maxHealth;
    activeEffects.clear();
    tempStatModifiers.updateAll((key, value) => 0);
  }

  Pet copy() {
    return Pet(
      name: name,
      strength: strength,
      dexterity: dexterity,
      constitution: constitution,
      intelligence: intelligence,
      wisdom: wisdom,
      charisma: charisma,
    );
  }

  @override
  String toString() {
    return '''
Pet: $name
STR: ${getTotalStat('strength')} | DEX: ${getTotalStat('dexterity')} | CON: ${getTotalStat('constitution')}
INT: ${getTotalStat('intelligence')} | WIS: ${getTotalStat('wisdom')} | CHA: ${getTotalStat('charisma')}
HP: $currentHealth/$maxHealth
Active Effects: ${activeEffects.length}
    ''';
  }
}

// DELETE THE CLASSES THAT WERE HERE (StatusEffect, StatusEffect_old, StatusEffectType)
// They are now imported from scenario.dart