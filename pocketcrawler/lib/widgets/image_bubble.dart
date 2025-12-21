import 'dart:math';
import 'package:flutter/material.dart';

import '../dungeon/scenario.dart';

class DraggableBubble extends StatefulWidget {
  final Widget child;
  final Offset initialPosition;
  final double size;
  final PetController? controller;

  const DraggableBubble({
    super.key,
    required this.child,
    this.initialPosition = const Offset(100, 100),
    this.size = 80.0,
    this.controller,
  });

  // This allows us to access the State from the parent
  @override
  State<DraggableBubble> createState() => DraggableBubbleState();
}

// Note: I removed the '_' from DraggableBubbleState so it's public
class DraggableBubbleState extends State<DraggableBubble> with TickerProviderStateMixin {
  late Offset position;

  // Animation controllers
  late AnimationController _shakeController;
  Color _overlayColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    position = widget.initialPosition;
    widget.controller?.addListener(_handleEvent);

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    );
  }

  void _handleEvent() {
    if (widget.controller == null) return;

    final color = widget.controller!.flashColor;

    // If it's red (damage), add a shake!
    if (color == Colors.red) {
      shake();
    }
    //do other things based on status effect
    switch(widget.controller!.effects){
      case "shaken":
        shake();
    }

    // Apply the flash color from the controller
    if(color != Colors.white10){
    flash(color, const Duration(milliseconds: 300));
    }else{
      shake();
    }
  }

  // --- PUBLIC METHODS ---

  /// Flashes the pet with a specific color (e.g., Red for damage, Green for heal)
  void flash(Color color, Duration duration) async {
    setState(() => _overlayColor = color);
    await Future.delayed(duration);
    if (mounted) {
      setState(() => _overlayColor = Colors.transparent);
    }
  }

  /// Makes the pet shake for a specific duration
  void shake({int count = 6}) async {
    for (int i = 0; i < count; i++) {
      await _shakeController.forward(from: 0.0);
      await _shakeController.reverse();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    widget.controller?.removeListener(_handleEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            position = Offset(
              (position.dx + details.delta.dx).clamp(0.0, screenSize.width - widget.size),
              (position.dy + details.delta.dy).clamp(0.0, screenSize.height - widget.size),
            );
          });
        },
        // AnimatedBuilder handles the "Shake"
        child: AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            // Shake logic: slight sine wave rotation or offset
            double offset = sin(_shakeController.value * pi * 2) * 4;
            return Transform.translate(
              offset: Offset(offset, 0),
              child: child,
            );
          },
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[900],
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(child: widget.child),
                // The Overlay Color Layer
                AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  color: _overlayColor.withOpacity(_overlayColor == Colors.transparent ? 0 : 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}