import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/update_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _oauthStarted = false;
  Timer? _sessionTimer;
  int _pollAttempts = 0;
  bool _isLoading = false;
  String? _errorMessage;


  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    final updateInfo = await UpdateService.checkForUpdate();
    if (updateInfo != null) {
      final currentVersion = await UpdateService.getCurrentVersion();
      if (UpdateService.compareVersions(currentVersion, updateInfo['version']) < 0) {
        _showUpdateDialog(updateInfo);
      }
    }
  }

  void _showUpdateDialog(Map<String, dynamic> updateInfo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova versão disponível'),
        content: Text('Versão ${updateInfo['version']} está disponível. Deseja atualizar agora?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Depois'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              UpdateService.downloadAndInstallUpdate(updateInfo['apkUrl']);
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
        redirectTo: 'io.supabase.flutter://callback',
      );
      _startSessionPolling();
    } catch (e) {
      setState(() {
        _errorMessage = 'Falha ao iniciar autenticação com Google: ${e.toString()}';
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
      debugPrint('Polling attempt $_pollAttempts - user detected? ${user != null}');

      if (user != null) {
        timer.cancel();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else if (_pollAttempts > 20) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _oauthStarted = false;
            _errorMessage = 'Tempo excedido aguardando autenticação. Tente novamente.';
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top gradient background
          Container(
            height: size.height * 0.80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF743BEF), Color(0xFF9C70FF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Column(
            children: [
              SizedBox(
                height: size.height * 0.60,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('DOMINUS',
                        style: GoogleFonts.poppins(
                            fontSize: 40,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.1,
                            color: Colors.white)),
                    const SizedBox(height: 26),
                    Text('Bem-vindo Dominus',
                        style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                    const SizedBox(height: 6),
                    Text('Entre para continuar',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(.85))),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(46), topRight: Radius.circular(46)),
                    boxShadow: [
                      BoxShadow(
                          color: Color(0x22000000), blurRadius: 14, offset: Offset(0, -4)),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 30, 28, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_oauthStarted && Supabase.instance.client.auth.currentUser == null)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF743BEF).withOpacity(.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: const Color(0xFF743BEF).withOpacity(.20)),
                            ),
                            child: Row(children: [
                              const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      valueColor:
                                          AlwaysStoppedAnimation(Color(0xFF743BEF)))),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Text('Aguardando retorno do Google...',
                                      style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF743BEF))))
                            ]),
                          ),
                        if (_errorMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 18),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(children: [
                              const Icon(Icons.error_outline, color: Color(0xFFD93025)),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text(_errorMessage!,
                                      style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFFD93025))))
                            ]),
                          ),
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signInWithGoogle,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              backgroundColor: const Color(0xFF743BEF),
                              disabledBackgroundColor:
                                  const Color(0xFF743BEF).withOpacity(.5),
                            ),
                            child: Ink(
                              decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                      colors: [Color(0xFF743BEF), Color(0xFF9C70FF)],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight),
                                  borderRadius: BorderRadius.all(Radius.circular(16))),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isLoading)
                                    const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2.6,
                                            valueColor:
                                                AlwaysStoppedAnimation(Colors.white)))
                                  else
                                    Container(
                                      height: 26,
                                      width: 26,
                                      decoration: const BoxDecoration(
                                          shape: BoxShape.circle, color: Colors.white),
                                      child: const Center(
                                          child: Text('G',
                                              style: TextStyle(
                                                  color: Color(0xFF4285F4),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold))),
                                    ),
                                  const SizedBox(width: 14),
                                  Text(_isLoading ? 'Entrando...' : 'Entrar com Google',
                                      style: GoogleFonts.poppins(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          letterSpacing: .3)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: Text(
                            'Rápido, seguro e sem senha',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF743BEF),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: Color(0x22000000),
                                  offset: Offset(0, 2),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
