import 'dart:math' as math;

import 'package:flutter/material.dart';

class PlaceholderImage extends StatefulWidget {
  final double width;
  final double height;
  final Color color;
  final IconData icon;
  final bool isAnimated;
  final List<Color>? gradientColors;
  final String? imageUrl;

  const PlaceholderImage({
    super.key,
    this.width = 100,
    this.height = 100,
    this.color = const Color(0xFF2A5298),
    this.icon = Icons.image,
    this.isAnimated = true,
    this.gradientColors,
    this.imageUrl,
  });

  @override
  State<PlaceholderImage> createState() => _PlaceholderImageState();
}

class _PlaceholderImageState extends State<PlaceholderImage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isAnimated) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> colors =
        widget.gradientColors ?? [widget.color, widget.color.withBlue((widget.color.blue + 40) % 255)];

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(_isHovered ? 0.4 : 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: widget.imageUrl != null
                  ? Stack(
                      children: [
                        // Gradient background as fallback
                        Container(
                          width: widget.width,
                          height: widget.height,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: colors,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              widget.icon,
                              size: widget.width * 0.3,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ),
                        // Network image with loading indicator
                        Image.network(
                          widget.imageUrl!,
                          width: widget.width,
                          height: widget.height,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            }
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                                color: Colors.white,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Stack(
                              children: [
                                // Background pattern
                                Positioned.fill(
                                  child: Opacity(
                                    opacity: 0.1,
                                    child: CustomPaint(
                                      painter: BackgroundPatternPainter(
                                        color: Colors.white,
                                        dotSize: 2,
                                        spacing: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                // Main icon
                                Center(
                                  child: Transform.scale(
                                    scale: widget.isAnimated ? _scaleAnimation.value : (_isHovered ? 1.1 : 1.0),
                                    child: Transform.rotate(
                                      angle: widget.isAnimated ? _rotationAnimation.value * 0.1 : 0,
                                      child: Container(
                                        padding: EdgeInsets.all(widget.width * 0.1),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          widget.icon,
                                          size: widget.width * 0.3,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    )
                  : Stack(
                      children: [
                        // Background pattern
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.1,
                            child: CustomPaint(
                              painter: BackgroundPatternPainter(
                                color: Colors.white,
                                dotSize: 2,
                                spacing: 20,
                              ),
                            ),
                          ),
                        ),
                        // Main icon
                        Center(
                          child: Transform.scale(
                            scale: widget.isAnimated ? _scaleAnimation.value : (_isHovered ? 1.1 : 1.0),
                            child: Transform.rotate(
                              angle: widget.isAnimated ? _rotationAnimation.value * 0.1 : 0,
                              child: Container(
                                padding: EdgeInsets.all(widget.width * 0.1),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  widget.icon,
                                  size: widget.width * 0.3,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Decorative elements
                        Positioned(
                          top: widget.height * 0.2,
                          left: widget.width * 0.15,
                          child: _buildDecorativeElement(6, Colors.white.withOpacity(0.3)),
                        ),
                        Positioned(
                          bottom: widget.height * 0.25,
                          right: widget.width * 0.2,
                          child: _buildDecorativeElement(8, Colors.white.withOpacity(0.2)),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDecorativeElement(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class BackgroundPatternPainter extends CustomPainter {
  final Color color;
  final double dotSize;
  final double spacing;

  BackgroundPatternPainter({
    required this.color,
    required this.dotSize,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = dotSize
      ..strokeCap = StrokeCap.round;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // Draw a single point
        canvas.drawCircle(
          Offset(x, y),
          dotSize / 2,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
