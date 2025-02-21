import 'package:loggy/loggy.dart';
import 'package:vdb_secure_token/vdb_secure_token.dart';

class PushService {
  static final loggy = Loggy<VdbLogger>('PushService');

  static String handle({
    required PlatformsEnum platform,
    required Map<String, dynamic> pushData,
  }) {
    loggy.info("Handling push data to extract auth code");
    String secureAuthCode;
    String authCode;
    switch (platform) {
      case PlatformsEnum.fcm:
        secureAuthCode = pushData["authCode"];
        break;
      case PlatformsEnum.hpk:
        secureAuthCode = pushData["authCode"];
        break;
    }

    loggy.info("Secure auth code: $secureAuthCode, it will be handled using secure version: ${VdbConstants.version}");
    switch (VdbConstants.version) {
      case "1":
        authCode = secureAuthCode;
        break;
      default:
        throw Exception("Secure version unknown");
    }

    loggy.info("Auth code successfully extracted");
    return authCode;
  }
}
