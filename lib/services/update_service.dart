import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static const String updateUrl = 'https://raw.githubusercontent.com/Darlysson717/IDOMINUS-UPADAT/main/update.json'; // Substitua pela sua URL

  static Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      final response = await Dio().get(
        updateUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        final bytes = response.data as List<int>;
        // Remove BOM if present (EF BB BF)
        List<int> cleanBytes = bytes;
        if (bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
          cleanBytes = bytes.sublist(3);
        }
        final raw = utf8.decode(cleanBytes);
        Map<String, dynamic> data = json.decode(raw) as Map<String, dynamic>;
        return data;
      }
    } catch (e) {
      // Silent fail
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
    String updateUrl, {
    Function(double)? onProgress,
    Function(String)? onStatus,
    Function()? onDownloadComplete,
  }) async {
    print('🔗 Abrindo página de atualização: $updateUrl');
    onStatus?.call('Abrindo página de atualização...');
    await openUpdateLink(updateUrl);
    onDownloadComplete?.call();
  }

  static Future<void> openUpdateLink(String updateUrl) async {
    final uri = Uri.parse(updateUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Não foi possível abrir o link de atualização');
    }
  }
}