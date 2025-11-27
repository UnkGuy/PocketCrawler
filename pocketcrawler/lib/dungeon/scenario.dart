import 'dart:math';
import '../pet.dart';

/// Represents a scenario encounter in the dungeon
class Scenario {
  String id;
  String title;
  String description;
  List<Choice> choices;
  ScenarioRarity rarity;

  Scenario({
    required this.id,
    required this.title,
    required this.description,
    required this.choices,
    this.rarity = ScenarioRarity.common,
  });

  /// Selects a random scenario based on weighted rarity
  static Scenario selectRandomScenario(List<Scenario> scenarios) {
    final random = Random();

    // Determine rarity based on weighted roll
    ScenarioRarity targetRarity;
    int roll = random.nextInt(100);

    if (roll < 70) {
      targetRarity = ScenarioRarity.common;
    } else if (roll < 90) {
      targetRarity = ScenarioRarity.uncommon;
    } else {
      targetRarity = ScenarioRarity.rare;
    }

    // Filter scenarios by the chosen rarity
    final availableScenarios = scenarios.where((s) => s.rarity == targetRarity).toList();

    // If no scenarios of that rarity exist, fall back to any random scenario
    if (availableScenarios.isEmpty) {
      return scenarios[random.nextInt(scenarios.length)];
    }

    return availableScenarios[random.nextInt(availableScenarios.length)];
  }

  @override
  String toString() => '$title - $description';
}

/// Rarity of scenarios for weighted random selection
enum ScenarioRarity {
  common,    // 70% chance
  uncommon,  // 20% chance
  rare,      // 10% chance
}

/// Represents a choice the player can make in a scenario
class Choice {
  String text;
  String statRequired; // e.g., 'strength', 'dexterity', etc.
  int difficultyClass; // DC for the check (like in DND)
  Outcome successOutcome;
  Outcome failureOutcome;
  CheckType checkType; // normal, advantage, disadvantage

  Choice({
    required this.text,
    required this.statRequired,
    required this.difficultyClass,
    required this.successOutcome,
    required this.failureOutcome,
    this.checkType = CheckType.normal,
  });

  /// Calculate success chance (approximation for display)
  double getSuccessChance(Pet pet) {
    int totalBonus = pet.getStatModifier(statRequired);
    int neededRoll = difficultyClass - totalBonus;

    // Clamp between 1 and 20 (a natural 1 is usually fail, 20 success, but for % calc we clamp)
    neededRoll = neededRoll.clamp(1, 20);

    // Calculate raw probability (rolling equal to or higher than needed)
    double baseChance = (21 - neededRoll) / 20;

    // Adjust for advantage/disadvantage
    if (checkType == CheckType.advantage) {
      // Chance of failure with advantage is (failure_chance * failure_chance)
      double failChance = 1.0 - baseChance;
      baseChance = 1.0 - (failChance * failChance);
    } else if (checkType == CheckType.disadvantage) {
      // Chance of success with disadvantage is (success_chance * success_chance)
      baseChance = baseChance * baseChance;
    }

    return (baseChance * 100).clamp(0, 100);
  }
}

/// Type of ability check
enum CheckType {
  normal,
  advantage,
  disadvantage,
}

/// Represents the outcome of a choice
class Outcome {
  String description;
  List<OutcomeEffect> effects;

  Outcome({
    required this.description,
    required this.effects,
  });

  /// Apply all effects to the pet and return a detailed result message
  String apply(Pet pet, GameStateCallback? callback) {
    String resultMessage = description;

    for (var effect in effects) {
      switch (effect.type) {
        case OutcomeEffectType.statChange:
          if (effect.statName != null && effect.amount != null) {
            pet.modifyStat(effect.statName!, effect.amount!);
            resultMessage += '\n${effect.statName!.toUpperCase()} ${effect.amount! > 0 ? '+' : ''}${effect.amount}';
          }
          break;

        case OutcomeEffectType.healthChange:
          if (effect.amount != null) {
            if (effect.amount! < 0) {
              pet.takeDamage(effect.amount!.abs());
              resultMessage += '\nLost ${effect.amount!.abs()} HP';
            } else {
              pet.heal(effect.amount!);
              resultMessage += '\nHealed ${effect.amount} HP';
            }
          }
          break;

        case OutcomeEffectType.statusEffect:
          if (effect.statusEffect != null) {
            pet.addStatusEffect(effect.statusEffect!);
            resultMessage += '\nGained: ${effect.statusEffect!.name}';
          }
          break;

        case OutcomeEffectType.giveItem:
        // This will be handled by the game state manager callback
          if (callback != null && effect.itemId != null) {
            callback(effect);
            resultMessage += '\nReceived: ${effect.itemId}';
          }
          break;

        case OutcomeEffectType.skipFloors:
          if (callback != null && effect.amount != null) {
            callback(effect);
            resultMessage += '\nSkipped ${effect.amount} floors!';
          }
          break;

        case OutcomeEffectType.loseFloors:
          if (callback != null && effect.amount != null) {
            callback(effect);
            resultMessage += '\nSent back ${effect.amount} floors!';
          }
          break;

        case OutcomeEffectType.swapStats:
          if (effect.statName != null && effect.secondStatName != null) {
            pet.swapStats(effect.statName!, effect.secondStatName!);
            resultMessage += '\nSwapped ${effect.statName!.toUpperCase()} and ${effect.secondStatName!.toUpperCase()}!';
          }
          break;

        case OutcomeEffectType.maxHealthChange:
        // Indirectly change max health by modifying constitution if needed,
        // or direct max health modifier could be added to Pet class later.
        // For now, we reuse the constitution modifier logic or simple message.
          if (effect.amount != null) {
            // Assuming direct constitution mod for simplicity as per Pet class logic
            pet.modifyStat('constitution', effect.amount!);
            resultMessage += '\nMax HP ${effect.amount! > 0 ? 'increased' : 'decreased'}!';
          }
          break;
      }
    }

    return resultMessage;
  }
}

/// Callback type for game state changes
typedef GameStateCallback = void Function(OutcomeEffect effect);

/// Individual effect within an outcome
class OutcomeEffect {
  OutcomeEffectType type;
  String? statName;      // For stat changes
  String? secondStatName; // For stat swaps
  int? amount;           // For stat changes, health changes, floor skips
  StatusEffect? statusEffect; // For status effects
  String? itemId;        // For giving items

  OutcomeEffect({
    required this.type,
    this.statName,
    this.secondStatName,
    this.amount,
    this.statusEffect,
    this.itemId,
  });

  // Factory constructors for common effects
  factory OutcomeEffect.statChange(String statName, int amount) {
    return OutcomeEffect(
      type: OutcomeEffectType.statChange,
      statName: statName,
      amount: amount,
    );
  }

  factory OutcomeEffect.healthChange(int amount) {
    return OutcomeEffect(
      type: OutcomeEffectType.healthChange,
      amount: amount,
    );
  }

  factory OutcomeEffect.addStatus(StatusEffect effect) {
    return OutcomeEffect(
      type: OutcomeEffectType.statusEffect,
      statusEffect: effect,
    );
  }

  factory OutcomeEffect.giveItem(String itemId) {
    return OutcomeEffect(
      type: OutcomeEffectType.giveItem,
      itemId: itemId,
    );
  }

  factory OutcomeEffect.skipFloors(int floors) {
    return OutcomeEffect(
      type: OutcomeEffectType.skipFloors,
      amount: floors,
    );
  }

  factory OutcomeEffect.loseFloors(int floors) {
    return OutcomeEffect(
      type: OutcomeEffectType.loseFloors,
      amount: floors,
    );
  }

  factory OutcomeEffect.swapStats(String stat1, String stat2) {
    return OutcomeEffect(
      type: OutcomeEffectType.swapStats,
      statName: stat1,
      secondStatName: stat2,
    );
  }

  factory OutcomeEffect.maxHealthChange(int amount) {
    return OutcomeEffect(
      type: OutcomeEffectType.maxHealthChange,
      amount: amount,
    );
  }
}

/// Types of outcome effects
enum OutcomeEffectType {
  statChange,       // Modify a stat permanently for this run
  healthChange,     // Heal or damage
  statusEffect,     // Apply buff/debuff
  giveItem,         // Give consumable item
  skipFloors,       // Skip forward
  loseFloors,       // Go backwards
  swapStats,        // Swap two stats
  maxHealthChange,  // Increase/decrease max HP
}