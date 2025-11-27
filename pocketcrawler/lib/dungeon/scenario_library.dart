import '../pet.dart';
import 'scenario.dart';

class ScenarioLibrary {
  static List<Scenario> getAllScenarios() {
    return [
      goblinMerchant,
      ancientStatue,
      mysteriousChest,
      crumblingBridge,
      strangeMushroomCircle,
      wanderingBard,
    ];
  }

  // --- COMMON SCENARIOS (70% Chance) ---

  static final Scenario goblinMerchant = Scenario(
    id: 'goblin_merchant_01',
    title: 'Goblin Merchant',
    description: 'A hunched goblin with a cart full of strange wares blocks your path. '
        'His beady eyes gleam as he notices you. "Toll! Toll to pass!" he squeaks.',
    rarity: ScenarioRarity.common,
    choices: [
      Choice(
        text: 'Intimidate him into letting you pass [STR]',
        statRequired: 'strength',
        difficultyClass: 12,
        successOutcome: Outcome(
          description: 'You flex menacingly. The goblin whimpers and scurries aside.',
          effects: [
            OutcomeEffect.statChange('strength', 2),
            OutcomeEffect.statChange('charisma', -1),
          ],
        ),
        failureOutcome: Outcome(
          description: 'The goblin laughs at your attempt. He demands payment in blood!',
          effects: [
            OutcomeEffect.healthChange(-2),
            OutcomeEffect.statChange('strength', -1),
          ],
        ),
      ),
      Choice(
        text: 'Bargain for safe passage [CHA]',
        statRequired: 'charisma',
        difficultyClass: 10,
        successOutcome: Outcome(
          description: 'You sweet-talk the merchant. He grins and tosses you a potion as you pass.',
          effects: [
            OutcomeEffect.giveItem('minor_healing'),
            OutcomeEffect.statChange('charisma', 2),
          ],
        ),
        failureOutcome: Outcome(
          description: 'The goblin sees through your charm and picks your pocket!',
          effects: [
            OutcomeEffect.statChange('charisma', -2),
            OutcomeEffect.statChange('dexterity', -1),
          ],
        ),
      ),
      Choice(
        text: 'Sneak past while he\'s distracted [DEX]',
        statRequired: 'dexterity',
        difficultyClass: 13,
        successOutcome: Outcome(
          description: 'You slip by unnoticed, even snagging a trinket from his cart!',
          effects: [
            OutcomeEffect.statChange('dexterity', 2),
            OutcomeEffect.giveItem('lucky_charm'),
          ],
        ),
        failureOutcome: Outcome(
          description: 'You trip over a loose stone! The goblin clubs you.',
          effects: [
            OutcomeEffect.healthChange(-3),
            OutcomeEffect.statChange('dexterity', -2),
          ],
        ),
      ),
    ],
  );

  static final Scenario ancientStatue = Scenario(
    id: 'ancient_statue_01',
    title: 'Ancient Statue',
    description: 'A weathered stone statue depicts a robed figure with arms outstretched. '
        'Runes glow faintly on its base, and you sense latent magic.',
    rarity: ScenarioRarity.common,
    choices: [
      Choice(
        text: 'Decipher the runes [INT]',
        statRequired: 'intelligence',
        difficultyClass: 14,
        successOutcome: Outcome(
          description: 'The runes reveal an ancient blessing! Knowledge floods your mind.',
          effects: [
            OutcomeEffect.statChange('intelligence', 3),
            OutcomeEffect.statChange('wisdom', 1),
          ],
        ),
        failureOutcome: Outcome(
          description: 'The runes burn your mind with incomprehensible visions.',
          effects: [
            OutcomeEffect.statChange('intelligence', -2),
            OutcomeEffect.healthChange(-1),
          ],
        ),
      ),
      Choice(
        text: 'Pray at the statue [WIS]',
        statRequired: 'wisdom',
        difficultyClass: 11,
        successOutcome: Outcome(
          description: 'A warm light envelops you. You feel rejuvenated and wiser.',
          effects: [
            OutcomeEffect.healthChange(3),
            OutcomeEffect.statChange('wisdom', 2),
          ],
        ),
        failureOutcome: Outcome(
          description: 'Your prayer echoes unanswered. You feel foolish.',
          effects: [
            OutcomeEffect.statChange('wisdom', -1),
            OutcomeEffect.statChange('charisma', -1),
          ],
        ),
      ),
      Choice(
        text: 'Smash the statue for treasure [STR]',
        statRequired: 'strength',
        difficultyClass: 15,
        successOutcome: Outcome(
          description: 'The statue crumbles, revealing a hidden cache of potions!',
          effects: [
            OutcomeEffect.giveItem('healing_potion'),
            OutcomeEffect.statChange('strength', 1),
          ],
        ),
        failureOutcome: Outcome(
          description: 'The statue releases a curse as it cracks! You feel weakened.',
          effects: [
            OutcomeEffect.statChange('strength', -3),
            OutcomeEffect.addStatus(StatusEffect(
              name: 'Statue\'s Curse',
              type: StatusEffectType.cursed,
              duration: 3,
              description: 'Strength checks have disadvantage',
            )),
          ],
        ),
      ),
    ],
  );

  // --- UNCOMMON SCENARIOS (20% Chance) ---

  static final Scenario mysteriousChest = Scenario(
    id: 'mysterious_chest_01',
    title: 'Mysterious Chest',
    description: 'An ornate chest sits in the middle of the room, practically glowing with possibility. '
        'No traps are visible, but something feels... off.',
    rarity: ScenarioRarity.uncommon,
    choices: [
      Choice(
        text: 'Carefully inspect for traps [WIS]',
        statRequired: 'wisdom',
        difficultyClass: 15,
        successOutcome: Outcome(
          description: 'You spot a needle trap and disarm it! The chest contains rare elixirs.',
          effects: [
            OutcomeEffect.giveItem('elixir_of_strength'),
            OutcomeEffect.giveItem('draught_of_intellect'),
            OutcomeEffect.statChange('wisdom', 2),
          ],
        ),
        failureOutcome: Outcome(
          description: 'You miss the trap entirely. Poisoned darts strike you!',
          effects: [
            OutcomeEffect.healthChange(-4),
            OutcomeEffect.addStatus(StatusEffect(
              name: 'Poisoned',
              type: StatusEffectType.statPenalty,
              duration: 5,
              description: 'All stats reduced by 1',
              statModifiers: {
                'strength': -1,
                'dexterity': -1,
                'constitution': -1,
                'intelligence': -1,
                'wisdom': -1,
                'charisma': -1,
              },
            )),
          ],
        ),
      ),
      Choice(
        text: 'Force it open immediately [STR]',
        statRequired: 'strength',
        difficultyClass: 16,
        successOutcome: Outcome(
          description: 'You rip the chest open before any traps can trigger! Treasure!',
          effects: [
            OutcomeEffect.giveItem('greater_healing'),
            OutcomeEffect.statChange('strength', 3),
            OutcomeEffect.skipFloors(3),
          ],
        ),
        failureOutcome: Outcome(
          description: 'The chest explodes in your face!',
          effects: [
            OutcomeEffect.healthChange(-5),
            OutcomeEffect.statChange('strength', -2),
            OutcomeEffect.statChange('dexterity', -1),
          ],
        ),
      ),
      Choice(
        text: 'Pick the lock deftly [DEX]',
        statRequired: 'dexterity',
        difficultyClass: 14,
        successOutcome: Outcome(
          description: 'Click! The lock opens smoothly. Inside: valuable items and a map showing a shortcut!',
          effects: [
            OutcomeEffect.giveItem('crystal_ball'),
            OutcomeEffect.statChange('dexterity', 3),
            OutcomeEffect.skipFloors(2),
          ],
        ),
        failureOutcome: Outcome(
          description: 'Your lock pick breaks, triggering a magic seal that drains you.',
          effects: [
            OutcomeEffect.statChange('dexterity', -3),
            OutcomeEffect.healthChange(-2),
          ],
        ),
      ),
    ],
  );

  static final Scenario crumblingBridge = Scenario(
    id: 'crumbling_bridge_01',
    title: 'Crumbling Bridge',
    description: 'A rope bridge stretches over a bottomless chasm. Several planks are missing, '
        'and the whole structure sways ominously in the wind.',
    rarity: ScenarioRarity.uncommon,
    choices: [
      Choice(
        text: 'Sprint across before it collapses [DEX]',
        statRequired: 'dexterity',
        difficultyClass: 16,
        successOutcome: Outcome(
          description: 'You dart across with incredible agility! Your confidence soars.',
          effects: [
            OutcomeEffect.statChange('dexterity', 3),
            OutcomeEffect.statChange('wisdom', 1),
          ],
        ),
        failureOutcome: Outcome(
          description: 'Your foot breaks through a plank! You barely grab the rope, bruised and shaken.',
          effects: [
            OutcomeEffect.healthChange(-4),
            OutcomeEffect.statChange('dexterity', -2),
            OutcomeEffect.loseFloors(2),
          ],
        ),
      ),
      Choice(
        text: 'Study the bridge pattern and cross methodically [INT]',
        statRequired: 'intelligence',
        difficultyClass: 15,
        successOutcome: Outcome(
          description: 'You identify the safe planks and cross easily. You notice a hidden cache mid-way!',
          effects: [
            OutcomeEffect.statChange('intelligence', 2),
            OutcomeEffect.giveItem('potion_of_agility'),
          ],
        ),
        failureOutcome: Outcome(
          description: 'Your calculations are wrong. You take a tumble.',
          effects: [
            OutcomeEffect.healthChange(-3),
            OutcomeEffect.statChange('intelligence', -2),
          ],
        ),
      ),
      Choice(
        text: 'Test each plank carefully [WIS]',
        statRequired: 'wisdom',
        difficultyClass: 13,
        successOutcome: Outcome(
          description: 'Patience pays off. You cross safely and feel more centered.',
          effects: [
            OutcomeEffect.statChange('wisdom', 2),
            OutcomeEffect.healthChange(2),
          ],
        ),
        failureOutcome: Outcome(
          description: 'Your caution makes you second-guess. You freeze mid-bridge as it sways wildly!',
          effects: [
            OutcomeEffect.statChange('wisdom', -1),
            OutcomeEffect.addStatus(StatusEffect(
              name: 'Shaken',
              type: StatusEffectType.disadvantage,
              duration: 2,
              description: 'Disadvantage on next 2 checks',
            )),
          ],
        ),
      ),
    ],
  );

  // --- RARE SCENARIOS (10% Chance) ---

  static final Scenario strangeMushroomCircle = Scenario(
    id: 'mushroom_circle_01',
    title: 'Strange Mushroom Circle',
    description: 'A perfect ring of glowing mushrooms surrounds a flat stone. '
        'The air shimmers with fey magic. This is a place of power... and danger.',
    rarity: ScenarioRarity.rare,
    choices: [
      Choice(
        text: 'Step into the circle and meditate [WIS]',
        statRequired: 'wisdom',
        difficultyClass: 18,
        successOutcome: Outcome(
          description: 'You commune with ancient spirits! They grant you their blessing and skip you forward!',
          effects: [
            OutcomeEffect.statChange('wisdom', 4),
            OutcomeEffect.addStatus(StatusEffect(
              name: 'Fey Blessing',
              type: StatusEffectType.blessed,
              duration: 10,
              description: 'Advantage on Wisdom checks',
            )),
            OutcomeEffect.skipFloors(5),
          ],
        ),
        failureOutcome: Outcome(
          description: 'Hostile fey spirits assault your mind! You stumble backward, mind fractured.',
          effects: [
            OutcomeEffect.healthChange(-6),
            OutcomeEffect.statChange('wisdom', -3),
            OutcomeEffect.statChange('intelligence', -2),
            OutcomeEffect.loseFloors(3),
          ],
        ),
      ),
      Choice(
        text: 'Consume one of the mushrooms [CON]',
        statRequired: 'constitution',
        difficultyClass: 17,
        successOutcome: Outcome(
          description: 'The mushroom grants you visions of power! Your body transforms, becoming stronger!',
          effects: [
            OutcomeEffect.maxHealthChange(3),
            OutcomeEffect.statChange('constitution', 3),
            OutcomeEffect.addStatus(StatusEffect(
              name: 'Mushroom Enhancement',
              type: StatusEffectType.statBoost,
              duration: 8,
              description: '+2 to all stats',
              statModifiers: {
                'strength': 2,
                'dexterity': 2,
                'intelligence': 2,
                'wisdom': 2,
                'charisma': 2,
              },
            )),
          ],
        ),
        failureOutcome: Outcome(
          description: 'The mushroom is violently poisonous! Your body convulses.',
          effects: [
            OutcomeEffect.healthChange(-8),
            OutcomeEffect.maxHealthChange(-2),
            OutcomeEffect.addStatus(StatusEffect(
              name: 'Severe Poisoning',
              type: StatusEffectType.cursed,
              duration: 10,
              description: 'All stats reduced by 2',
              statModifiers: {
                'strength': -2,
                'dexterity': -2,
                'constitution': -2,
                'intelligence': -2,
                'wisdom': -2,
                'charisma': -2,
              },
            )),
          ],
        ),
      ),
      Choice(
        text: 'Use magic to harness the circle\'s power [INT]',
        statRequired: 'intelligence',
        difficultyClass: 19,
        successOutcome: Outcome(
          description: 'You channel the fey magic perfectly! Reality bends to your will!',
          effects: [
            OutcomeEffect.statChange('intelligence', 5),
            OutcomeEffect.giveItem('divine_favor'),
            OutcomeEffect.swapStats('strength', 'intelligence'),
            OutcomeEffect.skipFloors(7),
          ],
        ),
        failureOutcome: Outcome(
          description: 'The magic backfires catastrophically! You\'re hurled back through the dungeon!',
          effects: [
            OutcomeEffect.healthChange(-5),
            OutcomeEffect.statChange('intelligence', -4),
            OutcomeEffect.loseFloors(5),
          ],
        ),
      ),
    ],
  );

  static final Scenario wanderingBard = Scenario(
    id: 'wandering_bard_01',
    title: 'The Wandering Bard',
    description: 'A cheerful bard sits on a rock, strumming a lute. '
        '"Ah, a fellow traveler! Care for a game of riddles? I promise the stakes are... interesting."',
    rarity: ScenarioRarity.rare,
    choices: [
      Choice(
        text: 'Accept his riddle challenge [INT]',
        statRequired: 'intelligence',
        difficultyClass: 17,
        successOutcome: Outcome(
          description: 'You solve every riddle flawlessly! The bard applauds and grants you a magical mirror.',
          effects: [
            OutcomeEffect.statChange('intelligence', 4),
            OutcomeEffect.giveItem('mirror_of_reversal'),
            OutcomeEffect.giveItem('tome_of_balance'),
          ],
        ),
        failureOutcome: Outcome(
          description: 'You fail the riddles. The bard laughs and casts a befuddlement spell!',
          effects: [
            OutcomeEffect.statChange('intelligence', -3),
            OutcomeEffect.swapStats('wisdom', 'charisma'),
          ],
        ),
      ),
      Choice(
        text: 'Challenge him to a performance duel [CHA]',
        statRequired: 'charisma',
        difficultyClass: 18,
        successOutcome: Outcome(
          description: 'Your performance brings tears to the bard\'s eyes! He declares you the winner and teleports you forward!',
          effects: [
            OutcomeEffect.statChange('charisma', 5),
            OutcomeEffect.addStatus(StatusEffect(
              name: 'Bardic Inspiration',
              type: StatusEffectType.advantage,
              duration: 8,
              description: 'Advantage on Charisma checks',
            )),
            OutcomeEffect.skipFloors(6),
          ],
        ),
        failureOutcome: Outcome(
          description: 'You embarrass yourself completely. The bard\'s mockery echoes through the dungeon.',
          effects: [
            OutcomeEffect.statChange('charisma', -4),
            OutcomeEffect.statChange('wisdom', -2),
          ],
        ),
      ),
      Choice(
        text: 'Rob him while he\'s distracted [DEX]',
        statRequired: 'dexterity',
        difficultyClass: 20,
        successOutcome: Outcome(
          description: 'You steal his entire bag of magical items without him noticing!',
          effects: [
            OutcomeEffect.statChange('dexterity', 3),
            OutcomeEffect.giveItem('lucky_charm'),
            OutcomeEffect.giveItem('crystal_ball'),
            OutcomeEffect.giveItem('greater_healing'),
          ],
        ),
        failureOutcome: Outcome(
          description: 'He catches you red-handed! The bard curses you and sends you tumbling backward!',
          effects: [
            OutcomeEffect.statChange('dexterity', -3),
            OutcomeEffect.statChange('charisma', -3),
            OutcomeEffect.loseFloors(4),
            OutcomeEffect.addStatus(StatusEffect(
              name: 'Bard\'s Curse',
              type: StatusEffectType.disadvantage,
              duration: 7,
              description: 'Disadvantage on all checks',
            )),
          ],
        ),
      ),
    ],
  );
}