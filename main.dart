import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:math_expressions/math_expressions.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GlassCalculatorApp());
}

class GlassCalculatorApp extends StatelessWidget {
  const GlassCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Glass Calculator',
      theme: ThemeData(
        brightness: Brightness.dark,
        textTheme: textTheme,
        scaffoldBackgroundColor: const Color(0xFF0A0B0F),
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6AD6FF),
      ),
      home: const CalculatorPage(),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  String _expr = '';
  String _result = '';

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _AnimatedGradientBackground(controller: _ctrl),
          _MovingBlobs(controller: _ctrl),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _glass(
                    radius: 28,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            reverse: true,
                            child: Text(
                              _expr.isEmpty ? '0' : _expr,
                              key: const Key(
                                'calculator_display',
                              ), // <--- Key added
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.white.withOpacity(0.85),
                                letterSpacing: 1.1,
                              ),
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            transitionBuilder: (child, anim) => SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.05, 0.25),
                                end: Offset.zero,
                              ).animate(anim),
                              child: FadeTransition(
                                opacity: anim,
                                child: child,
                              ),
                            ),
                            child: Text(
                              _result.isEmpty ? ' ' : _result,
                              key: const ValueKey('calculator_result'),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _glass(
                      radius: 28,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _buildKeyboard(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboard() {
    final keys = <List<String>>[
      ['C', 'DEL', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['±', '0', '.', '='],
    ];

    return Column(
      children: [
        for (final row in keys)
          Expanded(
            child: Row(
              children: [
                for (final k in row)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: GlassButton(
                        label: k,
                        isAccent: '÷×-+=%'.contains(k),
                        isDanger: k == 'C' || k == 'DEL',
                        onTap: () => _onKey(k),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  void _onKey(String k) {
    HapticFeedback.lightImpact();

    setState(() {
      switch (k) {
        case 'C':
          _expr = '';
          _result = '';
          return;
        case 'DEL':
          if (_expr.isNotEmpty) _expr = _expr.substring(0, _expr.length - 1);
          _tryEval();
          return;
        case '=':
          _finalizeResult();
          return;
        case '%':
          _expr = _applyToLastNumber(_expr, (v) => v / 100);
          _tryEval();
          return;
        case '±':
          _expr = _toggleSignOnLastNumber(_expr);
          _tryEval();
          return;
        default:
          _append(k);
          _tryEval();
      }
    });
  }

  void _append(String k) {
    if (_isOperator(k)) {
      if (_expr.isEmpty) return;
      final last = _expr[_expr.length - 1];
      if (_isOperator(last)) {
        _expr = _expr.substring(0, _expr.length - 1) + k;
      } else {
        _expr += k;
      }
    } else if (k == '.') {
      final tail = _tailNumber(_expr);
      if (tail.contains('.')) return;
      _expr += k;
    } else {
      _expr += k;
    }
  }

  void _tryEval() {
    if (_expr.isEmpty) {
      _result = '';
      return;
    }
    final last = _expr[_expr.length - 1];
    if (_isOperator(last)) {
      _result = '';
      return;
    }
    try {
      final val = _evaluate(_expr);
      _result = _formatNumber(val);
    } catch (_) {
      _result = '';
    }
  }

  void _finalizeResult() {
    if (_result.isNotEmpty) {
      _expr = _result;
    }
  }

  bool _isOperator(String s) => ['+', '-', '×', '÷'].contains(s);

  String _tailNumber(String expr) {
    final m = RegExp(r'(-?\d+\.?\d*)$').firstMatch(expr);
    return m?.group(0) ?? '';
  }

  String _applyToLastNumber(String expr, double Function(double) transform) {
    final m = RegExp(r'(-?\d+\.?\d*)$').firstMatch(expr);
    if (m == null) return expr;
    final start = m.start, end = m.end;
    final v = double.tryParse(m.group(0)!) ?? 0.0;
    final rep = _formatNumber(transform(v));
    return expr.replaceRange(start, end, rep);
  }

  String _toggleSignOnLastNumber(String expr) {
    final m = RegExp(r'(-?\d+\.?\d*)$').firstMatch(expr);
    if (m == null) return expr;
    final start = m.start, end = m.end;
    final v = double.tryParse(m.group(0)!) ?? 0.0;
    final rep = _formatNumber(-v);
    return expr.replaceRange(start, end, rep);
  }

  double _evaluate(String expression) {
    final sanitized = expression.replaceAll('×', '*').replaceAll('÷', '/');
    final parser = Parser();
    final exp = parser.parse(sanitized);
    final cm = ContextModel();
    final res = exp.evaluate(EvaluationType.REAL, cm);
    return (res is num) ? res.toDouble() : double.nan;
  }

  String _formatNumber(double v) {
    if (v.isNaN || v.isInfinite) return 'Error';
    final s = v.toStringAsFixed(10).replaceFirst(RegExp(r'\.?0+$'), '');
    return s;
  }

  Widget _glass({required Widget child, double radius = 20}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: Colors.white.withOpacity(0.07),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// Animated background and blobs same as before...

class _AnimatedGradientBackground extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedGradientBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        final c1 = Color.lerp(
          const Color(0xFF0F2027),
          const Color(0xFF4A148C),
          t,
        )!;
        final c2 = Color.lerp(
          const Color(0xFF203A43),
          const Color(0xFF0D47A1),
          1 - t,
        )!;
        final c3 = Color.lerp(
          const Color(0xFF2C5364),
          const Color(0xFF00ACC1),
          (0.5 - (t - 0.5).abs()) * 2,
        )!;

        final begin = Alignment.lerp(
          Alignment.topLeft,
          Alignment.bottomRight,
          t,
        )!;
        final end = Alignment.lerp(
          Alignment.bottomRight,
          Alignment.topLeft,
          t,
        )!;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: begin,
              end: end,
              colors: [c1, c2, c3],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
        );
      },
    );
  }
}

class _MovingBlobs extends StatelessWidget {
  final AnimationController controller;
  const _MovingBlobs({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        final s = MediaQuery.sizeOf(context);

        double wave(double phase, double amp, double freq) =>
            amp * math.sin(2 * math.pi * (t * freq + phase));

        return IgnorePointer(
          child: Stack(
            children: [
              _blob(
                left: s.width * 0.15 + wave(0.1, 24, 1),
                top: s.height * 0.12 + wave(0.3, 18, 1.2),
                size: s.width * 0.55,
                color: const Color(0xFF64B5F6).withOpacity(0.20),
              ),
              _blob(
                right: s.width * 0.05 + wave(0.6, 28, 0.8),
                top: s.height * 0.48 + wave(0.2, 22, 1.1),
                size: s.width * 0.6,
                color: const Color(0xFF80DEEA).withOpacity(0.18),
              ),
              _blob(
                left: s.width * 0.35 + wave(0.9, 18, 1.3),
                bottom: s.height * 0.04 + wave(0.5, 20, 0.9),
                size: s.width * 0.5,
                color: const Color(0xFFCE93D8).withOpacity(0.16),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _blob({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double size,
    required Color color,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          gradient: RadialGradient(
            colors: [Colors.white.withOpacity(0.12), color],
            center: const Alignment(-0.3, -0.3),
          ),
        ),
      ),
    );
  }
}

class GlassButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isAccent;
  final bool isDanger;

  const GlassButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isAccent = false,
    this.isDanger = false,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = Colors.white.withOpacity(0.07);
    final border = Colors.white.withOpacity(0.16);

    final accent = widget.isDanger
        ? Colors.redAccent.withOpacity(0.85)
        : widget.isAccent
        ? Theme.of(context).colorScheme.secondary.withOpacity(0.85)
        : Colors.white.withOpacity(0.9);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 110),
        scale: _pressed ? 0.96 : 1.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: widget.label == '=' ? 28 : 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: accent,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
