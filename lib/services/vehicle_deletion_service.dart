import 'package:supabase_flutter/supabase_flutter.dart';

class VehicleDeletionService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Exclui um anúncio completamente, incluindo imagens do storage
  static Future<bool> deleteVehicle(String vehicleId) async {
    try {
      // Primeiro, buscar os dados do veículo para obter as URLs das imagens
      final vehicleResponse = await _client
          .from('veiculos')
          .select('fotos, fotos_thumb')
          .eq('id', vehicleId)
          .single();

      if (vehicleResponse.isEmpty) {
        throw Exception('Veículo não encontrado');
      }

      final vehicleData = vehicleResponse as Map<String, dynamic>;
      final fotos = vehicleData['fotos'] as List<dynamic>? ?? [];
      final fotosThumb = vehicleData['fotos_thumb'] as List<dynamic>? ?? [];

      // Excluir imagens do storage
      await _deleteImagesFromStorage(fotos.cast<String>());
      await _deleteImagesFromStorage(fotosThumb.cast<String>());

      // Excluir registro do banco de dados
      await _client.from('veiculos').delete().eq('id', vehicleId);

      return true;
    } catch (e) {
      print('Erro ao excluir veículo: $e');
      rethrow;
    }
  }

  /// Exclui múltiplas imagens do Supabase Storage
  static Future<void> _deleteImagesFromStorage(List<String> imageUrls) async {
    if (imageUrls.isEmpty) return;

    try {
      // Extrair os caminhos dos arquivos das URLs
      final filePaths = imageUrls.map((url) {
        // URL típica: https://[project].supabase.co/storage/v1/object/public/fotos/anuncios/[filename]
        final uri = Uri.parse(url);
        final pathSegments = uri.pathSegments;

        // Encontrar o índice de 'fotos' e pegar tudo depois dele
        final fotosIndex = pathSegments.indexOf('fotos');
        if (fotosIndex != -1 && fotosIndex < pathSegments.length - 1) {
          return pathSegments.sublist(fotosIndex + 1).join('/');
        }

        // Fallback: tentar extrair do path
        final path = uri.path;
        final fotosPathIndex = path.indexOf('/fotos/');
        if (fotosPathIndex != -1) {
          return path.substring(fotosPathIndex + 7); // +7 para pular '/fotos/'
        }

        return null;
      }).where((path) => path != null).cast<String>().toList();

      if (filePaths.isNotEmpty) {
        // Excluir arquivos do storage
        await _client.storage.from('fotos').remove(filePaths);
        print('Imagens excluídas do storage: ${filePaths.length}');
      }
    } catch (e) {
      print('Erro ao excluir imagens do storage: $e');
      // Não lançar erro aqui para não impedir a exclusão do registro
      // As imagens órfãs podem ser limpas posteriormente
    }
  }

  /// Limpa imagens órfãs do storage (imagens sem veículo associado)
  static Future<int> cleanupOrphanedImages() async {
    try {
      // Listar todos os arquivos no bucket 'fotos'
      final files = await _client.storage.from('fotos').list(path: 'anuncios');

      if (files.isEmpty) return 0;

      // Coletar todas as URLs de imagens ativas dos veículos
      final vehiclesResponse = await _client
          .from('veiculos')
          .select('fotos, fotos_thumb');

      final activeImageUrls = <String>{};

      for (final vehicle in vehiclesResponse) {
        final fotos = vehicle['fotos'] as List<dynamic>? ?? [];
        final fotosThumb = vehicle['fotos_thumb'] as List<dynamic>? ?? [];

        activeImageUrls.addAll(fotos.cast<String>());
        activeImageUrls.addAll(fotosThumb.cast<String>());
      }

      // Identificar imagens órfãs
      final orphanedPaths = <String>[];

      for (final file in files) {
        final filePath = 'anuncios/${file.name}';
        final publicUrl = _client.storage.from('fotos').getPublicUrl(filePath);

        if (!activeImageUrls.contains(publicUrl)) {
          orphanedPaths.add(filePath);
        }
      }

      // Excluir imagens órfãs
      if (orphanedPaths.isNotEmpty) {
        await _client.storage.from('fotos').remove(orphanedPaths);
        print('Imagens órfãs removidas: ${orphanedPaths.length}');
      }

      return orphanedPaths.length;
    } catch (e) {
      print('Erro na limpeza de imagens órfãs: $e');
      return 0;
    }
  }
}