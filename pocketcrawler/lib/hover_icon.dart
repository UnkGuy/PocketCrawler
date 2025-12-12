import 'package:flutter/material.dart';

class SmartHoverTooltip extends StatefulWidget {
  final Widget child;
  final Widget tooltipContent;
  final bool triggerOnLongPress;
  final Color backgroundColor; // <--- New Parameter

  const SmartHoverTooltip({
    super.key,
    required this.child,
    required this.tooltipContent,
    this.triggerOnLongPress = true,
    this.backgroundColor = Colors.white, // Default to white
  });

  @override
  State<SmartHoverTooltip> createState() => _SmartHoverTooltipState();
}

enum TriggerMode { hover, manual }

class _SmartHoverTooltipState extends State<SmartHoverTooltip> {
  OverlayEntry? _overlayEntry;
  bool _isVisible = false;
  TriggerMode _triggerMode = TriggerMode.hover;

  void _showOverlay({required TriggerMode mode}) {
    if (_isVisible) return;

    setState(() {
      _triggerMode = mode;
      _isVisible = true;
    });

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    // Safety check: if the widget is off-screen (e.g. in a scroll view), don't show
    if (!mounted) return;

    final double screenWidth = mediaQuery.size.width;
    final double screenHeight = mediaQuery.size.height;

    final bool showAbove = offset.dy > screenHeight * 0.6;
    final bool alignRight = offset.dx > screenWidth * 0.6;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 1. Mobile/Manual Blocker (Only adds if triggered manually)
          if (_triggerMode == TriggerMode.manual)
            Positioned.fill(
              child: GestureDetector(
                onTap: _removeOverlay,
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.transparent),
              ),
            ),

          // 2. The Tooltip Box
          Positioned(
            top: showAbove ? null : offset.dy + size.height + 5,
            bottom: showAbove ? screenHeight - offset.dy + 5 : null,
            left: alignRight ? null : offset.dx,
            right: alignRight ? screenWidth - (offset.dx + size.width) : null,
            child: Material(
              elevation: 8,
              color: widget.backgroundColor, // <--- Applies the color here
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: BoxConstraints(maxWidth: screenWidth * 0.8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.backgroundColor, // <--- And here
                  borderRadius: BorderRadius.circular(8),
                ),
                child: widget.tooltipContent,
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _isVisible = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: widget.triggerOnLongPress
          ? () => _showOverlay(mode: TriggerMode.manual)
          : null,
      onTap: widget.triggerOnLongPress
          ? null
          : () {
        _isVisible
            ? _removeOverlay()
            : _showOverlay(mode: TriggerMode.manual);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _showOverlay(mode: TriggerMode.hover),
        onExit: (_) => _removeOverlay(),
        child: widget.child,
      ),
    );
  }
}