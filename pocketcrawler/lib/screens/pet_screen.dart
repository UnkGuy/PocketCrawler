import 'package:flutter/material.dart';
import '../../petsim/pet_game_manager.dart';
import '../widgets/town_page.dart';
import '../widgets/sanctuary_page.dart';
import '../widgets/dungeon_gate_page.dart';

class PetScreen extends StatefulWidget {
  const PetScreen({super.key});

  @override
  State<PetScreen> createState() => _PetScreenState();
}

class _PetScreenState extends State<PetScreen> {
  final PetGameManager _manager = PetGameManager();
  // Start at page 1 (Sanctuary) so we can swipe Left (Town) or Right (Gate)
  final PageController _pageController = PageController(initialPage: 1);

  @override
  void initState() {
    super.initState();
    _manager.initialize();
  }

  @override
  void dispose() {
    _manager.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _manager,
      builder: (context, child) {
        if (_manager.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFF3E2723),
            body: Center(child: CircularProgressIndicator(color: Colors.amber)),
          );
        }

        return Scaffold(
          body: Stack(
            children: [
              // --- 1. UNIFIED PARALLAX BACKGROUND ---
              // This background stays behind everything and slides based on scroll
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    // Calculate alignment:
                    // Page 0 (Town) = -1.0 (Left)
                    // Page 1 (Sanctuary) = 0.0 (Center)
                    // Page 2 (Gate) = 1.0 (Right)
                    double page = _pageController.hasClients ? (_pageController.page ?? 1.0) : 1.0;
                    double alignmentX = page - 1.0;

                    return Image.asset(
                      'assets/backgrounds/wide_tabletop_bg.png', // One VERY WIDE image (e.g. 3000px wide)
                      fit: BoxFit.cover,
                      alignment: Alignment(alignmentX, 0.0), // Slides left/right
                      errorBuilder: (c, e, s) => Container(color: const Color(0xFF3E2723)), // Fallback Wood Color
                    );
                  },
                ),
              ),

              // --- 2. THE PAGES (Transparent backgrounds) ---
              SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(), // Stats Panel

                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const ClampingScrollPhysics(), // Stops "bouncing" past edges
                        children: [
                          TownPage(manager: _manager),
                          SanctuaryPage(manager: _manager),
                          DungeonGatePage(manager: _manager),
                        ],
                      ),
                    ),

                    _buildPageIndicator(), // Navigation
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF4E342E).withOpacity(0.9), // Dark Wood transparency
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF8D6E63), width: 2),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _statBadge(Icons.stars, "Gen ${_manager.myPet.generation}"),
          Text(
              _manager.myPet.name,
              style: const TextStyle(
                  color: Color(0xFFFFECB3),
                  fontSize: 20,
                  fontFamily: 'Pixelify',
                  shadows: [Shadow(color: Colors.black, blurRadius: 2)]
              )
          ),
          _statBadge(Icons.monetization_on, "${_manager.townService.gold} G"),
        ],
      ),
    );
  }

  Widget _statBadge(IconData icon, String text) {
    return Row(children: [
      Icon(icon, color: Colors.amber, size: 16),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
    ]);
  }

  Widget _buildPageIndicator() {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        int page = _pageController.hasClients ? (_pageController.page?.round() ?? 1) : 1;
        return Container(
          height: 60,
          decoration: BoxDecoration(
              color: const Color(0xFF3E2723),
              border: const Border(top: BorderSide(color: Color(0xFF8D6E63), width: 2)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0,-5))]
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navIcon(Icons.store_mall_directory, "Town", 0, page),
              _navIcon(Icons.cottage, "Sanctuary", 1, page),
              _navIcon(Icons.door_back_door, "Gate", 2, page),
            ],
          ),
        );
      },
    );
  }

  Widget _navIcon(IconData icon, String label, int index, int currentPage) {
    bool isSelected = index == currentPage;
    return GestureDetector(
      onTap: () => _pageController.animateToPage(index, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut),
      child: AnimatedScale(
        scale: isSelected ? 1.2 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.amber : const Color(0xFFD7CCC8)),
            if(isSelected) // Only show text when selected to save space
              Text(label, style: const TextStyle(color: Colors.amber, fontSize: 10, fontFamily: 'Pixelify')),
          ],
        ),
      ),
    );
  }
}