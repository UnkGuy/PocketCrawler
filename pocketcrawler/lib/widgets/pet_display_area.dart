import 'package:flutter/material.dart';
import '../petsim/pet_game_manager.dart';
import '../../pet.dart';

class PetDisplayArea extends StatelessWidget {
  final PetGameManager manager;

  const PetDisplayArea({super.key, required this.manager});

  // --- EVOLUTION LOGIC ---
  String _getPetAsset(Pet pet) {
    // 1. Check Highest Stat
    Map<String, int> stats = {
      'str': pet.strength,
      'dex': pet.dexterity,
      'int': pet.intelligence,
    };

    // Sort to find highest
    var highest = stats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    String dominantStat = highest.first.key;

    // 2. Determine "Stage" based on Generation or Total Stats
    // Assuming you have these assets in your folder
    if (dominantStat == 'str') return 'assets/pets/pet_warrior.png';
    if (dominantStat == 'dex') return 'assets/pets/pet_rogue.png';
    if (dominantStat == 'int') return 'assets/pets/pet_mage.png';

    return 'assets/pets/pet_blob.png'; // Default
  }

  @override
  Widget build(BuildContext context) {
    bool hasCustomImage = manager.getCustomPetImage() != null;

    // Determine the asset if no custom image is set
    String assetPath = _getPetAsset(manager.myPet);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ... Keep Status Bars code ...

        const Spacer(),

        // PET CONTAINER
        DragTarget<String>(
          // ... (Keep existing drag logic) ...
            builder: (context, candidates, rejects) {
              return GestureDetector(
                // ... (Keep existing gesture logic) ...
                  child: Stack(
                    children: [
                      Container(
                        width: 200, height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          // --- UPDATED IMAGE LOGIC ---
                          image: hasCustomImage
                              ? DecorationImage(image: manager.getCustomPetImage()!, fit: BoxFit.cover)
                              : DecorationImage(image: AssetImage(assetPath), fit: BoxFit.cover),
                          // ---------------------------
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)],
                        ),
                      ),
                      // ... Keep Dirt logic ...
                    ],
                  )
              );
            }
        ),
        const Spacer(),
      ],
    );
  }
}