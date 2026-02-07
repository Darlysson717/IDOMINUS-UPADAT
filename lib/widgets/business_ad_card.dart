import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/business_ads_service.dart';

class BusinessAdCard extends StatefulWidget {
  final Map<String, dynamic> ad;
  final bool showStats;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const BusinessAdCard({
    super.key,
    required this.ad,
    this.showStats = false,
    this.onTap,
    this.onDelete,
  });

  @override
  State<BusinessAdCard> createState() => _BusinessAdCardState();
}

class _BusinessAdCardState extends State<BusinessAdCard> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Incrementar visualização quando o anúncio é exibido
    _incrementView();
  }

  Future<void> _incrementView() async {
    try {
      await BusinessAdsService().incrementViews(widget.ad['id']);
    } catch (e) {
      // Silenciar erros de visualização para não incomodar o usuário
      debugPrint('Erro ao incrementar visualização: $e');
    }
  }

  Color _getPlanColor() {
    switch (widget.ad['plan_type']) {
      case 'premium':
        return Colors.purple;
      case 'destaque':
        return Colors.orange;
      case 'basico':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getPlanLabel() {
    switch (widget.ad['plan_type']) {
      case 'premium':
        return 'PREMIUM';
      case 'destaque':
        return 'DESTAQUE';
      case 'basico':
        return 'BÁSICO';
      default:
        return '';
    }
  }

  Future<void> _handleContact() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Incrementar contador de cliques
      await BusinessAdsService().incrementClicks(widget.ad['id']);

      // Abrir WhatsApp ou telefone
      final whatsapp = widget.ad['whatsapp'];
      if (whatsapp != null && whatsapp.isNotEmpty) {
        final phoneNumber = whatsapp.replaceAll(RegExp(r'[^\d]'), '');
        final message = Uri.encodeComponent('Olá, estou aqui pelo Dominus e gostaria de informações');
        final whatsappUrl = Uri.parse('https://wa.me/55$phoneNumber?text=$message');

        try {
          // Tentar abrir WhatsApp diretamente
          await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
        } catch (whatsappError) {
          // Se WhatsApp falhar, tentar ligação telefônica
          try {
            final telUrl = Uri.parse('tel:+55$phoneNumber');
            await launchUrl(telUrl);
          } catch (telError) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Não foi possível abrir WhatsApp nem fazer ligação'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir contato: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openWebsite() async {
    final website = widget.ad['website'];
    if (website != null && website.isNotEmpty) {
      try {
        await BusinessAdsService().incrementClicks(widget.ad['id']);

        final url = Uri.parse(website.startsWith('http') ? website : 'https://$website');
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao abrir website'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = widget.ad['plan_type'] == 'premium';
    final isDestaque = widget.ad['plan_type'] == 'destaque';
    final hasImage = widget.ad['image_url'] != null && widget.ad['image_url'].toString().isNotEmpty && widget.ad['image_url'].toString() != 'null';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isPremium ? 12 : isDestaque ? 8 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isPremium ? 16 : isDestaque ? 14 : 12),
        side: BorderSide(
          color: _getPlanColor().withValues(alpha: isPremium ? 0.5 : isDestaque ? 0.4 : 0.3),
          width: isPremium ? 3 : isDestaque ? 2 : 1,
        ),
      ),
      child: Container(
        decoration: isPremium
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.purple.shade50.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              )
            : isDestaque
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.orange.shade50.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              )
            : null,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(isPremium ? 16 : isDestaque ? 14 : 12),
          child: Padding(
            padding: EdgeInsets.all(isPremium ? 20 : isDestaque ? 18 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getPlanColor().withValues(alpha: isPremium ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getPlanColor().withValues(alpha: isPremium ? 0.6 : 0.3),
                      width: isPremium ? 2 : 1,
                    ),
                    boxShadow: isPremium || isDestaque
                        ? [
                            BoxShadow(
                              color: _getPlanColor().withValues(alpha: 0.2),
                              blurRadius: isPremium ? 8 : 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isPremium) ...[
                        const Icon(Icons.star, size: 16, color: Colors.purple),
                        const SizedBox(width: 4),
                      ] else if (isDestaque) ...[
                        const Icon(Icons.flash_on, size: 16, color: Colors.orange),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        _getPlanLabel(),
                        style: TextStyle(
                          color: _getPlanColor(),
                          fontSize: isPremium ? 14 : isDestaque ? 13 : 12,
                          fontWeight: isPremium ? FontWeight.bold : isDestaque ? FontWeight.w600 : FontWeight.w500,
                          letterSpacing: isPremium ? 1.2 : isDestaque ? 0.8 : 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (widget.ad['business_name'] != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.ad['business_name'],
                          style: TextStyle(
                            fontSize: isPremium ? 22 : isDestaque ? 20 : 18,
                            fontWeight: isPremium ? FontWeight.w900 : isDestaque ? FontWeight.w700 : FontWeight.bold,
                            color: isPremium ? Colors.purple.shade800 : isDestaque ? Colors.orange.shade800 : null,
                            letterSpacing: isPremium ? 0.5 : isDestaque ? 0.3 : null,
                          ),
                        ),
                      ),
                      if (widget.onDelete != null) ...[
                        IconButton(
                          onPressed: widget.onDelete,
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 20,
                          ),
                          tooltip: 'Excluir anúncio',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  children: [
                    if (widget.ad['category'] != null) ...[
                      Icon(Icons.category, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        widget.ad['category'],
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (widget.ad['city'] != null) ...[
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        widget.ad['city'],
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                if (widget.ad['creative_text'] != null) ...[
                  Text(
                    widget.ad['creative_text'],
                    style: const TextStyle(fontSize: 14, height: 1.4),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],
                if (hasImage) ...[
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.ad['image_url'],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) {
                            return child;
                          }
                          return Center(
                            child: CircularProgressIndicator(
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (!hasImage) const SizedBox(height: 12),
                if (widget.showStats) ...[
                  Row(
                    children: [
                      Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.ad['views_count'] ?? 0} visualizações',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.touch_app, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.ad['clicks_count'] ?? 0} cliques',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    if (widget.ad['whatsapp'] != null && widget.ad['whatsapp'].isNotEmpty) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _handleContact,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.message),
                          label: const Text('WhatsApp'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPremium ? Colors.green.shade600 : Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(isPremium ? 12 : 8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            minimumSize: const Size(0, 48),
                            elevation: isPremium ? 4 : 0,
                            shadowColor: isPremium ? Colors.green.shade200 : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (widget.ad['website'] != null && widget.ad['website'].isNotEmpty) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openWebsite,
                          icon: const Icon(Icons.web),
                          label: const Text('Website'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}