import 'package:flutter/material.dart';
import 'package:society_management/constants/app_colors.dart';

class KDVLogo extends StatelessWidget {
  final double size;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;

  const KDVLogo({
    super.key,
    this.size = 120,
    this.primaryColor = AppColors.buttonColor,
    this.secondaryColor = Colors.white,
    this.backgroundColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: CustomPaint(
        size: Size(size, size),
        painter: KDVLogoPainter(
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
        ),
      ),
    );
  }
}

class KDVLogoPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  KDVLogoPainter({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw outer circle
    final outerCirclePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.08;
    
    canvas.drawCircle(center, radius * 0.85, outerCirclePaint);
    
    // Draw inner circle
    final innerCirclePaint = Paint()
      ..color = secondaryColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius * 0.7, innerCirclePaint);
    
    // Draw K
    final kPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.12
      ..strokeCap = StrokeCap.round;
    
    // Vertical line of K
    canvas.drawLine(
      Offset(center.dx - radius * 0.4, center.dy - radius * 0.4),
      Offset(center.dx - radius * 0.4, center.dy + radius * 0.4),
      kPaint,
    );
    
    // Upper diagonal of K
    canvas.drawLine(
      Offset(center.dx - radius * 0.4, center.dy),
      Offset(center.dx - radius * 0.1, center.dy - radius * 0.4),
      kPaint,
    );
    
    // Lower diagonal of K
    canvas.drawLine(
      Offset(center.dx - radius * 0.4, center.dy),
      Offset(center.dx - radius * 0.1, center.dy + radius * 0.4),
      kPaint,
    );
    
    // Draw D
    final dPath = Path();
    dPath.moveTo(center.dx, center.dy - radius * 0.4);
    dPath.lineTo(center.dx + radius * 0.1, center.dy - radius * 0.4);
    dPath.quadraticBezierTo(
      center.dx + radius * 0.5, center.dy,
      center.dx + radius * 0.1, center.dy + radius * 0.4,
    );
    dPath.lineTo(center.dx, center.dy + radius * 0.4);
    dPath.close();
    
    final dPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.08
      ..strokeCap = StrokeCap.round;
    
    canvas.drawPath(dPath, dPaint);
    
    // Draw V
    final vPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.08
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(
      Offset(center.dx - radius * 0.25, center.dy - radius * 0.2),
      Offset(center.dx, center.dy + radius * 0.2),
      vPaint,
    );
    
    canvas.drawLine(
      Offset(center.dx, center.dy + radius * 0.2),
      Offset(center.dx + radius * 0.25, center.dy - radius * 0.2),
      vPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
