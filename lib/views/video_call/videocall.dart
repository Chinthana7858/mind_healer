import 'package:agora_token_service/agora_token_service.dart';
import 'package:agora_uikit/agora_uikit.dart';
import 'package:flutter/material.dart';
import 'package:mind_healer/const/agora_credentials.dart';
import 'package:mind_healer/service/token_generator.dart';

class VideoCall extends StatefulWidget {
  final String channelName;
  const VideoCall({super.key, required this.channelName});

  @override
  State<VideoCall> createState() => _VideoCallState();
}

class _VideoCallState extends State<VideoCall> {
  AgoraClient? client;
  final String appId = AgoraCredentials.appId;
  final String appCertificate = AgoraCredentials.appCertificate;
  final int uid = 0; // Use 0 if you do not use a specific user ID
  final RtcRole role = RtcRole.publisher;

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  Future<void> initAgora() async {
    final token = generateAgoraToken(
      appId: appId,
      appCertificate: appCertificate,
      channelName: widget.channelName,
      uid: '0',
      role: role,
    );

    setState(() {
      client = AgoraClient(
        agoraConnectionData: AgoraConnectionData(
          appId: appId,
          channelName: widget.channelName,
          tempToken: token,
        ),
        enabledPermission: [
          Permission.camera,
          Permission.microphone,
        ],
      );
    });

    await client!.initialize();
  }

  @override
  void dispose() {
    client?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              client != null
                  ? AgoraVideoViewer(
                      client: client!,
                      layoutType: Layout.oneToOne,
                    )
                  : const Center(child: CircularProgressIndicator()),
              client != null
                  ? AgoraVideoButtons(
                      client: client!,
                      onDisconnect: () => Navigator.pop(context),
                      addScreenSharing: false)
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}
