import 'package:agora_token_service/agora_token_service.dart';

String generateAgoraToken({
  required String appId,
  required String appCertificate,
  required String channelName,
  required String uid,
  required RtcRole role,
  int expirationInSeconds = 3600,
}) {
  final currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final expireTimestamp = currentTimestamp + expirationInSeconds;

  final token = RtcTokenBuilder.build(
    appId: appId,
    appCertificate: appCertificate,
    channelName: channelName,
    uid: uid,
    role: role,
    expireTimestamp: expireTimestamp,
  );

  return token;
}
