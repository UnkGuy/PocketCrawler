import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../petsim/pet_game_manager.dart';
import '../../pet.dart';

class SanctuaryPage extends StatefulWidget {
  final PetGameManager manager;
  const SanctuaryPage({super.key, required this.manager});

  @override
  State<SanctuaryPage> createState() => _SanctuaryPageState();
}

class _SanctuaryPageState extends State<SanctuaryPage> with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late AudioPlayer _sfxPlayer;
  String _petSpeech = "...";
  DateTime? _lastPetTime;
  Timer? _idleTimer;
  Alignment _petAlignment = Alignment.bottomCenter;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _sfxPlayer = AudioPlayer();
    _bounceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150), lowerBound: 0.0, upperBound: 0.1);
    _startIdleBehavior();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _sfxPlayer.dispose();
    _idleTimer?.cancel();
    super.dispose();
  }

  void _startIdleBehavior() {
    _idleTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      // Random wandering logic
      double randomX = _rng.nextBool() ? (_rng.nextDouble() * 1.6) - 0.8 : 0.0;
      setState(() => _petAlignment = Alignment(randomX, 1.0));
    });
  }

  Future<void> _playSound(String fileName) async => await _sfxPlayer.play(AssetSource('audio/$fileName'));

  void _onPetTap() {
    final now = DateTime.now();
    _bounceController.forward().then((_) => _bounceController.reverse());
    _playSound('squish.wav');

    if (_lastPetTime == null || now.difference(_lastPetTime!).inSeconds >= 60) {
      setState(() {
        _lastPetTime = now;
        _petSpeech = widget.manager.petPet();
      });
    } else {
      int remaining = 60 - now.difference(_lastPetTime!).inSeconds;
      setState(() => _petSpeech = "Resting... (${remaining}s)");
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _petSpeech = "...");
    });
  }

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder gives us the constraints of the available space in the PageView
    return LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. TOP STATS
                _buildStatusPanel(),

                // 2. PET AREA (Takes up all remaining space!)
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Speech Bubble floating near top of area
                      Positioned(
                        top: 20,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: _petSpeech == "..." ? 0.0 : 1.0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                                color: const Color(0xFFFFF8E1),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: const Color(0xFF5D4037), width: 2)
                            ),
                            child: Text(_petSpeech, style: const TextStyle(color: Color(0xFF3E2723), fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),

                      // The Pet (Movable within this expanded area)
                      GestureDetector(
                        onTap: _onPetTap, // Catch tap on background
                        child: Container(
                          color: Colors.transparent, // Required to catch taps on empty space
                          width: double.infinity,
                          height: double.infinity,
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 1500),
                            curve: Curves.easeInOutQuad,
                            alignment: _petAlignment,
                            child: GestureDetector(
                              onTap: _onPetTap,
                              child: AnimatedBuilder(
                                animation: _bounceController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scaleY: 1.0 - _bounceController.value,
                                    scaleX: 1.0 + (_bounceController.value * 0.5),
                                    alignment: Alignment.bottomCenter,
                                    child: child,
                                  );
                                },
                                child: Container(
                                  // Responsive size: 40% of screen height
                                  height: constraints.maxHeight * 0.4,
                                  width: constraints.maxHeight * 0.4,
                                  decoration: const BoxDecoration(
                                    // Optional shadow to ground the pet
                                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: -10, offset: Offset(0, 20))]
                                  ),
                                  child: Image.asset(
                                    _getPetAsset(widget.manager.myPet),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. BOTTOM BUTTONS
                _buildActionButtons(),
              ],
            ),
          );
        }
    );
  }

  String _getPetAsset(Pet pet) {
    if (pet.strength >= 20) return 'assets/pets/pet_warrior.png';
    if (pet.intelligence >= 20) return 'assets/pets/pet_mage.png';
    return 'assets/pets/pet_crystalcrab.gif'; // Make sure this asset exists
  }

  // (Keep _buildStatusPanel, _bar, _buildActionButtons same as previous version but verify imports)
  Widget _buildStatusPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF8D6E63))
      ),
      child: Column(
        children: [
          _bar("HP", widget.manager.myPet.currentHealth, widget.manager.myPet.maxHealth, Colors.redAccent),
          const SizedBox(height: 8),
          _bar("HGR", widget.manager.hunger, 100, Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _bar(String label, int current, int max, Color color) {
    double pct = (max == 0) ? 0 : (current / max).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(width: 40, child: Text(label, style: const TextStyle(color: Color(0xFFFFECB3), fontWeight: FontWeight.bold, fontSize: 12))),
        Expanded(
          child: Container(
            height: 14,
            decoration: BoxDecoration(
                color: const Color(0xFF3E2723),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF5D4037))
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct,
              child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _tokenButton(Icons.lunch_dining, "Feed", () {
            _playSound('eat.wav');
            setState(() => _petSpeech = widget.manager.feedPet());
          }),
          _tokenButton(Icons.back_hand, "Pet", _onPetTap),
          _tokenButton(Icons.cleaning_services, "Clean", () {
            _playSound('clean.wav');
            setState(() => _petSpeech = widget.manager.cleanPet());
          }),
        ],
      ),
    );
  }

  Widget _tokenButton(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFF5D4037),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF8D6E63), width: 3),
                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 3))]
            ),
            child: Icon(icon, color: const Color(0xFFFFECB3), size: 24),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Color(0xFFFFECB3), fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}