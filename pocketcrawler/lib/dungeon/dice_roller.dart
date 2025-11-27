import 'dart:math';

/// Utility class for rolling dice with DND mechanics
class DiceRoller {
  static final Random _random = Random();

  /// Roll a single d20
  static int rollD20() {
    return _random.nextInt(20) + 1;
  }

  /// Roll with advantage (roll twice, take higher)
  static int rollWithAdvantage() {
    int roll1 = rollD20();
    int roll2 = rollD20();
    return max(roll1, roll2);
  }

  /// Roll with disadvantage (roll twice, take lower)
  static int rollWithDisadvantage() {
    int roll1 = rollD20();
    int roll2 = rollD20();
    return min(roll1, roll2);
  }

  /// Roll for ability check
  /// Returns the total (roll + modifier) and whether it succeeded
  static AbilityCheckResult abilityCheck({
    required int dc,
    required int modifier,
    bool advantage = false,
    bool disadvantage = false,
  }) {
    int roll;

    // Advantage cancels out Disadvantage
    if (advantage && !disadvantage) {
      roll = rollWithAdvantage();
    } else if (disadvantage && !advantage) {
      roll = rollWithDisadvantage();
    } else {
      roll = rollD20();
    }

    int total = roll + modifier;
    bool success = total >= dc;

    return AbilityCheckResult(
      roll: roll,
      modifier: modifier,
      total: total,
      dc: dc,
      success: success,
      advantage: advantage && !disadvantage,
      disadvantage: disadvantage && !advantage,
    );
  }

  /// Roll multiple dice (e.g., 2d6, 3d8)
  static int rollDice(int numberOfDice, int diceSides) {
    int total = 0;
    for (int i = 0; i < numberOfDice; i++) {
      total += _random.nextInt(diceSides) + 1;
    }
    return total;
  }

  /// Roll for stat generation (4d6 drop lowest)
  static int rollStat() {
    List<int> rolls = List.generate(4, (_) => _random.nextInt(6) + 1);
    rolls.sort();
    // Drop the lowest (index 0), sum the rest
    return rolls[1] + rolls[2] + rolls[3];
  }

  /// Generate a full set of 6 stats using 4d6 drop lowest
  static List<int> rollStatArray() {
    return List.generate(6, (_) => rollStat());
  }

  /// Calculate percentage success chance for a given DC and modifier
  static double calculateSuccessChance({
    required int dc,
    required int modifier,
    bool advantage = false,
    bool disadvantage = false,
  }) {
    // Determine the raw die roll needed (e.g. if DC is 15 and mod is +2, need 13)
    int neededRoll = (dc - modifier).clamp(1, 20);

    // Base probability (rolling >= neededRoll)
    // 21 because there are 20 outcomes. If needed is 1, (21-1)/20 = 100%.
    double baseChance = (21 - neededRoll) / 20.0;

    if (advantage) {
      // With advantage: 1 - (chance of BOTH failing)
      // Chance to fail = 1.0 - baseChance
      double failChance = 1.0 - baseChance;
      return (1.0 - (failChance * failChance)) * 100;
    } else if (disadvantage) {
      // With disadvantage: Chance both succeed
      return (baseChance * baseChance) * 100;
    }

    return baseChance * 100;
  }

  /// Get a random weighted outcome based on common (70%), uncommon (20%), rare (10%)
  static String rollRarity() {
    int roll = _random.nextInt(100);
    if (roll < 70) return 'common';
    if (roll < 90) return 'uncommon';
    return 'rare';
  }

  /// Roll for a random outcome with custom weights
  /// Returns the index of the chosen weight
  static int rollWeighted(List<int> weights) {
    int total = weights.fold(0, (a, b) => a + b);
    int roll = _random.nextInt(total);

    int cumulative = 0;
    for (int i = 0; i < weights.length; i++) {
      cumulative += weights[i];
      if (roll < cumulative) {
        return i;
      }
    }
    return weights.length - 1;
  }

  /// Check for critical success (natural 20)
  static bool isCriticalSuccess(int roll) => roll == 20;

  /// Check for critical failure (natural 1)
  static bool isCriticalFailure(int roll) => roll == 1;

  /// Get modifier from stat value (DND style)
  static int getModifier(int statValue) {
    return ((statValue - 10) / 2).floor();
  }
}

/// Result of an ability check (Immutable)
class AbilityCheckResult {
  final int roll;
  final int modifier;
  final int total;
  final int dc;
  final bool success;
  final bool advantage;
  final bool disadvantage;

  const AbilityCheckResult({
    required this.roll,
    required this.modifier,
    required this.total,
    required this.dc,
    required this.success,
    this.advantage = false,
    this.disadvantage = false,
  });

  bool get isCriticalSuccess => roll == 20;
  bool get isCriticalFailure => roll == 1;

  String get resultType {
    if (isCriticalSuccess) return 'CRITICAL SUCCESS';
    if (isCriticalFailure) return 'CRITICAL FAILURE';
    return success ? 'SUCCESS' : 'FAILURE';
  }

  @override
  String toString() {
    String advantageText = advantage ? ' (Advantage)' : disadvantage ? ' (Disadvantage)' : '';
    return '$resultType$advantageText\nRoll: $roll + $modifier = $total vs DC $dc';
  }
}