import 'dart:math';

import 'package:flutter/material.dart';

class _Particle {
  Offset position;
  double size;
  Color color;
  Offset velocity;
  double maxLife;
  double life;
  bool blinks;
  double blinkPhase;
  bool hasGlow;

  _Particle({
    required this.position,
    required this.size,
    required this.color,
    required this.velocity,
    required this.maxLife,
    required this.life,
    required this.blinks,
    required this.blinkPhase,
    required this.hasGlow,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> _particles;
  final Random _random;

  _ParticlePainter(this._particles, this._random, Animation<double> animation)
      : super(repaint: animation);

  void _tick(Size size) {
    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.life -= 1;
      if (p.life <= 0) {
        _particles[i] = _makeParticle(size);
      } else {
        p.position = Offset(
          p.position.dx + p.velocity.dx + (_random.nextDouble() - 0.5) * 0.05,
          p.position.dy + p.velocity.dy + (_random.nextDouble() - 0.5) * 0.05,
        );
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_particles.isEmpty) _init(size);
    _tick(size);
    for (final p in _particles) {
      double a = p.life / p.maxLife;
      if (p.blinks) {
        final b = (sin(p.life * 0.03 + p.blinkPhase) + 1) / 2;
        a *= b;
      }
      a = a.clamp(0.0, 1.0);
      if (a <= 0) continue;

      if (p.hasGlow) {
        final glowPaint = Paint()
          ..color = p.color.withValues(alpha: a * 0.55)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(p.position, p.size, glowPaint);
      }

      final paint = Paint()
        ..color = p.color.withValues(alpha: a)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p.position, p.size, paint);
    }
  }

  void _init(Size size) {
    final n = (size.width * size.height / 20000).round().clamp(8, 90);
    for (int i = 0; i < n; i++) {
      _particles.add(_makeParticle(size));
    }
  }

  _Particle _makeParticle(Size size) {
    final hue = _random.nextDouble() * 50 + 250;
    final lightness = _random.nextDouble() * 20 + 60;
    return _Particle(
      position: Offset(
        _random.nextDouble() * size.width * 0.6 + size.width * 0.4,
        _random.nextDouble() * size.height,
      ),
      size: _random.nextDouble() * 1.5 + 0.5,
      color: HSLColor.fromAHSL(1.0, hue, 1.0, lightness / 100).toColor(),
      velocity: Offset(
        (_random.nextDouble() - 0.5) * 0.12,
        (_random.nextDouble() - 0.5) * 0.12,
      ),
      maxLife: _random.nextDouble() * 300 + 150,
      life: _random.nextDouble() * 300 + 150,
      blinks: _random.nextDouble() > 0.7,
      blinkPhase: _random.nextDouble() * pi * 2,
      hasGlow: _random.nextDouble() > 0.6,
    );
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

/// Full-screen animated particle background identical to the ghpage particle canvas.
///
/// Wrap any screen's [Scaffold] body with this widget:
/// ```dart
/// ParticleBackground(
///   enabled: settingsShowParticles,
///   child: myScreenBody,
/// )
/// ```
///
/// Particles run on their own repaint cycle via [CustomPainter] + [AnimationController]
/// so the child widget tree is NOT rebuilt every frame.
class ParticleBackground extends StatefulWidget {
  final Widget child;

  /// When false, the child is returned as-is (no overhead).
  final bool enabled;

  const ParticleBackground({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _ParticlePainter(_particles, _random, _controller),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}
