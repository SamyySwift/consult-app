import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/slide_action_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  late VideoPlayerController _videoController;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initVideoPlayer();
  }

  Future<void> _initVideoPlayer() async {
    final sources = <String>[
      if (kIsWeb) 'video/main_bg.mp4',
      'assets/video/main_bg.mp4',
      'https://carpitalconsult.com/api/files/assets%2F1790245754648_f6a456e2d4a0.mp4',
      if (kIsWeb) 'video/bg.mp4',
      'assets/video/bg.mp4',
    ];

    for (final src in sources) {
      try {
        if (src.startsWith('http') || kIsWeb) {
          _videoController = VideoPlayerController.networkUrl(
            Uri.parse(src),
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          );
        } else {
          _videoController = VideoPlayerController.asset(
            src,
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          );
        }

        await _videoController.initialize();
        await _videoController.setLooping(true);
        await _videoController.setVolume(0.0); // Completely silent
        await _videoController.play();

        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
        return;
      } catch (e) {
        debugPrint('Video source ($src) initialization note: $e');
      }
    }

    if (mounted) {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isInitialized) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _videoController.pause();
    } else if (state == AppLifecycleState.resumed) {
      _videoController.play();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_isInitialized) {
      _videoController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070709),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: Ambient Background Fallback ──────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0B1410),
                  Color(0xFF070A09),
                  Color(0xFF060608),
                ],
              ),
            ),
          ),

          // ── Layer 2: Fullscreen Looping Video (Silent & Unobstructed) ─────
          if (_isInitialized && !_hasError)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: _videoController.value.size.width > 0
                      ? _videoController.value.size.width
                      : 720,
                  height: _videoController.value.size.height > 0
                      ? _videoController.value.size.height
                      : 1280,
                  child: VideoPlayer(_videoController),
                ),
              ),
            ),

          // ── Layer 3: Cinematic Atmospheric Vignettes ──────────────────────
          // Non-blocking gradient overlay so video remains visible in center
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.20, 0.45, 0.70, 1.0],
                    colors: [
                      Colors.black.withValues(alpha: 0.75),
                      Colors.black.withValues(alpha: 0.15),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.78),
                      Colors.black.withValues(alpha: 0.96),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Layer 4: Top Floating Brand Capsule ───────────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _buildBrandHeader(),
              ),
            ),
          ),

          // ── Layer 5: Bottom Interactive Hero Deck ─────────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Monumental Editorial Headline
                    _buildHeadline(),
                    const SizedBox(height: 12),

                    // Supporting Subtitle
                    _buildSubtitle(),
                    const SizedBox(height: 20),

                    // Proof-of-Trust Quality Metrics
                    _buildMetricsRow(),
                    const SizedBox(height: 26),

                    // Slide to Get Started Action Button
                    SlideActionButton(
                      label: 'Slide to Get Started',
                      onSlideComplete: () =>
                          context.go(AppConstants.routeRegister),
                    ),
                    const SizedBox(height: 16),

                    // Secondary Sign-In Link
                    _buildSignInLink(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandHeader() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.40),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _LiveStatusPulse(),
              const SizedBox(width: 8),
              Text(
                'CARPITAL CONSULT',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeadline() {
    return Text.rich(
      TextSpan(
        text: 'Relocate Your Vehicle\nWith ',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1.15,
          letterSpacing: -0.8,
        ),
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFF00E676),
                  Color(0xFF69F0AE),
                  Colors.white,
                ],
              ).createShader(bounds),
              child: Text(
                'Absolute Precision.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.15,
                  letterSpacing: -0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'White-glove carriers, real-time GPS telemetry tracking, and vetted insured transit nationwide.',
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14.5,
        color: const Color(0xFFA0A0A0),
        height: 1.45,
        letterSpacing: -0.1,
      ),
    );
  }

  Widget _buildMetricsRow() {
    return Row(
      children: [
        _buildMetricPill('100%', 'Insured Transit'),
        const SizedBox(width: 8),
        _buildMetricPill('Live GPS', 'Telemetry Track'),
        const SizedBox(width: 8),
        _buildMetricPill('4.9 ★', 'Client Rating'),
      ],
    );
  }

  Widget _buildMetricPill(String title, String subtitle) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF888888),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInLink(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Already have an account? ',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF7E7E7E),
              fontSize: 14,
            ),
          ),
          GestureDetector(
            onTap: () => context.go(AppConstants.routeLogin),
            child: Text(
              'Sign In →',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveStatusPulse extends StatefulWidget {
  const _LiveStatusPulse();

  @override
  State<_LiveStatusPulse> createState() => _LiveStatusPulseState();
}

class _LiveStatusPulseState extends State<_LiveStatusPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 10,
      height: 10,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00E676).withValues(
                      alpha: _opacityAnimation.value,
                    ),
                  ),
                ),
              );
            },
          ),
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF00E676),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF00E676),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
