import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Stack(
        children: [
          // Hero Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.65,
            child: ShaderMask(
              shaderCallback: (rect) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.transparent],
                ).createShader(Rect.fromLTRB(0, rect.height * 0.5, rect.width, rect.height));
              },
              blendMode: BlendMode.dstIn,
              child: Image.network(
                'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?q=80&w=3538&auto=format&fit=crop',
                fit: BoxFit.cover,
                color: const Color(0xFF00C853).withValues(alpha: 0.08), // Subtle green tint
                colorBlendMode: BlendMode.colorBurn,
              ),
            ),
          ),
          
          // Bottom Content
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.colors.background.withValues(alpha: 0.0),
                    context.colors.background.withValues(alpha: 0.8),
                    context.colors.background,
                    context.colors.background,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Book Vehicle Transport\nEffortlessly',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
                  SizedBox(height: 16),
                  Text(
                    'Schedule pick-up, drop-off, and shipping for your car in minutes. No paperwork headaches.',
                    style: TextStyle(
                      fontSize: 15,
                      color: context.colors.textSecondary,
                      height: 1.5,
                    ),
                  ).animate(delay: 200.ms).fadeIn(duration: 600.ms).slideY(begin: 0.2),
                  SizedBox(height: 48),
                  GestureDetector(
                    onTap: () => context.go(AppConstants.routeRegister),
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: context.colors.accent,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: context.colors.accent,
                              size: 24,
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                'Get Started',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 20),
                          Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 20),
                          Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 20),
                          SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ).animate(delay: 400.ms).fadeIn(duration: 600.ms).slideY(begin: 0.2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
