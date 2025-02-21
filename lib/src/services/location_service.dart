import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:google_huawei_availability/google_huawei_availability.dart';
import 'package:huawei_location/huawei_location.dart';
import 'package:loggy/loggy.dart';
import 'package:vdb_secure_token/vdb_secure_token.dart';

class LocationService {
  static final loggy = Loggy<VdbLogger>('LocationService');
  static FusedLocationProviderClient hmsLocation = FusedLocationProviderClient();

  static Future<bool> googlePlayAvailable() async {
    if (Platform.isIOS) return true;

    return await GoogleHuaweiAvailability.isGoogleServiceAvailable ?? false;
  }

  static void init() async {
    if (await googlePlayAvailable() == false) {
      loggy.info("Huawei device detected, starting location service");
      hmsLocation.initFusedLocationService();
    }
  }

  static Future<bool> isLocationServiceEnabled() async {
    bool gpsEnabled = false;

    if (await googlePlayAvailable()) {
      gpsEnabled = await Geolocator.isLocationServiceEnabled();
    } else {
      var state = await hmsLocation.checkLocationSettings(LocationSettingsRequest());
      gpsEnabled = state.gpsUsable;
    }

    return gpsEnabled;
  }

  static Future<LocationPermission> checkPermission() async {
    //checking permissions do not need hms or gms
    return await Geolocator.checkPermission();
  }

  static Future<LocationPermission> requestPermission() async {
    //requesting permissions do not need hms or gms
    return await Geolocator.requestPermission();
  }

  static Future<Position> getCurrentPosition(Duration locationTimeLimit) async {
    if (await googlePlayAvailable()) {
      return await Geolocator.getCurrentPosition(
        timeLimit: locationTimeLimit,
      );
    } else {
      Location currentPosition = Location();
      await hmsLocation.requestLocationUpdates(LocationRequest()).then((value) async {
        currentPosition = await hmsLocation.getLastLocation();
      });
      return Position(
          longitude: currentPosition.longitude!,
          latitude: currentPosition.latitude!,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0);
    }
  }
}
