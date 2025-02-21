import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:loggy/loggy.dart';
import 'package:pointycastle/export.dart';
import 'package:vdb_secure_token/src/services/location_service.dart';
import 'package:vdb_secure_token/vdb_secure_token.dart';

class DeviceService {
  static final loggy = Loggy<VdbLogger>('DeviceService');

  static Future<String> getSecurePayload({
    required PlatformsEnum platform,
    required String pushToken,
    required bool locationMandatory,
    required Duration locationTimeLimit,
  }) async {
    var securePayloadDto = SecurePayloadDto();
    securePayloadDto.pushToken = pushToken;
    securePayloadDto.platform = platform;

    loggy.info("Loading device info");
    final deviceInfoPlugin = DeviceInfoPlugin();

    if (Platform.isIOS) {
      loggy.info("iOS device detected");
      final deviceInfoRaw = await deviceInfoPlugin.iosInfo;
      loggy.debug("iOS device info: $deviceInfoRaw");
      securePayloadDto.deviceID = deviceInfoRaw.identifierForVendor;
      securePayloadDto.deviceOS = deviceInfoRaw.systemVersion;
      securePayloadDto.deviceInfo = "Apple - ${deviceInfoRaw.name}";
    } else {
      loggy.info("Android device detected");
      final deviceInfoRaw = await deviceInfoPlugin.androidInfo;
      loggy.debug("Android device info: $deviceInfoRaw");
      securePayloadDto.deviceID = deviceInfoRaw.id;
      securePayloadDto.deviceOS = deviceInfoRaw.version.release;
      securePayloadDto.deviceInfo = '${deviceInfoRaw.brand} - ${deviceInfoRaw.model}';
    }

    LocationService.init();

    securePayloadDto.gpsActive = await LocationService.isLocationServiceEnabled();

    if (locationMandatory && !securePayloadDto.gpsActive!) {
      throw VDBLocationException('Location service is not enabled. Cannot continue because locationMandatory is true');
    }

    var gpsPermission = await LocationService.checkPermission();
    if (gpsPermission == LocationPermission.denied) {
      gpsPermission = await LocationService.requestPermission();
    }

    securePayloadDto.gpsPermission =
        gpsPermission == LocationPermission.always || gpsPermission == LocationPermission.whileInUse;

    if (locationMandatory && !securePayloadDto.gpsPermission!) {
      throw VDBLocationException('Location permission denied. Cannot continue because locationMandatory is true');
    }

    Position position;
    try {
      position = await LocationService.getCurrentPosition(locationTimeLimit);
      securePayloadDto.latitude = position.latitude;
      securePayloadDto.longitude = position.longitude;
    } catch (ex) {
      loggy.error('There was an error getting current location', ex);
    }

    securePayloadDto.latitude ??= 0;
    securePayloadDto.longitude ??= 0;

    loggy.info("Device info loaded");

    loggy.info("Securing device info using version: ${VdbConstants.version}");
    switch (VdbConstants.version) {
      case "1":
        final aes = AESEngine();
        final cbc = CBCBlockCipher(aes)
          ..init(
            true,
            ParametersWithIV(
              KeyParameter(createUint8ListFromHexString(ConfigService.key)),
              createUint8ListFromHexString(ConfigService.initVector),
            ),
          );

        Uint8List textBytes = createUint8ListFromString(jsonEncode(securePayloadDto.toJson()));
        Uint8List paddedText = pad(textBytes, aes.blockSize);
        Uint8List cipherBytes = processBlocks(cbc, paddedText);

        final securePayload = base64Encode(cipherBytes);
        loggy.info("Secure payload: $securePayload");
        return securePayload;
      default:
        throw VDBException("Secure version unknown");
    }
  }

  static Uint8List createUint8ListFromHexString(String hex) {
    var result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      var num = hex.substring(i, i + 2);
      var byte = int.parse(num, radix: 16);
      result[i ~/ 2] = byte;
    }
    return result;
  }

  static Uint8List createUint8ListFromString(String s) {
    var ret = Uint8List(s.length);
    for (var i = 0; i < s.length; i++) {
      ret[i] = s.codeUnitAt(i);
    }
    return ret;
  }

  static Uint8List pad(Uint8List src, int blockSize) {
    var pad = PKCS7Padding();
    pad.init(null);

    int padLength = blockSize - (src.length % blockSize);
    var out = Uint8List(src.length + padLength)..setAll(0, src);
    pad.addPadding(out, src.length);

    return out;
  }

  static Uint8List processBlocks(BlockCipher cipher, Uint8List inp) {
    var out = Uint8List(inp.lengthInBytes);

    for (var offset = 0; offset < inp.lengthInBytes;) {
      var len = cipher.processBlock(inp, offset, out, offset);
      offset += len;
    }

    return out;
  }
}
