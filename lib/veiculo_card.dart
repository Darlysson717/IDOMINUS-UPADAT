import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VeiculoCard extends StatelessWidget {
  final String foto;
  final String nome;
  final String preco;
  final String ano;
  final String quilometragem;
  final String cidadeEstado;
  final String badge;
  final VoidCallback onVerDetalhes;

  const VeiculoCard({
    super.key,
    required this.foto,
    required this.nome,
    required this.preco,
    required this.ano,
    required this.quilometragem,
    required this.cidadeEstado,
    required this.badge,
    required this.onVerDetalhes,
  });

  double? _parsePreco(String precoRaw) {
    final trimmed = precoRaw.trim();
    if (trimmed.isEmpty) return null;

    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;

    int decimalDigits = 0;
    final match = RegExp(r'[.,](\d+)\s*$').firstMatch(trimmed);
    if (match != null) {
      decimalDigits = match.group(1)?.length ?? 0;
      if (decimalDigits > 2) decimalDigits = 0;
    }

    final valorBase = double.tryParse(digits);
    if (valorBase == null) return null;

    double divisor = 1;
    for (var i = 0; i < decimalDigits; i++) {
      divisor *= 10;
    }

    return valorBase / divisor;
  }

  String _formatPreco(String precoRaw) {
    final valor = _parsePreco(precoRaw);
    if (valor == null) return precoRaw;

    final formatted = NumberFormat.decimalPattern('pt_BR').format(valor.round());
    final hasCurrency = RegExp(r'R\$\s*', caseSensitive: false).hasMatch(precoRaw);
    return hasCurrency ? 'R\$ $formatted' : formatted;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 400;
    final cardRadius = isSmall ? 12.0 : 18.0;
    final imageHeight = isSmall ? 280.0 : 390.0;
    final padding = isSmall ? 12.0 : 16.0;

    return SizedBox(
      width: double.infinity,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        elevation: 4,
        shadowColor: Colors.black12,
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagem com badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(cardRadius)),
                  child: (foto.isEmpty || foto == 'null')
                      ? Container(
                          height: imageHeight,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: Icon(Icons.directions_car, size: 70, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey[600]),
                        )
                      : Hero(
                          tag: foto,
                          child: Image.network(
                            foto,
                            height: imageHeight,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: imageHeight,
                                width: double.infinity,
                                color: Colors.grey[300],
                                child: Icon(Icons.directions_car, size: 70, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey[600]),
                              );
                            },
                          ),
                        ),
                ),
                if (badge.isNotEmpty)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _BadgeChip(label: badge),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nome/modelo
                  Text(
                    nome,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmall ? 18 : 24,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Preço (formatado em milhares, sem decimais)
                  Text(
                    _formatPreco(preco),
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: isSmall ? 17 : 22,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Linha de detalhes + botão
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Detalhes do veículo em linha única
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: _DetailInfo(
                                icon: Icons.calendar_today,
                                label: ano,
                                isSmall: isSmall,
                              ),
                            ),
                            SizedBox(width: isSmall ? 8 : 12),
                            Flexible(
                              child: _DetailInfo(
                                icon: Icons.speed,
                                label: quilometragem,
                                isSmall: isSmall,
                              ),
                            ),
                            SizedBox(width: isSmall ? 8 : 12),
                            Flexible(
                              flex: 2,
                              child: _DetailInfo(
                                icon: Icons.location_on,
                                label: cidadeEstado,
                                isSmall: isSmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: isSmall ? 12 : 16),
                      // Botão "Ver" destacado
                      ElevatedButton(
                        onPressed: onVerDetalhes,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: isSmall ? 8 : 12,
                            horizontal: isSmall ? 14 : 18,
                          ),
                          minimumSize: Size(isSmall ? 80 : 96, isSmall ? 38 : 44),
                        ),
                        child: Text(
                          'Ver',
                          style: TextStyle(
                            fontSize: isSmall ? 15 : 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSmall;

  const _DetailInfo({
    required this.icon,
    required this.label,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: isSmall ? 15 : 17, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey[600]),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isSmall ? 13 : 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final String label;
  const _BadgeChip({required this.label});
  @override
  Widget build(BuildContext context) {
    Color base;
    if(label.toLowerCase() == 'novo'){
      base = Colors.blueAccent;
    } else if(label.toLowerCase() == 'destaque'){
      base = Colors.orange;
    } else {
      base = Colors.green;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [base.withValues(alpha: .95), base.withValues(alpha: .75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: base.withValues(alpha: .35), blurRadius: 6, offset: const Offset(0,3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if(label.toLowerCase() == 'novo') const Icon(Icons.fiber_new, size: 16, color: Colors.white),
          if(label.toLowerCase() == 'novo') const SizedBox(width:4),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12, letterSpacing: .3)),
        ],
      ),
    );
  }
}
