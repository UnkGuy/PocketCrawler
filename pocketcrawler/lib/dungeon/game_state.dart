import 'dart:math';
import '../pet.dart';
import 'dice_roller.dart';
import 'scenario.dart';
import 'item.dart';

/// Manages the state of a dungeon run
class GameState {
  final Pet pet;
  final int maxFloor;
  final bool isInfiniteMode;

  int currentFloor;

  // Inventory & Items
  final List<Item> inventory;
  final List<ActiveItemEffect> activeItemEffects;

  // Scenario Management
  Scenario? currentScenario;
  final List<String> completedScenarioIds;

  // Oracle/Prediction
  bool oracleActive;
  int oracleRemainingFloors;

  // Run History & Statistics
  final List<String> eventHistory;
  final Map<String, int> statsSnapshot;
  int floorsSkipped;
  int floorsLost;
  int itemsFound;
  int choicesMade;

  GameState({
    required this.pet,
    this.currentFloor = 1,
    this.maxFloor = 100,
    this.isInfiniteMode = false,
  })  : inventory = [],
        activeItemEffects = [],
        completedScenarioIds = [],
        eventHistory = [],
        statsSnapshot = {},
        oracleActive = false,
        oracleRemainingFloors = 0,
        floorsSkipped = 0,
        floorsLost = 0,
        itemsFound = 0,
        choicesMade = 0 {
    _takeStatsSnapshot();
  }

  // ============================================================================
  // FLOOR PROGRESSION
  // ============================================================================

  /// Advance to the next floor(s)
  void advanceFloor({int floors = 1}) {
    currentFloor += floors;

    // Track skipped floors
    if (floors > 1) {
      floorsSkipped += floors - 1;
    }

    // Update all duration-based effects
    _updateDurationEffects();
  }

  /// Go back floors (from negative events)
  void retreatFloors(int floors) {
    int actualFloors = min(floors, currentFloor - 1);
    currentFloor -= actualFloors;
    floorsLost += actualFloors;
  }

  /// Update all duration-based effects (pet effects, items, oracle)
  void _updateDurationEffects() {
    // Pet status effects
    pet.decrementEffectDurations();

    // Active item effects
    for (var effect in activeItemEffects) {
      effect.tick();
      if (effect.isExpired) {
        effect.onExpire(pet);
      }
    }
    activeItemEffects.removeWhere((effect) => effect.isExpired);

    // Oracle duration
    if (oracleActive) {
      oracleRemainingFloors--;
      if (oracleRemainingFloors <= 0) {
        oracleActive = false;
      }
    }
  }

  // ============================================================================
  // SCENARIO MANAGEMENT
  // ============================================================================

  /// Set the current scenario for this floor
  void setCurrentScenario(Scenario scenario) {
    currentScenario = scenario;
  }

  /// Complete the current scenario and mark it as done
  void completeScenario() {
    if (currentScenario != null) {
      completedScenarioIds.add(currentScenario!.id);
    }
    currentScenario = null;
  }

  /// Make a choice in the current scenario
  ChoiceResult makeChoice(Choice choice) {
    choicesMade++;

    // Perform ability check
    final checkResult = DiceRoller.abilityCheck(
      dc: choice.difficultyClass,
      modifier: pet.getStatModifier(choice.statRequired),
      advantage: choice.checkType == CheckType.advantage ||
          pet.hasEffect(StatusEffectType.advantage),
      disadvantage: choice.checkType == CheckType.disadvantage ||
          pet.hasEffect(StatusEffectType.disadvantage),
    );

    // Apply outcome
    Outcome outcome = checkResult.success
        ? choice.successOutcome
        : choice.failureOutcome;

    String outcomeMessage = outcome.apply(pet, _handleOutcomeCallback);

    // Log to history
    _logChoice(choice, checkResult);

    return ChoiceResult(
      success: checkResult.success,
      roll: checkResult.roll,
      modifier: checkResult.modifier,
      total: checkResult.total,
      dc: checkResult.dc,
      outcomeMessage: outcomeMessage,
      isCritical: checkResult.isCriticalSuccess || checkResult.isCriticalFailure,
    );
  }

  /// Log a choice to event history
  void _logChoice(Choice choice, AbilityCheckResult checkResult) {
    String advantageText = checkResult.advantage
        ? ' (Advantage)'
        : checkResult.disadvantage
        ? ' (Disadvantage)'
        : '';

    eventHistory.add(
        'Floor $currentFloor: ${choice.statRequired.toUpperCase()} check$advantageText - '
            'Rolled ${checkResult.roll} + ${checkResult.modifier} = ${checkResult.total} '
            'vs DC ${checkResult.dc} - ${checkResult.resultType}'
    );
  }

  // ============================================================================
  // INVENTORY & ITEM MANAGEMENT
  // ============================================================================

  /// Add an item to inventory
  void addItem(Item item) {
    inventory.add(item);
    itemsFound++;
    eventHistory.add('Floor $currentFloor: Found ${item.name}');
  }

  /// Use an item from inventory by index
  ItemUseResult? useItem(int inventoryIndex) {
    if (inventoryIndex < 0 || inventoryIndex >= inventory.length) {
      return null;
    }

    Item item = inventory[inventoryIndex];
    ItemUseResult result = item.use(pet);

    // Remove from inventory
    inventory.removeAt(inventoryIndex);

    // Track duration-based effects
    if (item.duration > 0) {
      activeItemEffects.add(ActiveItemEffect(
        item: item,
        remainingDuration: item.duration,
      ));
    }

    // Activate oracle
    if (item.type == ItemType.oracle) {
      oracleActive = true;
      oracleRemainingFloors = item.duration;
    }

    eventHistory.add('Floor $currentFloor: Used ${item.name}');
    return result;
  }

  // ============================================================================
  // OUTCOME CALLBACK (For special effects)
  // ============================================================================

  /// Handle special outcome effects that affect GameState
  void _handleOutcomeCallback(OutcomeEffect effect) {
    switch (effect.type) {
      case OutcomeEffectType.giveItem:
        if (effect.itemId != null) {
          Item? item = ItemLibrary.getItem(effect.itemId!);
          if (item != null) {
            addItem(item);
          }
        }
        break;

      case OutcomeEffectType.skipFloors:
        if (effect.amount != null) {
          currentFloor += effect.amount!;
          floorsSkipped += effect.amount!;
        }
        break;

      case OutcomeEffectType.loseFloors:
        if (effect.amount != null) {
          retreatFloors(effect.amount!);
        }
        break;

      default:
        break;
    }
  }

  // ============================================================================
  // STATS & SUMMARY
  // ============================================================================

  /// Take a snapshot of pet's starting stats
  void _takeStatsSnapshot() {
    statsSnapshot.addAll({
      'strength': pet.strength,
      'dexterity': pet.dexterity,
      'constitution': pet.constitution,
      'intelligence': pet.intelligence,
      'wisdom': pet.wisdom,
      'charisma': pet.charisma,
      'maxHealth': pet.maxHealth,
    });
  }

  /// Get stat changes since the start of the run
  Map<String, int> getStatChanges() {
    return {
      'strength': pet.strength - (statsSnapshot['strength'] ?? pet.strength),
      'dexterity': pet.dexterity - (statsSnapshot['dexterity'] ?? pet.dexterity),
      'constitution': pet.constitution - (statsSnapshot['constitution'] ?? pet.constitution),
      'intelligence': pet.intelligence - (statsSnapshot['intelligence'] ?? pet.intelligence),
      'wisdom': pet.wisdom - (statsSnapshot['wisdom'] ?? pet.wisdom),
      'charisma': pet.charisma - (statsSnapshot['charisma'] ?? pet.charisma),
    };
  }

  /// Generate run summary
  RunSummary getSummary() {
    return RunSummary(
      floorsReached: currentFloor - 1,
      isDungeonCleared: isDungeonCleared,
      startingStats: Map.from(statsSnapshot),
      finalStats: {
        'strength': pet.strength,
        'dexterity': pet.dexterity,
        'constitution': pet.constitution,
        'intelligence': pet.intelligence,
        'wisdom': pet.wisdom,
        'charisma': pet.charisma,
        'currentHealth': pet.currentHealth,
        'maxHealth': pet.maxHealth,
      },
      statChanges: getStatChanges(),
      floorsSkipped: floorsSkipped,
      floorsLost: floorsLost,
      itemsFound: itemsFound,
      choicesMade: choicesMade,
      eventHistory: List.from(eventHistory),
    );
  }

  // ============================================================================
  // STATE CHECKS
  // ============================================================================

  /// Check if the run is complete
  bool get isRunComplete => isPetDead || (currentFloor > maxFloor && !isInfiniteMode);

  /// Check if pet died
  bool get isPetDead => !pet.isAlive;

  /// Check if dungeon was cleared successfully
  bool get isDungeonCleared => pet.isAlive && currentFloor > maxFloor && !isInfiniteMode;

  @override
  String toString() {
    return '''
Floor: $currentFloor${isInfiniteMode ? ' (Infinite)' : '/$maxFloor'}
Pet: ${pet.name} (${pet.currentHealth}/${pet.maxHealth} HP)
Scenario: ${currentScenario?.title ?? 'None'}
Inventory: ${inventory.length} items
Active Effects: ${activeItemEffects.length}
Oracle: ${oracleActive ? 'Active ($oracleRemainingFloors floors)' : 'Inactive'}
    ''';
  }
}

// ==============================================================================
// CHOICE RESULT
// ==============================================================================

/// Result of making a choice in a scenario
class ChoiceResult {
  final bool success;
  final int roll;
  final int modifier;
  final int total;
  final int dc;
  final String outcomeMessage;
  final bool isCritical;

  const ChoiceResult({
    required this.success,
    required this.roll,
    required this.modifier,
    required this.total,
    required this.dc,
    required this.outcomeMessage,
    this.isCritical = false,
  });

  String get resultType {
    if (isCritical) {
      return roll == 20 ? 'CRITICAL SUCCESS' : 'CRITICAL FAILURE';
    }
    return success ? 'SUCCESS' : 'FAILURE';
  }

  @override
  String toString() {
    return '''
$resultType!
Roll: $roll + $modifier = $total (DC $dc)
$outcomeMessage
    ''';
  }
}

// ==============================================================================
// RUN SUMMARY
// ==============================================================================

/// Summary of a completed dungeon run
class RunSummary {
  final int floorsReached;
  final bool isDungeonCleared;
  final Map<String, int> startingStats;
  final Map<String, int> finalStats;
  final Map<String, int> statChanges;
  final int floorsSkipped;
  final int floorsLost;
  final int itemsFound;
  final int choicesMade;
  final List<String> eventHistory;

  const RunSummary({
    required this.floorsReached,
    required this.isDungeonCleared,
    required this.startingStats,
    required this.finalStats,
    required this.statChanges,
    required this.floorsSkipped,
    required this.floorsLost,
    required this.itemsFound,
    required this.choicesMade,
    required this.eventHistory,
  });

  @override
  String toString() {
    String result = isDungeonCleared ? 'DUNGEON CLEARED!' : 'Run Ended';
    String statChangesStr = statChanges.entries
        .map((e) => '${e.key.toUpperCase()}: ${e.value > 0 ? '+' : ''}${e.value}')
        .join('\n');

    return '''
=== RUN SUMMARY ===
$result
Floors Reached: $floorsReached
Choices Made: $choicesMade
Items Found: $itemsFound
Floors Skipped: $floorsSkipped
Floors Lost: $floorsLost

=== STAT CHANGES ===
$statChangesStr
    ''';
  }
}