import 'package:flutter_test/flutter_test.dart';
import 'package:dominus/services/update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UpdateService Tests', () {
    test('compareVersions should return correct comparison', () {
      expect(UpdateService.compareVersions('1.0.5', '1.0.6'), -1);
      expect(UpdateService.compareVersions('1.0.6', '1.0.5'), 1);
      expect(UpdateService.compareVersions('1.0.5', '1.0.5'), 0);
      expect(UpdateService.compareVersions('1.0.10', '1.0.2'), 1);
      expect(UpdateService.compareVersions('2.0.0', '1.9.9'), 1);
    });

    // Note: Network tests are disabled in TestWidgetsFlutterBinding
    // To test checkForUpdate, would need to mock Dio or use integration tests
    // test('checkForUpdate should fetch data from GitHub', () async {
    //   final updateInfo = await UpdateService.checkForUpdate();
    //   expect(updateInfo, isNotNull);
    //   expect(updateInfo!['version'], isNotNull);
    //   expect(updateInfo['apk_url'], isNotNull);
    //   expect(updateInfo['changelog'], isNotNull);
    // });

    // test('isUpdateAvailable should detect version difference', () async {
    //   final available = await UpdateService.isUpdateAvailable();
    //   expect(available, isTrue);
    // });
  });
}