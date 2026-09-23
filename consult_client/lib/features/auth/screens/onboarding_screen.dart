import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/slide_action_button.dart';

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
                  SlideActionButton(
                    label: 'Get Started',
                    onSlideComplete: () => context.go(AppConstants.routeRegister),
                  ).animate(delay: 400.ms).fadeIn(duration: 600.ms).slideY(begin: 0.2),
                  SizedBox(height: 20),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                            color: context.colors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go(AppConstants.routeLogin),
                          child: Text(
                            'Sign in',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 500.ms).fadeIn(duration: 600.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
