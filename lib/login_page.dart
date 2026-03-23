import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/profile_service.dart';
import 'services/update_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  bool _oauthStarted = false;
  Timer? _sessionTimer;
  int _pollAttempts = 0;
  bool _isLoading = false;
  String? _errorMessage;
  late final AnimationController _bgController;
  final List<_ShapeConfig> _shapes = const [
    _ShapeConfig(
      kind: ShapeKind.circle,
      base: Offset(0.2, 0.25),
      travel: Offset(0.12, 0.08),
      sizeFactor: 120,
      phase: 0.05,
      opacity: 0.08,
    ),
    _ShapeConfig(
      kind: ShapeKind.square,
      base: Offset(0.75, 0.2),
      travel: Offset(-0.1, 0.12),
      sizeFactor: 100,
      phase: 0.35,
      opacity: 0.06,
    ),
    _ShapeConfig(
      kind: ShapeKind.circle,
      base: Offset(0.6, 0.65),
      travel: Offset(0.1, -0.1),
      sizeFactor: 160,
      phase: 0.6,
      opacity: 0.07,
    ),
    _ShapeConfig(
      kind: ShapeKind.square,
      base: Offset(0.3, 0.75),
      travel: Offset(-0.08, 0.1),
      sizeFactor: 130,
      phase: 0.8,
      opacity: 0.05,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    _checkForUpdate();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _checkForUpdate() async {
    try {
      final updateInfo = await UpdateService.checkForUpdate();
      if (updateInfo == null) return;

      final currentVersion = await UpdateService.getCurrentVersion();
      if (UpdateService.compareVersions(currentVersion, updateInfo['version']) <
          0) {
        if (!mounted) return;
        _showUpdateDialog(updateInfo);
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Erro ao verificar atualização: $e');
        debugPrint(stack.toString());
      }
    }
  }

  void _showUpdateDialog(Map<String, dynamic> updateInfo) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova versão disponível'),
        content: Text(
          'Versão ${updateInfo['version']} está disponível. Abriremos a loja ou o navegador para concluir a atualização.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Depois'),
          ),
          ElevatedButton(
            onPressed: kIsWeb
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Atualizações não disponíveis na web. Use o app mobile.')),
                    );
                  }
                : () async {
                    try {
                      await UpdateService.downloadAndInstallUpdate(
                        updateInfo['apkUrl'],
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    } catch (error) {
                      if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao abrir a atualização: $error'),
                  ),
                );
              }
            },
            child: const Text('Atualizar'),
          ),
        ],
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _oauthStarted = true;
    });

    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? 'https://darlysson717.github.io/DOMINUSWEB/' : 'io.supabase.flutter://callback',
      );
      _startSessionPolling();
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('Falha ao iniciar autenticação: $error');
        debugPrint(stack.toString());
      }
      setState(() {
        _errorMessage = 'Falha ao iniciar autenticação com Google: $error';
        _oauthStarted = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      } else {
        _isLoading = false;
      }
    }
  }

  void _startSessionPolling() {
    _sessionTimer?.cancel();
    _pollAttempts = 0;
    _sessionTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      _pollAttempts++;
      final user = Supabase.instance.client.auth.currentUser;
      if (kDebugMode) {
        debugPrint(
          'Polling attempt $_pollAttempts - user detected? ${user != null}',
        );
      }

      if (user != null) {
        timer.cancel();
        unawaited(ProfileService().syncProfileFromAuth());
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else if (_pollAttempts > 20) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _oauthStarted = false;
            _errorMessage =
                'Tempo excedido aguardando autenticação. Tente novamente.';
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double maxContentWidth = math.min(420, size.width - 32);

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, _) {
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _BackgroundShapesPainter(
                    progress: _bgController.value,
                    shapes: _shapes,
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 24),
                          const _DominusLogo(size: 200),
                          Text(
                            'BEM VINDO DOMINUS',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.7,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Login',
                            style: GoogleFonts.poppins(
                              fontSize: 34,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Sign in to continue.',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Colors.black.withValues(alpha: 0.55),
                            ),
                          ),
                          const SizedBox(height: 32),
                          if (_oauthStarted &&
                              Supabase.instance.client.auth.currentUser == null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Aguardando retorno do Google...',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black.withValues(
                                          alpha: 0.65,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_oauthStarted &&
                              Supabase.instance.client.auth.currentUser == null)
                            const SizedBox(height: 18),
                          if (_errorMessage != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Color(0xFFD93025),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFFD93025),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_errorMessage != null) const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signInWithGoogle,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const _GoogleLogo(size: 22),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Entrar com o Google',
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
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

class _DominusLogo extends StatelessWidget {
  final double size;
  const _DominusLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/Dominuscorte.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.redAccent,
          );
        },
      ),
    );
  }
}

enum ShapeKind { circle, square }

class _ShapeConfig {
  final ShapeKind kind;
  final Offset base;
  final Offset travel;
  final double sizeFactor;
  final double phase;
  final double opacity;
  const _ShapeConfig({
    required this.kind,
    required this.base,
    required this.travel,
    required this.sizeFactor,
    required this.phase,
    required this.opacity,
  });
}

class _BackgroundShapesPainter extends CustomPainter {
  final double progress;
  final List<_ShapeConfig> shapes;
  const _BackgroundShapesPainter({
    required this.progress,
    required this.shapes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shortestSide = size.shortestSide;
    for (final shape in shapes) {
      final t = (progress + shape.phase) % 1.0;
      final offset = Offset(
        (shape.base.dx + shape.travel.dx * math.sin(2 * math.pi * t)) *
            size.width,
        (shape.base.dy + shape.travel.dy * math.cos(2 * math.pi * t)) *
            size.height,
      );
      final paint = Paint()
        ..color = Colors.black.withValues(alpha: shape.opacity);
      final dimension = shape.sizeFactor + shortestSide * 0.08;

      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.rotate(0.35 * t);
      switch (shape.kind) {
        case ShapeKind.circle:
          canvas.drawCircle(Offset.zero, dimension * 0.5, paint);
          break;
        case ShapeKind.square:
          final rect = Rect.fromCenter(
            center: Offset.zero,
            width: dimension,
            height: dimension,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(16)),
            paint,
          );
          break;
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundShapesPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.shapes != shapes;
  }
}

class _GoogleLogo extends StatelessWidget {
  final double size;
  const _GoogleLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    final stroke = size * 0.22;
    return CustomPaint(
      size: Size.square(size),
      painter: _GoogleLogoPainter(stroke),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  final double stroke;
  const _GoogleLogoPainter(this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    const gap = math.pi / 12;
    const double blueSweep = 7 * math.pi / 12;
    const double redSweep = math.pi / 3;
    const double yellowSweep = math.pi / 3;
    final double greenSweep =
        2 * math.pi - (blueSweep + redSweep + yellowSweep + gap);

    const double start = -math.pi / 4;

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, start, blueSweep, false, paint);

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, start + blueSweep, redSweep, false, paint);

    paint.color = const Color(0xFFFBBC04);
    canvas.drawArc(
      rect,
      start + blueSweep + redSweep,
      yellowSweep,
      false,
      paint,
    );

    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      rect,
      start + blueSweep + redSweep + yellowSweep,
      greenSweep,
      false,
      paint,
    );

    paint
      ..color = const Color(0xFF4285F4)
      ..strokeCap = StrokeCap.square;
    final lineY = size.height * 0.5;
    final lineStart = Offset(size.width * 0.56, lineY);
    final lineEnd = Offset(size.width * 0.88, lineY);
    canvas.drawLine(lineStart, lineEnd, paint);
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter oldDelegate) => false;
}
