import 'package:flutter/material.dart';
import 'package:tencent_trtc_cloud/trtc_cloud.dart';
import 'package:tencent_trtc_cloud/trtc_cloud_def.dart';
import 'package:tencent_trtc_cloud/trtc_cloud_video_view.dart';
import 'package:permission_handler/permission_handler.dart';

class TencentScreen extends StatefulWidget {
  const TencentScreen({super.key});

  @override
  State<TencentScreen> createState() => _TencentScreenState();
}

class _TencentScreenState extends State<TencentScreen> {
  // Replace with your Tencent App ID and UserSig
  final int sdkAppId = 20032063; // Your SDK App ID
  final String userId = 'test_user_001'; // Use this exact ID to generate UserSig
  final String roomId = '12345';
  final String userSig = 'eJwtzF0LgjAYBeD-suvQ163ND*gmKcKkDzIwEETZqpcolpsRRP89Uy-Pcw7nQ7L04LxUQyJCHSCTPqNUD4tn7NkqY8vWqKYE8MaBkbdKa5QkogCMgmCDq7fGRpHI45x3DQxq8f43X-heyEMIxg*8dO-TdSur*rRNsng130u9LNxN4dKsFqxwTRJfU7Z75jSI84VIjjPy-QEqrDNk'; // Generate from: https://console.cloud.tencent.com/trtc

  TRTCCloud? _trtcCloud;
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isCameraOff = false;
  String? _remoteUserId;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initTRTC();
  }

  Future<void> _initTRTC() async {
    // Request permissions
    await [Permission.microphone, Permission.camera].request();

    // Get TRTC instance
    _trtcCloud = await TRTCCloud.sharedInstance();

    // Register event listeners
    _trtcCloud?.registerListener(_onTRTCListener);

    // Enable local audio first
    await _trtcCloud?.startLocalAudio(TRTCCloudDef.TRTC_AUDIO_QUALITY_DEFAULT);

    setState(() {
      _isInitialized = true;
    });

    debugPrint('TRTC initialized');
  }

  void _onTRTCListener(type, params) {
    debugPrint('TRTC Event: $type, params: $params');
    debugPrint('Event type class: ${type.runtimeType}');
    
    // Handle different event types based on string keys
    if (type.toString().contains('onEnterRoom')) {
      if (params > 0) {
        debugPrint('Enter room success - setting _isJoined = true');
        setState(() {
          _isJoined = true;
        });
      } else {
        debugPrint('Enter room failed: $params');
        _showSnackBar('Failed to join room');
      }
    } else if (type.toString().contains('onExitRoom')) {
      debugPrint('Exit room: $params');
      setState(() {
        _isJoined = false;
        _remoteUserId = null;
      });
    } else if (type.toString().contains('onRemoteUserEnterRoom')) {
      debugPrint('Remote user entered: $params');
      setState(() {
        _remoteUserId = params;
      });
    } else if (type.toString().contains('onRemoteUserLeaveRoom')) {
      debugPrint('Remote user left: $params');
      setState(() {
        _remoteUserId = null;
      });
    } else if (type.toString().contains('onUserVideoAvailable')) {
      debugPrint('User video available: $params');
      if (params is Map && params['available'] == true) {
        setState(() {
          _remoteUserId = params['userId'];
        });
      }
    } else if (type.toString().contains('onError')) {
      debugPrint('Error: $params');
      if (params is Map) {
        _showSnackBar('Error: ${params['errMsg'] ?? 'Unknown error'}');
      }
    }
  }

  Future<void> _enterRoom() async {
    if (sdkAppId == 0) {
      _showSnackBar('Please configure your Tencent SDK App ID');
      return;
    }

    // Set video encoding parameters
    TRTCVideoEncParam encParam = TRTCVideoEncParam(
      videoResolution: TRTCCloudDef.TRTC_VIDEO_RESOLUTION_960_540,
      videoBitrate: 1200,
      videoFps: 15,
    );
    await _trtcCloud?.setVideoEncoderParam(encParam);

    // Enter room
    TRTCParams params = TRTCParams(
      sdkAppId: sdkAppId,
      userId: userId,
      userSig: userSig,
      roomId: int.parse(roomId),
      role: TRTCCloudDef.TRTCRoleAnchor,
    );

    await _trtcCloud?.enterRoom(params, TRTCCloudDef.TRTC_APP_SCENE_LIVE);
    debugPrint('Entering room...');
  }

  Future<void> _exitRoom() async {
    await _trtcCloud?.exitRoom();
  }

  Future<void> _toggleMute() async {
    setState(() {
      _isMuted = !_isMuted;
    });
    await _trtcCloud?.muteLocalAudio(_isMuted);
  }

  Future<void> _toggleCamera() async {
    setState(() {
      _isCameraOff = !_isCameraOff;
    });
    await _trtcCloud?.muteLocalVideo(_isCameraOff);
  }

  Future<void> _switchCamera() async {
    await _trtcCloud?.getDeviceManager().switchCamera(true);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _trtcCloud?.unRegisterListener(_onTRTCListener);
    _trtcCloud?.exitRoom();
    _trtcCloud?.stopLocalPreview();
    _trtcCloud?.stopLocalAudio();
    TRTCCloud.destroySharedInstance();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tencent RTC Streaming'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Main video view - show local preview when joined
          if (_isJoined)
            TRTCCloudVideoView(
              viewType: TRTCCloudDef.TRTC_VideoView_TextureView,
              onViewCreated: (viewId) async {
                debugPrint('Main video view created with viewId: $viewId');
                if (_remoteUserId != null) {
                  // Show remote user if available
                  await _trtcCloud?.startRemoteView(
                    _remoteUserId!,
                    TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_BIG,
                    viewId,
                  );
                } else {
                  // Show local preview in main view
                  await _trtcCloud?.startLocalPreview(true, viewId);
                }
              },
            )
          else
            const Center(
              child: Text(
                'Join a room to start',
                style: TextStyle(fontSize: 18),
              ),
            ),

          // Local preview (small window)
          if (_isJoined && _isInitialized)
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
                      : TRTCCloudVideoView(
                          viewType: TRTCCloudDef.TRTC_VideoView_TextureView,
                          onViewCreated: (viewId) async {
                            debugPrint('Local view created with viewId: $viewId');
                            await _trtcCloud?.startLocalPreview(true, viewId);
                          },
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
                  // Room info
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
                        'Room: $roomId | User: $userId',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
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
                          onPressed: _exitRoom,
                          color: Colors.red,
                        ),
                      ] else
                        ElevatedButton.icon(
                          onPressed: _enterRoom,
                          icon: const Icon(Icons.video_call),
                          label: const Text('Join Room'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            backgroundColor: Colors.teal,
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
