🏰 Pocket Crawler

Pocket Crawler is a hybrid mobile game that combines Tamagotchi-style Pet Simulation with a Text-Based D&D Dungeon Crawler.

This repository focuses on the Dungeon Crawler "Arcade Mode" module of the application.

📖 About the Project

While one part of the app focuses on caring for and customizing a pet, the core gameplay loop involves taking that pet into a dungeon, navigating random text-based scenarios, and surviving as long as possible. The game relies heavily on Dungeons & Dragons 5e mechanics, utilizing Ability Scores and D20 rolls to resolve non-combat encounters.

🎮 Core Concepts

Genre: Text Adventure / Simulation / Roguelite (Arcade)

Theme: D&D Fantasy

Goal: Survive 100 floors (or Infinite Mode)

Combat: None. All conflict is resolved via narrative choices and stat checks.

Progression: Arcade-style. Stats reset after every run (Roguelite). High scores are based on floors reached.

🐾 The Pet System

The Pet is the central character passed between the Simulation mode and the Dungeon mode. Instead of a complex skill tree, we use the 6 core D&D attributes:

Stat

Description

STR

Strength

DEX

Dexterity

INT

Intelligence

WIS

Wisdom

CHA

Charisma

CON

Constitution (Determines Max Health, not used for checks)

Start of Run

When entering the dungeon, the player "Rolls for Stats" (distributing points or random rolls) to determine the baseline for that specific run.

🏰 Dungeon Mechanics

The Gameplay Loop

Enter Floor: A Scenario is generated based on rarity weights.

Scenario: Text describes the situation (e.g., "A goblin merchant blocks the path").

Choice: Player selects 1 of 3 options, each tied to a specific Stat.

The Roll: (D20 + Stat Modifier) vs Difficulty Class (DC)

Outcome: Success or Failure triggers consequences.

Next Floor: If Health > 0, proceed.

Rarity System

Common (70%): Standard interactions.

Uncommon (20%): Harder checks, better rewards.

Rare (10%): Unique events, massive risks/rewards.

Consequences & Rewards

Stat Mods: Trade-offs (e.g., +2 STR / -1 INT).

Health: Damage or rare healing.

Items: Temporary consumables (e.g., Potion of Bull's Strength).

Floor Skips: Jump forward 5-10 floors (Reward) or fall back (Punishment).

Conditions: Temporary Advantage (Blessed) or Disadvantage (Cursed) on rolls.

📂 Project Structure

lib/
├── models/
│   └── pet_model.dart       # Core Pet logic (Stats, Health, Status Effects)
├── dungeon/
│   ├── game_state.dart      # Manages the run (Floors, Inventory, History)
│   ├── scenario.dart        # Data classes for Scenario, Choice, Outcome
│   ├── scenario_data.dart   # Hardcoded library of game scenarios
│   ├── item.dart            # Item data classes and logic
│   └── dice_roller.dart     # RNG utility (D20, Advantage/Disadvantage)


🗺️ Roadmap & Progress

[x] Phase 1: The Engine

[x] Create Pet class with stats

[x] Implement D20 RNG Logic (DiceRoller)

[ ] Basic UI for stat display

[x] Phase 2: The Content

[x] Create Scenario and Choice classes

[x] Implement initial library of Scenarios (ScenarioLibrary)

[x] Implement Rarity weighting logic

[x] Phase 3: The Loop

[x] Floor counter implementation (GameState)

[x] Health tracking & Game Over state

[x] Stat Modification logic (Success/Fail outcomes)

[x] Phase 4: Advanced Mechanics

[x] Inventory & Item usage

[x] Advantage/Disadvantage system

[x] Floor Skipping/Backtracking

🛠️ Technical Architecture

Built using Flutter and Dart.

Key Classes:

Pet: Stores stats, health, inventory, and active conditions.

Scenario: Holds description, rarity, and list of Choices.

Choice: Connects UI button text to specific Stats and DCs.

Outcome: Handles the logic for result application (stat changes, damage, etc.).

GameState: Manages the current run (Floor count, active pet, history).

This project is currently in active development.
