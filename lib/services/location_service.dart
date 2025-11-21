import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:permission_handler/permission_handler.dart' as perm;

class LocationService with ChangeNotifier {
  LocationService._();
  static final LocationService _inst = LocationService._();
  static LocationService get I => _inst;

  bool _loading = false;
  bool get loading => _loading;
  String? _cidade; String? get cidade => _cidade;
  String? _uf; String? get uf => _uf;
  double? _lat; double? get lat => _lat;
  double? _lon; double? get lon => _lon;
  String? _erro; String? get erro => _erro;
  LocationPermission? _lastPermission; LocationPermission? get lastPermission => _lastPermission;

  bool get deniedForever => _lastPermission == LocationPermission.deniedForever;
  bool get deniedOnce => _lastPermission == LocationPermission.denied;

  Future<bool> requestPermissionWithRationale() async {
    LocationPermission status = await Geolocator.checkPermission();
    _lastPermission = status;
    if (status == LocationPermission.denied) {
      status = await Geolocator.requestPermission();
      _lastPermission = status;
    }
    if (status == LocationPermission.deniedForever) {
      _erro = 'Permissão negada permanentemente. Abra as configurações para habilitar.';
      notifyListeners();
      return false;
    }
    final ok = status == LocationPermission.always || status == LocationPermission.whileInUse;
    if(!ok){
      _erro = 'Permissão de localização não concedida.';
      notifyListeners();
    }
    return ok;
  }

  Future<void> openAppSettings() async {
    await perm.openAppSettings();
  }

  Future<bool> ensurePermission() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    _lastPermission = perm;
    if (perm == LocationPermission.deniedForever) {
      _erro = 'Permissão de localização permanentemente negada';
      notifyListeners();
      return false;
    }
    return perm == LocationPermission.always || perm == LocationPermission.whileInUse;
  }

  Future<void> fetch({bool force = false}) async {
    if (_loading) return; // evita chamadas concorrentes
    if (!force && _lat != null && _lon != null && _cidade != null && _uf != null) return;
    _loading = true; _erro = null; notifyListeners();
    try {
      final has = await ensurePermission();
      if (!has) { _loading = false; notifyListeners(); return; }
      Position pos;
      try {
        pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      } on MissingPluginException catch (_) {
        _erro = 'Localização não disponível neste build (plugin não registrado).';
        return;
      }
      _lat = pos.latitude; _lon = pos.longitude;
      final placemarks = await geo.placemarkFromCoordinates(_lat!, _lon!);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        // Alguns provedores retornam em administrativeArea / subAdministrativeArea
        final cidadeRaw = p.subAdministrativeArea?.isNotEmpty == true ? p.subAdministrativeArea : p.locality;
        final ufRaw = p.administrativeArea;
        if (cidadeRaw != null) {
          _cidade = cidadeRaw.split(RegExp(r'\s+')).map((w){final l=w.toLowerCase();return l.isEmpty?'' : l[0].toUpperCase()+l.substring(1);}).join(' ');
        }
        if (ufRaw != null && ufRaw.length <= 3) {
          _uf = ufRaw.toUpperCase();
        }
      }
    } catch (e) {
      _erro = 'Falha localização: $e';
    } finally {
      _loading = false; notifyListeners();
    }
  }
}
