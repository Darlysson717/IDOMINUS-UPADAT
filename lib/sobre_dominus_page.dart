import 'package:flutter/material.dart';

class SobreDominusPage extends StatelessWidget {
  const SobreDominusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 400;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sobre o Dominus'),
        backgroundColor: Colors.deepPurple,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmall ? 20 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo/Icon principal
            Container(
              width: isSmall ? 120 : 150,
              height: isSmall ? 120 : 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.3),
                    spreadRadius: 3,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.business,
                size: 60,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            // Título principal
            Text(
              'Dominus',
              style: TextStyle(
                fontSize: isSmall ? 28 : 32,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Marketplace de Veículos',
              style: TextStyle(
                fontSize: isSmall ? 16 : 18,
                color: Colors.deepPurple,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 32),

            // Card de descrição
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(isSmall ? 20 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.deepPurple,
                          size: isSmall ? 24 : 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Sobre Nós',
                          style: TextStyle(
                            fontSize: isSmall ? 20 : 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'O Dominus é a plataforma líder em marketplace de veículos, conectando compradores e vendedores de forma segura e eficiente. Nossa missão é revolucionar a forma como as pessoas compram e vendem veículos, oferecendo uma experiência digital completa e confiável.',
                      style: TextStyle(
                        fontSize: isSmall ? 14 : 16,
                        color: isDark ? Colors.white70 : Colors.grey[700],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Seção de recursos (texto simples)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(isSmall ? 20 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.star_outline,
                          color: Colors.deepPurple,
                          size: isSmall ? 24 : 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Nossos Diferenciais',
                          style: TextStyle(
                            fontSize: isSmall ? 20 : 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '• Segurança: Transações seguras e verificação completa de usuários\n'
                      '• Rapidez: Anúncios publicados e disponíveis em poucos minutos\n'
                      '• Qualidade: Veículos verificados e informações confiáveis\n'
                      '• Suporte: Atendimento dedicado e especializado 24 horas por dia',
                      style: TextStyle(
                        fontSize: isSmall ? 14 : 16,
                        color: isDark ? Colors.white70 : Colors.grey[700],
                        height: 1.6,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Card de contato
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(isSmall ? 20 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.contact_mail,
                          color: Colors.deepPurple,
                          size: isSmall ? 24 : 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Contato',
                          style: TextStyle(
                            fontSize: isSmall ? 20 : 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _ContactItem(
                      icon: Icons.email,
                      title: 'E-mail',
                      value: 'contato@dominus.com.br',
                      isSmall: isSmall,
                    ),
                    const SizedBox(height: 12),
                    _ContactItem(
                      icon: Icons.phone,
                      title: 'Telefone',
                      value: '(11) 9999-9999',
                      isSmall: isSmall,
                    ),
                    const SizedBox(height: 12),
                    _ContactItem(
                      icon: Icons.web,
                      title: 'Website',
                      value: 'www.dominus.com.br',
                      isSmall: isSmall,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Versão do app
            Text(
              'Versão 1.0.0',
              style: TextStyle(
                fontSize: isSmall ? 12 : 14,
                color: isDark ? Colors.white54 : Colors.grey[500],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isSmall;

  const _ContactItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          icon,
          size: isSmall ? 20 : 24,
          color: Colors.deepPurple.withOpacity(0.7),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: isSmall ? 12 : 14,
                color: isDark ? Colors.white54 : Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: isSmall ? 14 : 16,
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}