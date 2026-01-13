import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/call_state_provider.dart';
import '../widgets/pill_gallery.dart';
import '../widgets/expanded_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _borderRadiusAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: const Cubic(0.32, 0.72, 0, 1), // Apple's ease curve
      ),
    );

    _borderRadiusAnimation = Tween<double>(begin: 135, end: 0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: const Cubic(0.32, 0.72, 0, 1),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleExpand() {
    final provider = context.read<CallStateProvider>();
    provider.expand();
    _scaleController.forward();
  }

  void _handleCollapse() {
    final provider = context.read<CallStateProvider>();
    _scaleController.reverse().then((_) {
      provider.collapse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<CallStateProvider>(
        builder: (context, state, child) {
          return Stack(
            children: [
              // The pill gallery - always visible underneath
              Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: state.isExpanded ? 0 : 1,
                  child: PillGallery(
                    onTap: _handleExpand,
                    currentIndex: state.currentImageIndex,
                  ),
                ),
              ),

              // The expanded overlay
              if (state.isExpanded)
                AnimatedBuilder(
                  animation: _scaleController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          _borderRadiusAnimation.value,
                        ),
                        child: Opacity(
                          opacity: _opacityAnimation.value.clamp(0.0, 1.0),
                          child: ExpandedView(
                            onClose: _handleCollapse,
                            currentIndex: state.currentImageIndex,
                            isMuted: state.isMuted,
                            callDuration: state.callDuration,
                            onToggleMute: () => state.toggleMute(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              // Debug Console (The "Brain Monitor")
              if (state.isExpanded)
                Positioned(
                  bottom: 40,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3))
                    ),
                    child: Text(
                      state.debugLog,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        color: Colors.greenAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
