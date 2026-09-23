# Pocket Crawler

Pocket Crawler is a hybrid mobile game that combines **Tamagotchi-style Pet Simulation** with a **Text-Based D&D Dungeon Crawler**.

This repository focuses on the **Dungeon Crawler "Arcade Mode"** module of the application.

---

# About the Project

While one part of the app focuses on caring for and customizing a pet, the core gameplay loop involves taking that pet into a dungeon, navigating random text-based scenarios, and surviving as long as possible.

The game relies heavily on **Dungeons & Dragons 5e** mechanics, utilizing **Ability Scores** and **D20 rolls** to resolve non-combat encounters.

---

# Core Concepts

- **Genre:** Text Adventure / Simulation / Roguelite (Arcade)
- **Theme:** D&D Fantasy
- **Goal:** Survive 100 floors (or play Infinite Mode)
- **Combat:** None. All conflict is resolved via narrative choices and stat checks.
- **Progression:** Arcade-style. Stats reset after every run (Roguelite). High scores are based on floors reached.

---

# The Pet System

The Pet is the central character passed between the Simulation mode and the Dungeon mode.

Instead of a complex skill tree, the game uses the six core D&D attributes:

| Stat | Description |
|--------|-------------|
| STR | Strength |
| DEX | Dexterity |
| INT | Intelligence |
| WIS | Wisdom |
| CHA | Charisma |
| CON | Constitution (Determines Max Health, not used for checks) |

## Start of a Run

When entering the dungeon, the player **rolls for stats** (via random rolls or point distribution) to determine the baseline attributes for that specific run.

---

# Dungeon Mechanics

## Gameplay Loop

1. **Enter Floor**  
   A scenario is generated based on rarity weights.

2. **Scenario Appears**  
   Text describes the situation.  
   Example: *"A goblin merchant blocks the path."*

3. **Make a Choice**  
   Select one of three options, each tied to a specific stat.

4. **Roll the Dice**  
   `(D20 + Stat Modifier)` vs. **Difficulty Class (DC)**

5. **Resolve Outcome**  
   Success or failure triggers consequences.

6. **Continue**  
   If Health > 0, proceed to the next floor.

---

## Rarity System

| Rarity | Chance | Description |
|---------|---------|-------------|
| Common | 70% | Standard interactions |
| Uncommon | 20% | Harder checks, better rewards |
| Rare | 10% | Unique events with major risks/rewards |

---

## Consequences & Rewards

### Stat Modifiers
Trade-offs such as:

- `+2 STR / -1 INT`
- `+1 CHA / -1 WIS`

### Health

- Damage from failed encounters
- Rare healing opportunities

### Items

Temporary consumables, such as:

- Potion of Bull's Strength
- Healing Potion
- Lucky Charm

### Floor Movement

- Skip forward 5-10 floors (Reward)
- Fall back several floors (Punishment)

### Conditions

Temporary roll modifiers such as:

- **Blessed** (Advantage)
- **Cursed** (Disadvantage)

---

# Project Structure

```text
lib/
├── models/
│   └── pet_model.dart       # Core Pet logic (Stats, Health, Status Effects)
├── dungeon/
│   ├── game_state.dart      # Manages runs (Floors, Inventory, History)
│   ├── scenario.dart        # Scenario, Choice, and Outcome models
│   ├── scenario_data.dart   # Scenario library
│   ├── item.dart            # Item definitions and logic
│   └── dice_roller.dart     # D20 RNG utility (Advantage/Disadvantage)
```

---

# Roadmap & Progress

## ✅ Phase 1: The Engine

- [x] Create Pet class with stats
- [x] Implement D20 RNG logic (`DiceRoller`)
- [ ] Basic UI for stat display

## ✅ Phase 2: The Content

- [x] Create Scenario and Choice classes
- [x] Implement initial scenario library (`ScenarioLibrary`)
- [x] Implement rarity weighting logic

## ✅ Phase 3: The Loop

- [x] Floor counter implementation (`GameState`)
- [x] Health tracking and Game Over state
- [x] Stat modification logic (success/failure outcomes)

## ✅ Phase 4: Advanced Mechanics

- [x] Inventory and item usage
- [x] Advantage/Disadvantage system
- [x] Floor skipping and backtracking

---

# Technical Architecture

Built using **Flutter** and **Dart**.

## Key Classes

### `Pet`
Stores:

- Stats
- Health
- Inventory
- Active conditions

### `Scenario`
Contains:

- Description
- Rarity
- Available choices

### `Choice`
Connects UI button text to specific stat checks and DC values.

### `Outcome`
Applies gameplay results such as:

- Stat changes
- Damage
- Healing
- Item rewards

### `GameState`
Manages the current run:

- Floor count
- Active pet
- Inventory
- Run history

---
