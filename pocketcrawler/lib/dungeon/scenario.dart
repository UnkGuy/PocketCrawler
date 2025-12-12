import 'dart:math';
import '../pet.dart';
import 'dice_roller.dart';

/// Represents a scenario encounter in the dungeon
class Scenario {
  final String id;
  final String title;
  final String description;
  final List<Choice> choices;
  final ScenarioRarity rarity;

  const Scenario({
    required this.id,
    required this.title,
    required this.description,
    required this.choices,
    this.rarity = ScenarioRarity.common,
  });

  /// Select a random scenario based on weighted rarity
  static Scenario selectRandomScenario(List<Scenario> scenarios) {
    if (scenarios.isEmpty) {
      throw ArgumentError('Cannot select from empty scenario list');
    }

    // Roll for rarity using DiceRoller
    String rarityRoll = DiceRoller.rollRarity();
    ScenarioRarity targetRarity = _rarityFromString(rarityRoll);

    // Filter scenarios by rarity
    final availableScenarios = scenarios
        .where((s) => s.rarity == targetRarity)
        .toList();

    // Fallback to any random scenario if none match
    if (availableScenarios.isEmpty) {
      availableScenarios.addAll(scenarios);
    }

    return availableScenarios[Random().nextInt(availableScenarios.length)];
  }

  /// Convert string rarity to enum
  static ScenarioRarity _rarityFromString(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'uncommon':
        return ScenarioRarity.uncommon;
      case 'rare':
        return ScenarioRarity.rare;
      default:
        return ScenarioRarity.common;
    }
  }

  @override
  String toString() => '$title - $description';
}

// ==============================================================================
// SCENARIO RARITY
// ==============================================================================

/// Rarity of scenarios for weighted random selection
enum ScenarioRarity {
  common, // 70% chance
  uncommon, // 20% chance
  rare, // 10% chance
}

// ==============================================================================
// CHOICE
// ==============================================================================

/// Represents a choice the player can make in a scenario
class Choice {
  final String text;
  final String statRequired;
  final int difficultyClass;
  final Outcome successOutcome;
  final Outcome failureOutcome;
  final CheckType checkType;

  const Choice({
    required this.text,
    required this.statRequired,
    required this.difficultyClass,
    required this.successOutcome,
    required this.failureOutcome,
    this.checkType = CheckType.normal,
  });

  /// Calculate success chance for this choice
  double getSuccessChance(Pet pet, {bool hasAdvantage = false, bool hasDisadvantage = false}) {
    // Combine check type with pet's status effects
    bool finalAdvantage = (checkType == CheckType.advantage || hasAdvantage) && !hasDisadvantage;
    bool finalDisadvantage = (checkType == CheckType.disadvantage || hasDisadvantage) && !hasAdvantage;

    return DiceRoller.calculateSuccessChance(
      dc: difficultyClass,
      modifier: pet.getStatModifier(statRequired),
      advantage: finalAdvantage,
      disadvantage: finalDisadvantage,
    );
  }
}

/// Type of ability check
enum CheckType {
  normal,
  advantage,
  disadvantage,
}

// ==============================================================================
// OUTCOME
// ==============================================================================

/// Represents the outcome of a choice
class Outcome {
  final String description;
  final List<OutcomeEffect> effects;

  const Outcome({
    required this.description,
    required this.effects,
  });

  /// Apply all effects to the pet and return a detailed result message
  String apply(Pet pet, GameStateCallback? callback) {
    StringBuffer resultMessage = StringBuffer(description);

    for (var effect in effects) {
      String effectMessage = _applyEffect(effect, pet, callback);
      if (effectMessage.isNotEmpty) {
        resultMessage.write('\n$effectMessage');
      }
    }

    return resultMessage.toString();
  }

  /// Apply a single effect and return its message
  String _applyEffect(OutcomeEffect effect, Pet pet, GameStateCallback? callback) {
    switch (effect.type) {
      case OutcomeEffectType.statChange:
        return _applyStatChange(effect, pet);

      case OutcomeEffectType.healthChange:
        return _applyHealthChange(effect, pet);

      case OutcomeEffectType.statusEffect:
        return _applyStatusEffect(effect, pet);

      case OutcomeEffectType.giveItem:
        return _applyGiveItem(effect, callback);

      case OutcomeEffectType.skipFloors:
        return _applySkipFloors(effect, callback);

      case OutcomeEffectType.loseFloors:
        return _applyLoseFloors(effect, callback);

      case OutcomeEffectType.swapStats:
        return _applySwapStats(effect, pet);

      case OutcomeEffectType.maxHealthChange:
        return _applyMaxHealthChange(effect, pet);

      }
  }

  String _applyStatChange(OutcomeEffect effect, Pet pet) {
    if (effect.statName == null || effect.amount == null) return '';
    pet.modifyStat(effect.statName!, effect.amount!);
    return '${effect.statName!.toUpperCase()} ${effect.amount! > 0 ? '+' : ''}${effect.amount}';
  }

  String _applyHealthChange(OutcomeEffect effect, Pet pet) {
    if (effect.amount == null) return '';
    if (effect.amount! < 0) {
      pet.takeDamage(effect.amount!.abs());
      return 'Lost ${effect.amount!.abs()} HP';
    } else {
      pet.heal(effect.amount!);
      return 'Healed ${effect.amount} HP';
    }
  }

  String _applyStatusEffect(OutcomeEffect effect, Pet pet) {

    if (effect.statusEffect == null) return '';
    pet.addStatusEffect(effect.statusEffect!);
    return 'Gained: ${effect.statusEffect!.name}';
  }

  String _applyGiveItem(OutcomeEffect effect, GameStateCallback? callback) {
    if (callback == null || effect.itemId == null) return '';
    callback(effect);
    return 'Received: ${effect.itemId}';
  }

  String _applySkipFloors(OutcomeEffect effect, GameStateCallback? callback) {
    if (callback == null || effect.amount == null) return '';
    callback(effect);
    return 'Skipped ${effect.amount} floors!';
  }

  String _applyLoseFloors(OutcomeEffect effect, GameStateCallback? callback) {
    if (callback == null || effect.amount == null) return '';
    callback(effect);
    return 'Sent back ${effect.amount} floors!';
  }

  String _applySwapStats(OutcomeEffect effect, Pet pet) {
    if (effect.statName == null || effect.secondStatName == null) return '';
    pet.swapStats(effect.statName!, effect.secondStatName!);
    return 'Swapped ${effect.statName!.toUpperCase()} and ${effect.secondStatName!.toUpperCase()}!';
  }

  String _applyMaxHealthChange(OutcomeEffect effect, Pet pet) {
    if (effect.amount == null) return '';
    pet.modifyStat('constitution', effect.amount!);
    return 'Max HP ${effect.amount! > 0 ? 'increased' : 'decreased'}!';
  }
}

/// Callback type for game state changes
typedef GameStateCallback = void Function(OutcomeEffect effect);

// ==============================================================================
// OUTCOME EFFECT
// ==============================================================================

/// Individual effect within an outcome
class OutcomeEffect {
  final OutcomeEffectType type;
  final String? statName;
  final String? secondStatName;
  final int? amount;
  final StatusEffect? statusEffect;
  final String? itemId;

  const OutcomeEffect({
    required this.type,
    this.statName,
    this.secondStatName,
    this.amount,
    this.statusEffect,
    this.itemId,
  });

  // ----------------------------------------------------------------------------
  // FACTORY CONSTRUCTORS
  // ----------------------------------------------------------------------------

  const OutcomeEffect.statChange(String this.statName, int this.amount)
      : type = OutcomeEffectType.statChange,
        secondStatName = null,
        statusEffect = null,
        itemId = null;

  const OutcomeEffect.healthChange(int this.amount)
      : type = OutcomeEffectType.healthChange,
        statName = null,
        secondStatName = null,
        statusEffect = null,
        itemId = null;

  const OutcomeEffect.addStatus(StatusEffect effect)
      : type = OutcomeEffectType.statusEffect,
        statName = null,
        secondStatName = null,
        amount = null,
        statusEffect = effect,
        itemId = null;

  const OutcomeEffect.giveItem(String this.itemId)
      : type = OutcomeEffectType.giveItem,
        statName = null,
        secondStatName = null,
        amount = null,
        statusEffect = null;

  const OutcomeEffect.skipFloors(int floors)
      : type = OutcomeEffectType.skipFloors,
        statName = null,
        secondStatName = null,
        amount = floors,
        statusEffect = null,
        itemId = null;

  const OutcomeEffect.loseFloors(int floors)
      : type = OutcomeEffectType.loseFloors,
        statName = null,
        secondStatName = null,
        amount = floors,
        statusEffect = null,
        itemId = null;

  const OutcomeEffect.swapStats(String stat1, String stat2)
      : type = OutcomeEffectType.swapStats,
        statName = stat1,
        secondStatName = stat2,
        amount = null,
        statusEffect = null,
        itemId = null;

  const OutcomeEffect.maxHealthChange(int this.amount)
      : type = OutcomeEffectType.maxHealthChange,
        statName = null,
        secondStatName = null,
        statusEffect = null,
        itemId = null;
}

/// Types of outcome effects
enum OutcomeEffectType {
  statChange, // Modify a stat permanently for this run
  healthChange, // Heal or damage
  statusEffect, // Apply buff/debuff
  giveItem, // Give consumable item
  skipFloors, // Skip forward
  loseFloors, // Go backwards
  swapStats, // Swap two stats
  maxHealthChange, // Increase/decrease max HP
}