import 'package:flutter/material.dart';
import '../../petsim/pet_game_manager.dart';

// Import Widgets
import '../widgets/pet_display_area.dart';
import '../widgets/pet_stat_grid.dart';
import '../widgets/pet_action_bar.dart';
import '../widgets/town_build_sheet.dart';

class PetScreen extends StatefulWidget {
  const PetScreen({super.key});

  @override
  State<PetScreen> createState() => _PetScreenState();
}

class _PetScreenState extends State<PetScreen> {
  final PetGameManager _manager = PetGameManager();

  @override
  void initState() {
    super.initState();
    _manager.initialize();
  }

  @override
  void dispose() {
    _manager.dispose();
    super.dispose();
  }

  void _showBuildMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => TownBuildSheet(
        townService: _manager.townService,
        onUpgrade: () => setState((){}), // Refresh screen if gold changed
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes in the Manager
    return ListenableBuilder(
      listenable: _manager,
      builder: (context, child) {
        if (_manager.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          backgroundColor: const Color(0xFF2C3E50),

          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.amber[700],
            onPressed: _showBuildMenu,
            child: const Icon(Icons.home_filled, size: 30),
          ),

          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Column(
              children: [
                Text(_manager.myPet.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("Gen ${_manager.myPet.generation}", style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
            actions: [
              IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState((){})),
            ],
          ),

          body: Column(
            children: [
              // 1. PET DISPLAY
              Expanded(
                  flex: 5,
                  child: PetDisplayArea(manager: _manager)
              ),

              // 2. TOOLS
              PetActionBar(manager: _manager),

              // 3. STATS
              Expanded(
                  flex: 4,
                  child: PetStatGrid(pet: _manager.myPet)
              ),
            ],
          ),
        );
      },
    );
  }
}