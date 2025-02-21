import 'package:flutter/foundation.dart';
import 'package:vdb_secure_token/src/enums/platforms_enum.dart';

class SecurePayloadDto {
  String? pushToken;
  String? deviceID;
  String? deviceOS;
  String? deviceInfo;
  double? latitude;
  double? longitude;
  bool? gpsPermission;
  bool? gpsActive;
  PlatformsEnum? platform;

  Map<String, dynamic> toJson() => {
        'pushToken': pushToken,
        'deviceID': deviceID,
        'deviceOS': deviceOS,
        'deviceInfo': deviceInfo,
        'latitude': latitude,
        'longitude': longitude,
        'gpsPermission': gpsPermission,
        'gpsActive': gpsActive,
        'platform': describeEnum(platform.toString()),
      };
}
