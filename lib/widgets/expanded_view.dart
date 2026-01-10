import 'package:flutter/material.dart';
import 'dart:ui';
import 'status_card.dart';

class ExpandedView extends StatefulWidget {
  final VoidCallback onClose;
  final int currentIndex;
  final bool isMuted;
  final String callDuration;
  final VoidCallback onToggleMute;

  const ExpandedView({
    super.key,
    required this.onClose,
    required this.currentIndex,
    required this.isMuted,
    required this.callDuration,
    required this.onToggleMute,
  });

  @override
  State<ExpandedView> createState() => _ExpandedViewState();
}

class _ExpandedViewState extends State<ExpandedView>
    with SingleTickerProviderStateMixin {
  late AnimationController _cardController;
  late Animation<double> _cardOpacity;
  late Animation<Offset> _cardSlide;
  bool _showCard = false;

  static const List<String> images = [
    'assets/images/dream-room.jpg',
    'assets/images/green-grotto.jpg',
    'assets/images/futuristic-interior.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _cardOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: const Cubic(0.32, 0.72, 0, 1),
      ),
    );

    _cardSlide = Tween<Offset>(
      begin: const Offset(0, -0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: const Cubic(0.32, 0.72, 0, 1),
      ),
    );

    // Show card after expansion animation
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _showCard = true);
        _cardController.forward();
      }
    });
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: widget.onToggleMute,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: Image.asset(
                images[widget.currentIndex],
                fit: BoxFit.cover,
              ),
            ),

            // Status card overlay
            if (_showCard)
              AnimatedBuilder(
                animation: _cardController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _cardOpacity.value,
                    child: SlideTransition(
                      position: _cardSlide,
                      child: Center(
                        child: StatusCard(
                          isMuted: widget.isMuted,
                          callDuration: widget.callDuration,
                        ),
                      ),
                    ),
                  );
                },
              ),

            // Close button
            Positioned(
              top: 48,
              right: 24,
              child: _CloseButton(onTap: widget.onClose),
            ),

            // Mute indicator
            if (widget.isMuted)
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'MICROPHONE MUTED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.close,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
