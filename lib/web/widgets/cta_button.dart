import 'package:flutter/material.dart';

class CTAButton extends StatefulWidget {
  final String title;
  final VoidCallback onPressed;
  final bool isPrimary;

  const CTAButton({
    super.key,
    required this.title,
    required this.onPressed,
    required this.isPrimary,
  });

  @override
  State<CTAButton> createState() => _CTAButtonState();
}

class _CTAButtonState extends State<CTAButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
        _controller.forward();
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isPrimary 
                ? Colors.white 
                : Colors.transparent,
            foregroundColor: widget.isPrimary 
                ? const Color(0xFF2A5298) 
                : Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: Colors.white,
                width: widget.isPrimary ? 0 : 2,
              ),
            ),
            elevation: widget.isPrimary ? 5 : 0,
            shadowColor: widget.isPrimary 
                ? Colors.black.withOpacity(0.3) 
                : Colors.transparent,
          ),
          child: Text(
            widget.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: widget.isPrimary 
                  ? const Color(0xFF2A5298) 
                  : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
