import 'dart:math';
import 'dungeon/dice_roller.dart';

/// Represents a pet with DND-style ability scores and health system
class Pet {
  String name;

  // Base DND Ability Scores
  int strength;
  int dexterity;
  int constitution;
  int intelligence;
  int wisdom;
  int charisma;

  // Health system (derived from constitution)
  int currentHealth;
  int maxHealth;

  // Active status effects during dungeon run
  List<StatusEffect> activeEffects;

  // Temporary stat modifiers from items/events (cleared between runs)
  Map<String, int> tempStatModifiers;

  Pet({
    required this.name,
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

  /// Factory: Create pet with randomly rolled stats (4d6 drop lowest)
  factory Pet.rollStats(String name) {
    final stats = DiceRoller.rollStatArray();
    return Pet(
      name: name,
      strength: stats[0],
      dexterity: stats[1],
      constitution: stats[2],
      intelligence: stats[3],
      wisdom: stats[4],
      charisma: stats[5],
    );
  }

  // ============================================================================
  // STAT ACCESSORS & MODIFIERS
  // ============================================================================

  /// Get total stat value (base + temporary modifiers)
  int getTotalStat(String statName) {
    int baseStat = _getBaseStat(statName);
    return baseStat + (tempStatModifiers[statName.toLowerCase()] ?? 0);
  }

  /// Calculate the DND-style modifier for a stat ((stat - 10) / 2)
  int getStatModifier(String statName) {
    return DiceRoller.getModifier(getTotalStat(statName));
  }

  /// Permanently modify a base stat for this run (clamped 1-30)
  void modifyStat(String statName, int amount) {
    int currentBase = _getBaseStat(statName);
    int newBase = (currentBase + amount).clamp(1, 30);
    _setBaseStat(statName, newBase);
  }

  /// Apply temporary stat modifier (from items/buffs)
  void applyTempModifier(String statName, int amount) {
    String stat = statName.toLowerCase();
    if (tempStatModifiers.containsKey(stat)) {
      tempStatModifiers[stat] = (tempStatModifiers[stat] ?? 0) + amount;
    }
  }

  /// Swap two base stats
  void swapStats(String stat1, String stat2) {
    int val1 = _getBaseStat(stat1);
    int val2 = _getBaseStat(stat2);
    _setBaseStat(stat1, val2);
    _setBaseStat(stat2, val1);
  }

  // ============================================================================
  // HEALTH MANAGEMENT
  // ============================================================================

  /// Calculate max health: 10 + CON modifier (minimum 1)
  static int _calculateMaxHealth(int constitution) {
    int conModifier = DiceRoller.getModifier(constitution);
    return max(1, 10 + conModifier);
  }

  /// Apply damage to the pet
  void takeDamage(int damage) {
    currentHealth = (currentHealth - damage).clamp(0, maxHealth);
  }

  /// Heal the pet
  void heal(int amount) {
    currentHealth = (currentHealth + amount).clamp(0, maxHealth);
  }

  /// Recalculate health when constitution changes
  void _recalculateHealthOnConChange() {
    int oldMax = maxHealth;
    maxHealth = _calculateMaxHealth(constitution);

    // Adjust current health proportionally
    if (oldMax > 0) {
      currentHealth = ((currentHealth.toDouble() / oldMax) * maxHealth).round();
    } else {
      currentHealth = maxHealth;
    }
  }

  // ============================================================================
  // STATUS EFFECTS
  // ============================================================================

  /// Add a status effect (buff/debuff)
  void addStatusEffect(StatusEffect effect) {
    StatusEffect newEffect = effect.copyWith();
    if(newEffect.canStack){
      activeEffects.add(newEffect);
      return;
    }

    final existingIndex = activeEffects.indexWhere((e) => e.name == newEffect.name);
    if (existingIndex != -1) {
      // It exists! Refresh the duration of the currently active one.
      activeEffects[existingIndex].duration = newEffect.duration;
      //print("Refreshed duration for: ${newEffect.name}");
    } else {
      // It doesn't exist yet, so we add it.
      activeEffects.add(newEffect);
      //print("Added new unique effect: ${newEffect.name}");
    }
    //print(activeEffects);
  }

  /// Check if pet has a specific status effect type
  bool hasEffect(StatusEffectType type) {
    return activeEffects.any((effect) => effect.type == type);
  }

  /// Decrement all status effect durations and remove expired ones
  void decrementEffectDurations() {
    for (StatusEffect effect in activeEffects) {
      print(effect);
      effect.duration--;
      //why does statue's curse not get removed
    }
    activeEffects.removeWhere((effects) => effects.duration <= 0);
  }

  // ============================================================================
  // HELPER METHODS (INTERNAL)
  // ============================================================================

  /// Get base stat value by name
  int _getBaseStat(String statName) {
    switch (statName.toLowerCase()) {
      case 'strength':
        return strength;
      case 'dexterity':
        return dexterity;
      case 'constitution':
        return constitution;
      case 'intelligence':
        return intelligence;
      case 'wisdom':
        return wisdom;
      case 'charisma':
        return charisma;
      default:
        return 0;
    }
  }

  /// Set base stat value by name
  void _setBaseStat(String statName, int value) {
    switch (statName.toLowerCase()) {
      case 'strength':
        strength = value;
        break;
      case 'dexterity':
        dexterity = value;
        break;
      case 'constitution':
        constitution = value;
        _recalculateHealthOnConChange();
        break;
      case 'intelligence':
        intelligence = value;
        break;
      case 'wisdom':
        wisdom = value;
        break;
      case 'charisma':
        charisma = value;
        break;
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Check if pet is alive
  bool get isAlive => currentHealth > 0;

  /// Reset pet for a new dungeon run (clears temporary effects)
  void resetForNewRun() {
    currentHealth = maxHealth;
    activeEffects.clear();
    tempStatModifiers.updateAll((key, value) => 0);
  }

  /// Create a deep copy of the pet
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

// ==============================================================================
// STATUS EFFECT CLASSES
// ==============================================================================

/// Represents a temporary buff or debuff on the pet
class StatusEffect {
  String name;
  int duration;
  String description;
  StatusEffectType type;
  Map<String, int>? statModifiers;

  final bool canStack;

  StatusEffect({
    required this.name,
    required this.type,
    required this.duration,
    required this.description,
    this.statModifiers,
    this.canStack = true, // Default to true (Stacking) if you prefer
  });

  // Ensure your copyWith handles the new property
  StatusEffect copyWith({int? duration}) {
    return StatusEffect(
      name: this.name,
      type: this.type,
      duration: duration ?? this.duration,
      description: this.description,
      canStack: this.canStack, // Pass the flag along
    );
  }

  @override
  String toString() => '$name ($duration floors): $description';
}
class StatusEffect_old {
  String name;
  StatusEffectType type;
  int duration; // in floors
  String description;

  /// Optional: specific stat modifications
  Map<String, int>? statModifiers;

  StatusEffect_old({
    required this.name,
    required this.type,
    required this.duration,
    required this.description,
    this.statModifiers,
  });

  @override
  String toString() => '$name ($duration floors): $description';
}

/// Types of status effects
enum StatusEffectType {
  advantage, // Roll with advantage on checks
  disadvantage, // Roll with disadvantage on checks
  blessed, // General positive buff
  cursed, // General negative debuff
  statBoost, // Temporary stat increase
  statPenalty, // Temporary stat decrease
}
