import 'dart:math';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

import '../pet.dart';
import 'dice_roller.dart';

part 'scenario.g.dart';

// ==============================================================================
// HELPERS
// ==============================================================================

class ColorSerialiser implements JsonConverter<Color, int> {
  const ColorSerialiser();
  @override
  Color fromJson(int json) => Color(json);
  @override
  int toJson(Color object) => object.value;
}

class PetController extends ChangeNotifier {
  Color flashColor = Colors.transparent;
  String effects = "";

  void triggerEffect(Color color, String debuff) {
    flashColor = color;
    effects = debuff;
    notifyListeners();
  }

  void triggerShake() {
    flashColor = Colors.white10;
    effects = "";
    notifyListeners();
  }

  void triggerDamage() {
    flashColor = Colors.red;
    effects = "";
    notifyListeners();
  }

  void triggerHeal() {
    flashColor = Colors.green;
    effects = "";
    notifyListeners();
  }

  void triggerStatBoost() {
    flashColor = Colors.blue;
    effects = "";
    notifyListeners();
  }
}

// ==============================================================================
// SCENARIO
// ==============================================================================

@JsonSerializable(explicitToJson: true)
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

  factory Scenario.fromJson(Map<String, dynamic> json) => _$ScenarioFromJson(json);
  Map<String, dynamic> toJson() => _$ScenarioToJson(this);

  static Scenario selectRandomScenario(List<Scenario> scenarios) {
    if (scenarios.isEmpty) throw ArgumentError('Cannot select from empty scenario list');
    String rarityRoll = DiceRoller.rollRarity();
    ScenarioRarity targetRarity = _rarityFromString(rarityRoll);
    final availableScenarios = scenarios.where((s) => s.rarity == targetRarity).toList();
    if (availableScenarios.isEmpty) availableScenarios.addAll(scenarios);
    return availableScenarios[Random().nextInt(availableScenarios.length)];
  }

  static ScenarioRarity _rarityFromString(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'uncommon': return ScenarioRarity.uncommon;
      case 'rare': return ScenarioRarity.rare;
      default: return ScenarioRarity.common;
    }
  }
}

enum ScenarioRarity { common, uncommon, rare }

// ==============================================================================
// CHOICE
// ==============================================================================

@JsonSerializable(explicitToJson: true)
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

  factory Choice.fromJson(Map<String, dynamic> json) => _$ChoiceFromJson(json);
  Map<String, dynamic> toJson() => _$ChoiceToJson(this);

  double getSuccessChance(Pet pet, {bool hasAdvantage = false, bool hasDisadvantage = false}) {
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

enum CheckType { normal, advantage, disadvantage }

// ==============================================================================
// OUTCOME
// ==============================================================================

@JsonSerializable(explicitToJson: true)
class Outcome {
  final String description;
  final List<OutcomeEffect> effects;

  const Outcome({required this.description, required this.effects});

  factory Outcome.fromJson(Map<String, dynamic> json) => _$OutcomeFromJson(json);
  Map<String, dynamic> toJson() => _$OutcomeToJson(this);

  String apply(Pet pet, GameStateCallback? callback, PetController? controller) {
    StringBuffer resultMessage = StringBuffer(description);
    for (var effect in effects) {
      String effectMessage = _applyEffect(effect, pet, callback, controller);
      if (effectMessage.isNotEmpty) resultMessage.write('\n$effectMessage');
    }
    return resultMessage.toString();
  }

  String _applyEffect(OutcomeEffect effect, Pet pet, GameStateCallback? callback, PetController? controller) {
    switch (effect.type) {
      case OutcomeEffectType.statChange:
        if (effect.statName != null && effect.amount != null) {
          pet.modifyStat(effect.statName!, effect.amount!);
          return '${effect.statName!.toUpperCase()} ${effect.amount! > 0 ? '+' : ''}${effect.amount}';
        }
        return '';
      case OutcomeEffectType.healthChange:
        if (effect.amount != null) {
          if (effect.amount! < 0) {
            pet.takeDamage(effect.amount!.abs());
            controller?.triggerDamage();
            return 'Lost ${effect.amount!.abs()} HP';
          } else {
            pet.heal(effect.amount!);
            controller?.triggerHeal();
            return 'Healed ${effect.amount} HP';
          }
        }
        return '';
      case OutcomeEffectType.statusEffect:
        if (effect.statusEffect != null) {
          pet.addStatusEffect(effect.statusEffect!);
          controller?.triggerEffect(effect.statusEffect!.color, effect.statusEffect!.name);
          return 'Gained: ${effect.statusEffect!.name}';
        }
        return '';
      case OutcomeEffectType.giveItem:
        if (callback != null && effect.itemId != null) {
          callback(effect);
          return 'Received: ${effect.itemId}';
        }
        return '';
      case OutcomeEffectType.skipFloors:
        if (callback != null && effect.amount != null) {
          controller?.triggerShake();
          callback(effect);
          return 'Skipped ${effect.amount} floors!';
        }
        return '';
      case OutcomeEffectType.loseFloors:
        if (callback != null && effect.amount != null) {
          controller?.triggerShake();
          callback(effect);
          return 'Sent back ${effect.amount} floors!';
        }
        return '';
      case OutcomeEffectType.swapStats:
        if (effect.statName != null && effect.secondStatName != null) {
          controller?.triggerStatBoost();
          pet.swapStats(effect.statName!, effect.secondStatName!);
          return 'Swapped ${effect.statName!.toUpperCase()} and ${effect.secondStatName!.toUpperCase()}!';
        }
        return '';
      case OutcomeEffectType.maxHealthChange:
        if (effect.amount != null) {
          effect.amount! > 0 ? controller?.triggerHeal() : controller?.triggerDamage();
          pet.modifyStat('constitution', effect.amount!);
          return 'Max HP ${effect.amount! > 0 ? 'increased' : 'decreased'}!';
        }
        return '';
    }
  }
}

typedef GameStateCallback = void Function(OutcomeEffect effect);

// ==============================================================================
// OUTCOME EFFECT
// ==============================================================================

@JsonSerializable(explicitToJson: true)
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

  factory OutcomeEffect.fromJson(Map<String, dynamic> json) => _$OutcomeEffectFromJson(json);
  Map<String, dynamic> toJson() => _$OutcomeEffectToJson(this);
}

enum OutcomeEffectType { statChange, healthChange, statusEffect, giveItem, skipFloors, loseFloors, swapStats, maxHealthChange }

// ==============================================================================
// STATUS EFFECT (THE SINGLE TRUTH)
// ==============================================================================

@JsonSerializable()
class StatusEffect {
  final String name;
  final StatusEffectType type;
  @ColorSerialiser()
  final Color color;

  // These are not final because we might change them in copyWith
  final int duration;
  final String description;
  final bool canStack;
  final Map<String, int>? statModifiers;

  const StatusEffect({
    required this.name,
    required this.type,
    required this.color,
    required this.duration,
    required this.description,
    this.canStack = false,
    this.statModifiers,
  });

  factory StatusEffect.fromJson(Map<String, dynamic> json) => _$StatusEffectFromJson(json);
  Map<String, dynamic> toJson() => _$StatusEffectToJson(this);

  /// Creates a copy of this effect with modified properties
  StatusEffect copyWith({int? duration}) {
    return StatusEffect(
      name: name,
      type: type,
      color: color,
      duration: duration ?? this.duration,
      description: description,
      canStack: canStack,
      statModifiers: statModifiers,
    );
  }
}

enum StatusEffectType { cursed, statPenalty, statBoost, blessed, advantage, disadvantage }