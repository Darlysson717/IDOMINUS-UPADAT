import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateService {
  static const String updateUrl = 'https://raw.githubusercontent.com/Darlysson717/IDOMINUS-UPADAT/main/update.json'; // Substitua pela sua URL

  static Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      print('🌐 Fazendo requisição para: $updateUrl');
      final response = await Dio().get(
        updateUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      print('📊 Status da resposta: ${response.statusCode}');

      if (response.statusCode == 200) {
        final bytes = response.data as List<int>;
        // Remove BOM if present (EF BB BF)
        List<int> cleanBytes = bytes;
        if (bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
          cleanBytes = bytes.sublist(3);
        }
        final raw = utf8.decode(cleanBytes);
        print('📄 Raw data type: ${raw.runtimeType}');
        print('📄 Raw data length: ${raw.length}');
        print('📄 First 20 chars (raw): ${raw.substring(0, min(20, raw.length))}');
        Map<String, dynamic> data = json.decode(raw) as Map<String, dynamic>;
        print('✅ JSON decodificado com sucesso: $data');
        return data;
      } else {
        print('❌ Status code diferente de 200: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Erro ao verificar atualização: $e');
    }
    return null;
  }

  static Future<bool> isUpdateAvailable() async {
    final updateInfo = await checkForUpdate();
    if (updateInfo == null) return false;

    final currentVersion = await getCurrentVersion();
    final newVersion = updateInfo['version'];

    return compareVersions(currentVersion, newVersion) < 0;
  }

  static Future<String> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final version = packageInfo.version;
    print('📱 Versão atual: $version');
    return version;
  }

  static int compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.parse).toList();
    final parts2 = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < parts1.length && i < parts2.length; i++) {
      if (parts1[i] < parts2[i]) return -1;
      if (parts1[i] > parts2[i]) return 1;
    }
    return parts1.length.compareTo(parts2.length);
  }

  static Future<void> downloadAndInstallUpdate(
    String apkUrl, {
    Function(double)? onProgress,
    Function(String)? onStatus,
    Function()? onDownloadComplete,
  }) async {
    try {
      // Usar getApplicationDocumentsDirectory() ao invés de getExternalStorageDirectory()
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/app-release.apk';

      print('📥 Baixando APK de: $apkUrl');
      print('💾 Salvando em: $filePath');

      onStatus?.call('Baixando atualização...');

      final response = await Dio().download(
        apkUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100);
            print('📊 Progresso: ${progress.toStringAsFixed(1)}%');
            onProgress?.call(progress);
          }
        },
      );

      if (response.statusCode == 200) {
        print('✅ Download concluído com sucesso!');
        onDownloadComplete?.call();

        // Verificar se o arquivo foi criado
        final file = File(filePath);
        final exists = await file.exists();
        final size = await file.length();

        print('📁 Arquivo existe: $exists');
        print('📏 Tamanho: ${size} bytes');

        if (exists && size > 0) {
          print('🚀 Iniciando instalação...');

          // Método 1: Tentar usar OpenFile (pode funcionar em algumas versões)
          try {
            final result = await OpenFile.open(filePath);
            print('📱 OpenFile result: ${result.type} - ${result.message}');

            if (result.type == ResultType.done) {
              print('✅ APK instalado com sucesso via OpenFile');
              return;
            }
          } catch (e) {
            print('⚠️ OpenFile falhou: $e');
          }

          // Método 2: Mostrar diálogo com instruções para instalação manual
          print('📋 Preparando instalação manual...');
          await _showManualInstallDialog(apkUrl, filePath);

        } else {
          throw Exception('Arquivo APK não foi criado corretamente');
        }
      } else {
        throw Exception('Erro no download: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro ao baixar/instalar atualização: $e');
      rethrow;
    }
  }

  static Future<void> _showManualInstallDialog(String apkUrl, String filePath) async {
    // Este método será chamado de um contexto com BuildContext
    // Por enquanto, vamos apenas logar as instruções
    print('📋 INSTRUÇÕES PARA INSTALAÇÃO MANUAL:');
    print('1. Vá para Configurações > Apps');
    print('2. Habilite "Instalar apps desconhecidos" para este app');
    print('3. Abra o explorador de arquivos');
    print('4. Navegue até: ${File(filePath).parent.path}');
    print('5. Toque no arquivo app-release.apk');
    print('6. Siga as instruções na tela para instalar');
    print('');
    print('🔗 Ou baixe diretamente de: $apkUrl');

    // Lançar uma exceção específica para que a UI possa mostrar um diálogo
    throw Exception('INSTALL_MANUAL_REQUIRED');
  }
}