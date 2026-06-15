import 'package:flutter/material.dart';

class PremiumAiSpeedDial extends StatefulWidget {
  const PremiumAiSpeedDial({
    super.key,
    required this.firstOptionTitle,
    required this.firstOptionIcon,
    required this.firstOptionTap,
    required this.secondOptionTitle,
    required this.secondOptionIcon,
    required this.secondOptionTap,
    required this.isVip,
  });

  final String firstOptionTitle;
  final IconData firstOptionIcon;
  final VoidCallback firstOptionTap;
  final String secondOptionTitle;
  final IconData secondOptionIcon;
  final VoidCallback secondOptionTap;
  final bool isVip;

  @override
  State<PremiumAiSpeedDial> createState() => _PremiumAiSpeedDialState();
}

class _PremiumAiSpeedDialState extends State<PremiumAiSpeedDial> with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.fastOutSlowIn,
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isOpen) ...[
          // Option 2 (AI Planner - VIP)
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: FadeTransition(
              opacity: _expandAnimation,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.secondOptionTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFB03A), Color(0xFFFF7E00)],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'VIP',
                              style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    FloatingActionButton.small(
                      heroTag: 'speed_dial_planner',
                      backgroundColor: const Color(0xFFE81CFF),
                      foregroundColor: Colors.white,
                      onPressed: () {
                        _toggleMenu();
                        widget.secondOptionTap();
                      },
                      child: Icon(widget.secondOptionIcon),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Option 1 (AI Coach - Free)
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: FadeTransition(
              opacity: _expandAnimation,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.firstOptionTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'FREE',
                            style: TextStyle(fontSize: 8, color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    FloatingActionButton.small(
                      heroTag: 'speed_dial_coach',
                      backgroundColor: const Color(0xFF06B6D4),
                      foregroundColor: Colors.white,
                      onPressed: () {
                        _toggleMenu();
                        widget.firstOptionTap();
                      },
                      child: Icon(widget.firstOptionIcon),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        // Main button
        Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFE81CFF), Color(0xFF06B6D4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE81CFF).withOpacity(0.35),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _toggleMenu,
              child: RotationTransition(
                turns: _rotateAnimation,
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
