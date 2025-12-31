import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraScreen extends StatefulWidget {
  const AgoraScreen({super.key});

  @override
  State<AgoraScreen> createState() => _AgoraScreenState();
}

class _AgoraScreenState extends State<AgoraScreen> {
  // Replace with your Agora App ID
  final String appId = '2968e6d74e034c34b0dc6fa12f21c468';
  final String channelName = 'test_channel';
  final String token = '007eJxTYBC87bSyoL3XuvLenAf3j7d3+n10O7JOwPBJWX7Z/Crpe0oKDEaWZhapZinmJqkGxibJxiZJBinJZmmJhkZpRobJJmYWGoqhmQ2BjAwhzqIsjAwQCOLzMJSkFpfEJ2ck5uWl5jAwAACGMCH+'; // Replace with fresh token from https://webdemo.agora.io/token-builder/

  RtcEngine? _engine;
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isCameraOff = false;
  int? _remoteUid;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    try {
      // Request permissions
      await [Permission.microphone, Permission.camera].request();

      // Create RTC engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: appId,
      ));

      debugPrint('Agora engine created and initialized');

      // Register event handlers
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint('Local user joined: ${connection.localUid}');
            setState(() {
              _isJoined = true;
            });
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint('Remote user joined: $remoteUid');
            setState(() {
              _remoteUid = remoteUid;
            });
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            debugPrint('Remote user offline: $remoteUid');
            setState(() {
              _remoteUid = null;
            });
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            debugPrint('Local user left channel');
            setState(() {
              _isJoined = false;
              _remoteUid = null;
            });
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('Agora Error: $err - $msg');
          },
        ),
      );

      debugPrint('Event handlers registered');

      // Enable video module
      await _engine!.enableVideo();
      debugPrint('Video enabled');
      
      // Enable local video
      await _engine!.enableLocalVideo(true);
      debugPrint('Local video enabled');
      
      // Start preview
      await _engine!.startPreview();
      debugPrint('Preview started');

      setState(() {
        _isInitialized = true;
      });
      
      debugPrint('Agora engine initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Agora: $e');
      _showSnackBar('Failed to initialize Agora: $e');
    }
  }

  Future<void> _joinChannel() async {
    if (!_isInitialized) {
      _showSnackBar('Initializing Agora engine, please wait...');
      return;
    }
    
    if (_engine == null) {
      _showSnackBar('Agora engine not initialized');
      return;
    }

    try {
      debugPrint('Setting channel profile and client role...');
      
      // Set channel profile
      await _engine!.setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
      
      // Set client role to broadcaster
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      
      debugPrint('Joining channel: $channelName with token: ${token.substring(0, 20)}...');
      debugPrint('Using UID: 0');
      
      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
      
      debugPrint('Join channel call completed');
    } catch (e) {
      debugPrint('Error joining channel: $e');
      _showSnackBar('Token may be expired or invalid. Generate a new token for channel "$channelName" and UID 0');
    }
  }

  Future<void> _leaveChannel() async {
    await _engine?.leaveChannel();
  }

  Future<void> _toggleMute() async {
    setState(() {
      _isMuted = !_isMuted;
    });
    await _engine?.muteLocalAudioStream(_isMuted);
  }

  Future<void> _toggleCamera() async {
    setState(() {
      _isCameraOff = !_isCameraOff;
    });
    await _engine?.muteLocalVideoStream(_isCameraOff);
  }

  Future<void> _switchCamera() async {
    await _engine?.switchCamera();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agora Live Streaming'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Video views
          _isJoined
              ? _remoteUid != null
                  ? _remoteVideo()
                  : const Center(
                      child: Text(
                        'Waiting for remote user to join...',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
              : Center(
                  child: _isInitialized
                      ? const Text(
                          'Join a channel to start',
                          style: TextStyle(fontSize: 18),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Initializing Agora...',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                ),

          // Local preview (small window)
          if (_isJoined)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: _isCameraOff
                      ? Container(
                          color: Colors.black,
                          child: const Center(
                            child: Icon(Icons.videocam_off, color: Colors.white),
                          ),
                        )
                      : AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: _engine!,
                            canvas: const VideoCanvas(uid: 0),
                          ),
                        ),
                ),
              ),
            ),

          // Control buttons
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Channel info
                  if (_isJoined)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Channel: $channelName',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Control buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (_isJoined) ...[
                        _buildControlButton(
                          icon: _isMuted ? Icons.mic_off : Icons.mic,
                          label: _isMuted ? 'Unmute' : 'Mute',
                          onPressed: _toggleMute,
                          color: _isMuted ? Colors.red : Colors.white,
                        ),
                        _buildControlButton(
                          icon: _isCameraOff
                              ? Icons.videocam_off
                              : Icons.videocam,
                          label: _isCameraOff ? 'Camera On' : 'Camera Off',
                          onPressed: _toggleCamera,
                          color: _isCameraOff ? Colors.red : Colors.white,
                        ),
                        _buildControlButton(
                          icon: Icons.cameraswitch,
                          label: 'Switch',
                          onPressed: _switchCamera,
                        ),
                        _buildControlButton(
                          icon: Icons.call_end,
                          label: 'Leave',
                          onPressed: _leaveChannel,
                          color: Colors.red,
                        ),
                      ] else
                        ElevatedButton.icon(
                          onPressed: _joinChannel,
                          icon: const Icon(Icons.video_call),
                          label: const Text('Join Channel'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine!,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: channelName),
        ),
      );
    } else {
      return const Center(
        child: Text(
          'Waiting for remote user...',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          iconSize: 32,
          color: color ?? Colors.white,
          style: IconButton.styleFrom(
            backgroundColor: Colors.black54,
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
