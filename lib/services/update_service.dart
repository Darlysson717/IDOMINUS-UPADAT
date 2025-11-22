import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class UpdateService {
  static const String updateUrl = 'https://raw.githubusercontent.com/Darlysson717/IDOMINUS-UPADAT/main/update.json'; // Substitua pela sua URL

  static Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      final response = await Dio().get(updateUrl);
      if (response.statusCode == 200) {
        return json.decode(response.data);
      }
    } catch (e) {
      print('Erro ao verificar atualização: $e');
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
    return packageInfo.version;
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

  static Future<void> downloadAndInstallUpdate(String apkUrl) async {
    try {
      final dir = await getExternalStorageDirectory() ?? await getTemporaryDirectory();
      final filePath = '${dir.path}/app-release.apk';

      print('Baixando APK de: $apkUrl para: $filePath');

      final response = await Dio().download(apkUrl, filePath);
      if (response.statusCode == 200) {
        print('Download concluído. Tentando instalar APK...');

        // Tentar abrir/instalar o APK
        final result = await OpenFile.open(filePath);
        print('Resultado da abertura: ${result.type} - ${result.message}');

        if (result.type != ResultType.done) {
          print('OpenFile falhou, tentando método alternativo...');
          // Método alternativo: mostrar mensagem para o usuário instalar manualmente
          throw Exception('Não foi possível instalar automaticamente. Baixe o APK manualmente de: $apkUrl');
        }
      } else {
        throw Exception('Erro no download: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao baixar/instalar atualização: $e');
      rethrow;
    }
  }
}