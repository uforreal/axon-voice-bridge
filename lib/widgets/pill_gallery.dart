import 'package:flutter/material.dart';

class PillGallery extends StatefulWidget {
  final VoidCallback onTap;
  final int currentIndex;

  const PillGallery({
    super.key,
    required this.onTap,
    required this.currentIndex,
  });

  @override
  State<PillGallery> createState() => _PillGalleryState();
}

class _PillGalleryState extends State<PillGallery>
    with SingleTickerProviderStateMixin {
  late AnimationController _panController;
  late Animation<double> _panAnimation;

  static const List<String> images = [
    'assets/images/dream-room.jpg',
    'assets/images/green-grotto.jpg',
    'assets/images/futuristic-interior.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _panController = AnimationController(
      duration: const Duration(seconds: 16),
      vsync: this,
    )..repeat(reverse: true);

    // Moves from 0 to -60 logical pixels
    _panAnimation = Tween<double>(begin: 0, end: -60).animate(
      CurvedAnimation(parent: _panController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _panController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 300,
        height: 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(135),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(135),
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _panAnimation,
                builder: (context, child) {
                  return Positioned(
                    left: _panAnimation.value, // Moves left
                    top: 0,
                    bottom: 0,
                    width: 400, // Explicitly wider than container (300)
                    child: Image.asset(
                      images[widget.currentIndex],
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
