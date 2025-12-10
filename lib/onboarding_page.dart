import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class _OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  const _OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class OnboardingPage extends StatefulWidget {
  final VoidCallback onFinish;
  const OnboardingPage({super.key, required this.onFinish});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      title: 'Login rápido e simples',
      description: 'Acesse sua conta de forma rápida e segura usando apenas o Google. Sem senha, sem cadastro manual - apenas um clique!',
      icon: Icons.lock_open_rounded,
      color: Color(0xFF743BEF),
    ),
    _OnboardingSlide(
      title: 'Segurança e verificação',
      description: 'Priorizamos sua segurança: solicitamos documentos dos vendedores e permitimos anúncios apenas de lojistas com CNPJ verificado.',
      icon: Icons.verified_user_rounded,
      color: Color(0xFF743BEF),
    ),
    _OnboardingSlide(
      title: 'Veículos verificados e confiáveis',
      description: 'Explore anúncios de vendedores confiáveis. Negocie com tranquilidade e encontre o veículo ideal com total segurança.',
      icon: Icons.speed_rounded,
      color: Color(0xFF743BEF),
    ),
    _OnboardingSlide(
      title: 'Suporte dedicado',
      description: 'Conte com nosso suporte para tirar dúvidas e resolver qualquer situação. Estamos aqui para ajudar você a ter a melhor experiência.',
      icon: Icons.headset_mic_rounded,
      color: Color(0xFF743BEF),
    ),
  ];

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _controller.nextPage(duration: Duration(milliseconds: 350), curve: Curves.ease);
    } else {
      widget.onFinish();
    }
  }

  void _skip() {
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _skip,
                child: Text('Pular', style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Color(0xFF743BEF))),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) {
                  final slide = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: slide.color.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 64,
                            backgroundColor: slide.color.withValues(alpha: 0.12),
                            child: Icon(slide.icon, size: 72, color: slide.color),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(slide.title,
                            style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: slide.color)),
                        const SizedBox(height: 20),
                        Text(slide.description,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                                fontSize: 18,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                                height: 1.4)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) => AnimatedContainer(
                duration: Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 18),
                width: _currentPage == i ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == i ? _slides[i].color : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
              )),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 28, left: 32, right: 32),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _slides[_currentPage].color,
                    elevation: 8,
                    shadowColor: _slides[_currentPage].color.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(_currentPage == _slides.length - 1 ? 'Começar' : 'Próximo',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
