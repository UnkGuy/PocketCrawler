import '../pet.dart';

/// Represents a consumable item that can be used during a dungeon run
class Item {
  final String id;
  final String name;
  final String description;
  final ItemType type;
  final ItemRarity rarity;

  /// Duration in floors (0 = instant, >0 = lasts X floors)
  final int duration;

  /// Stat modifications (Key: stat name, Value: modifier amount)
  final Map<String, int>? statModifiers;

  /// Health restoration amount
  final int? healthRestore;

  /// Stats to swap (for stat swapper items)
  final String? swapStat1;
  final String? swapStat2;

  /// Reveals success chance (for oracle items)
  final bool revealsSuccessChance;

  /// Status effect type to apply (for blessings/curses)
  final StatusEffectType? grantedEffectType;

  const Item({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.rarity = ItemRarity.common,
    this.duration = 0,
    this.statModifiers,
    this.healthRestore,
    this.swapStat1,
    this.swapStat2,
    this.revealsSuccessChance = false,
    this.grantedEffectType,
  });

  // ============================================================================
  // ITEM USAGE
  // ============================================================================

  /// Use the item and apply its effects to the pet
  ItemUseResult use(Pet pet) {
    List<String> messages = [];

    switch (type) {
      case ItemType.statBoost:
        _applyStatBoost(pet, messages);
        break;

      case ItemType.healthPotion:
        _applyHealthPotion(pet, messages);
        break;

      case ItemType.statSwapper:
        _applyStatSwapper(pet, messages);
        break;

      case ItemType.oracle:
        messages.add('The $name reveals hidden knowledge...');
        break;

      case ItemType.blessing:
      case ItemType.curse:
        _applyStatusEffect(pet, messages);
        break;
    }

    return ItemUseResult(
      success: true,
      messages: messages,
      item: this,
    );
  }

  /// Apply stat boost effects
  void _applyStatBoost(Pet pet, List<String> messages) {
    if (statModifiers == null) return;

    if (duration > 0) {
      // Temporary boost
      statModifiers!.forEach((stat, amount) {
        pet.applyTempModifier(stat, amount);
        messages.add('${stat.toUpperCase()} +$amount for $duration floors');
      });
    } else {
      // Permanent boost (for this run)
      statModifiers!.forEach((stat, amount) {
        pet.modifyStat(stat, amount);
        messages.add('${stat.toUpperCase()} permanently +$amount');
      });
    }
  }

  /// Apply health potion effects
  void _applyHealthPotion(Pet pet, List<String> messages) {
    if (healthRestore == null) return;

    int missingHealth = pet.maxHealth - pet.currentHealth;
    int actualHealing = healthRestore! >= 999
        ? missingHealth
        : (healthRestore! > missingHealth ? missingHealth : healthRestore!);

    pet.heal(healthRestore!);
    messages.add('Restored $actualHealing HP');
  }

  /// Apply stat swapper effects
  void _applyStatSwapper(Pet pet, List<String> messages) {
    if (swapStat1 == null || swapStat2 == null) return;

    pet.swapStats(swapStat1!, swapStat2!);
    messages.add('Swapped ${swapStat1!.toUpperCase()} and ${swapStat2!.toUpperCase()}');
  }

  /// Apply blessing/curse status effects
  void _applyStatusEffect(Pet pet, List<String> messages) {
    StatusEffectType effectType = grantedEffectType ??
        (type == ItemType.blessing ? StatusEffectType.blessed : StatusEffectType.cursed);

    pet.addStatusEffect(StatusEffect(
      name: name,
      type: effectType,
      duration: duration,
      description: description,
      statModifiers: statModifiers,
    ));

    String action = type == ItemType.blessing ? 'Gained blessing' : 'Afflicted with curse';
    messages.add('$action: $name for $duration floors');
  }

  @override
  String toString() => '$name - $description';
}

// ==============================================================================
// ITEM ENUMS
// ==============================================================================

/// Types of items
enum ItemType {
  statBoost, // Increases one or more stats
  healthPotion, // Restores health
  statSwapper, // Swaps two stats
  oracle, // Reveals success chances
  blessing, // Beneficial status effect
  curse, // Negative status effect
}

/// Rarity of items (affects drop rate)
enum ItemRarity {
  common,
  uncommon,
  rare,
}

// ==============================================================================
// ITEM USE RESULT
// ==============================================================================

/// Result of using an item
class ItemUseResult {
  final bool success;
  final List<String> messages;
  final Item item;

  const ItemUseResult({
    required this.success,
    required this.messages,
    required this.item,
  });
}

// ==============================================================================
// ACTIVE ITEM EFFECT (For duration-based items)
// ==============================================================================

/// Tracks active temporary item effects in GameState
class ActiveItemEffect {
  final Item item;
  int remainingDuration;

  ActiveItemEffect({
    required this.item,
    required this.remainingDuration,
  });

  /// Decrement the duration
  void tick() {
    remainingDuration--;
  }

  /// Check if the effect has expired
  bool get isExpired => remainingDuration <= 0;

  /// Revert temporary effects when item expires
  void onExpire(Pet pet) {
    // Only statBoost items with duration modify tempStatModifiers
    if (item.type == ItemType.statBoost &&
        item.duration > 0 &&
        item.statModifiers != null) {
      item.statModifiers!.forEach((stat, amount) {
        pet.applyTempModifier(stat, -amount);
      });
    }
  }

  @override
  String toString() => '${item.name} ($remainingDuration floors)';
}

// ==============================================================================
// ITEM LIBRARY
// ==============================================================================

/// Predefined items library
class ItemLibrary {
  static const Map<String, Item> _items = {
    // --- HEALTH POTIONS ---
    'minor_healing': Item(
      id: 'minor_healing',
      name: 'Minor Healing Potion',
      description: 'Restores 3 HP',
      type: ItemType.healthPotion,
      rarity: ItemRarity.common,
      healthRestore: 3,
    ),
    'healing_potion': Item(
      id: 'healing_potion',
      name: 'Healing Potion',
      description: 'Restores 5 HP',
      type: ItemType.healthPotion,
      rarity: ItemRarity.uncommon,
      healthRestore: 5,
    ),
    'greater_healing': Item(
      id: 'greater_healing',
      name: 'Greater Healing Potion',
      description: 'Fully restores HP',
      type: ItemType.healthPotion,
      rarity: ItemRarity.rare,
      healthRestore: 999,
    ),

    // --- TEMPORARY STAT BOOSTERS ---
    'elixir_of_strength': Item(
      id: 'elixir_of_strength',
      name: 'Elixir of Strength',
      description: 'Gain +3 STR for 5 floors',
      type: ItemType.statBoost,
      rarity: ItemRarity.uncommon,
      duration: 5,
      statModifiers: {'strength': 3},
    ),
    'potion_of_agility': Item(
      id: 'potion_of_agility',
      name: 'Potion of Agility',
      description: 'Gain +3 DEX for 5 floors',
      type: ItemType.statBoost,
      rarity: ItemRarity.uncommon,
      duration: 5,
      statModifiers: {'dexterity': 3},
    ),
    'draught_of_intellect': Item(
      id: 'draught_of_intellect',
      name: 'Draught of Intellect',
      description: 'Gain +3 INT for 5 floors',
      type: ItemType.statBoost,
      rarity: ItemRarity.uncommon,
      duration: 5,
      statModifiers: {'intelligence': 3},
    ),
    'tonic_of_wisdom': Item(
      id: 'tonic_of_wisdom',
      name: 'Tonic of Wisdom',
      description: 'Gain +3 WIS for 5 floors',
      type: ItemType.statBoost,
      rarity: ItemRarity.uncommon,
      duration: 5,
      statModifiers: {'wisdom': 3},
    ),
    'philter_of_charm': Item(
      id: 'philter_of_charm',
      name: 'Philter of Charm',
      description: 'Gain +3 CHA for 5 floors',
      type: ItemType.statBoost,
      rarity: ItemRarity.uncommon,
      duration: 5,
      statModifiers: {'charisma': 3},
    ),

    // --- STAT SWAPPERS ---
    'mirror_of_reversal': Item(
      id: 'mirror_of_reversal',
      name: 'Mirror of Reversal',
      description: 'Swap STR and DEX',
      type: ItemType.statSwapper,
      rarity: ItemRarity.rare,
      swapStat1: 'strength',
      swapStat2: 'dexterity',
    ),
    'tome_of_balance': Item(
      id: 'tome_of_balance',
      name: 'Tome of Balance',
      description: 'Swap INT and WIS',
      type: ItemType.statSwapper,
      rarity: ItemRarity.rare,
      swapStat1: 'intelligence',
      swapStat2: 'wisdom',
    ),

    // --- ORACLE ITEMS ---
    'crystal_ball': Item(
      id: 'crystal_ball',
      name: 'Crystal Ball',
      description: 'Reveals success chances for next 3 floors',
      type: ItemType.oracle,
      rarity: ItemRarity.rare,
      duration: 3,
      revealsSuccessChance: true,
    ),
    'scroll_of_insight': Item(
      id: 'scroll_of_insight',
      name: 'Scroll of Insight',
      description: 'Reveals stats used for the next choice',
      type: ItemType.oracle,
      rarity: ItemRarity.uncommon,
      duration: 1,
      revealsSuccessChance: true,
    ),

    // --- BLESSINGS ---
    'lucky_charm': Item(
      id: 'lucky_charm',
      name: 'Lucky Charm',
      description: 'Gain Advantage on all checks for 3 floors',
      type: ItemType.blessing,
      grantedEffectType: StatusEffectType.advantage,
      rarity: ItemRarity.rare,
      duration: 3,
    ),
    'divine_favor': Item(
      id: 'divine_favor',
      name: 'Divine Favor',
      description: 'Gain +2 to all stats for 5 floors',
      type: ItemType.blessing,
      grantedEffectType: StatusEffectType.blessed,
      rarity: ItemRarity.rare,
      duration: 5,
      statModifiers: {
        'strength': 2,
        'dexterity': 2,
        'constitution': 2,
        'intelligence': 2,
        'wisdom': 2,
        'charisma': 2,
      },
    ),
  };

  /// Get an item by ID
  static Item? getItem(String id) => _items[id];

  /// Get all items
  static List<Item> getAllItems() => _items.values.toList();

  /// Get a random item by rarity
  static Item? getRandomItem(ItemRarity rarity) {
    final matchingItems = _items.values.where((item) => item.rarity == rarity).toList();
    if (matchingItems.isEmpty) return null;

    matchingItems.shuffle();
    return matchingItems.first;
  }

  /// Get all items of a specific rarity
  static List<Item> getItemsByRarity(ItemRarity rarity) {
    return _items.values.where((item) => item.rarity == rarity).toList();
  }

  /// Get all items of a specific type
  static List<Item> getItemsByType(ItemType type) {
    return _items.values.where((item) => item.type == type).toList();
  }
}