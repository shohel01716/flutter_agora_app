import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraConferenceScreen extends StatefulWidget {
  const AgoraConferenceScreen({super.key});

  @override
  State<AgoraConferenceScreen> createState() => _AgoraConferenceScreenState();
}

class _AgoraConferenceScreenState extends State<AgoraConferenceScreen> {
  final String appId = '2968e6d74e034c34b0dc6fa12f21c468';
  final String channelName = 'conference_room';
  final String token = '007eJxTYJjWO2f2ecPO8vaPbyXPlH60LV2S9oPDxd1TtfqNelHJyzwFBiNLM4tUsxRzk1QDY5NkY5Mkg5Rks7REQ6M0I8NkEzMLNc/QzIZARoaWv86sjAwQCOLzMyTn56WlFqXmJafGF+Xn5zIwAAAMKSQ8'; // Set to empty if token auth is disabled in Agora Console

  RtcEngine? _engine;
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isInitialized = false;
  int? _localUid;
  
  // Store remote users
  final Set<int> _remoteUsers = {};

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    try {
      await [Permission.microphone, Permission.camera].request();

      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: appId,
      ));

      debugPrint('Agora engine initialized');

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint('Local user joined: ${connection.localUid}');
            setState(() {
              _isJoined = true;
              _localUid = connection.localUid;
            });
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint('Remote user joined: $remoteUid');
            setState(() {
              _remoteUsers.add(remoteUid);
            });
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            debugPrint('Remote user offline: $remoteUid');
            setState(() {
              _remoteUsers.remove(remoteUid);
            });
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            debugPrint('Local user left channel');
            setState(() {
              _isJoined = false;
              _remoteUsers.clear();
            });
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('Agora Error: $err - $msg');
          },
        ),
      );

      await _engine!.enableVideo();
      await _engine!.enableLocalVideo(true);
      await _engine!.startPreview();

      setState(() {
        _isInitialized = true;
      });

      debugPrint('Agora conference initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Agora: $e');
      _showSnackBar('Failed to initialize: $e');
    }
  }

  Future<void> _joinChannel() async {
    if (!_isInitialized) {
      _showSnackBar('Initializing, please wait...');
      return;
    }

    if (_engine == null) {
      _showSnackBar('Engine not initialized');
      return;
    }

    try {
      debugPrint('Joining conference channel: $channelName');

      await _engine!.setChannelProfile(ChannelProfileType.channelProfileCommunication);
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

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
      _showSnackBar('Failed to join: $e');
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
        title: const Text('Agora Conference'),
        centerTitle: true,
        actions: [
          if (_isJoined)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  '${_remoteUsers.length + 1} participants',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
        ],
      ),
      body: _isInitialized
          ? _isJoined
              ? _buildConferenceView()
              : _buildJoinView()
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing...'),
                ],
              ),
            ),
    );
  }

  Widget _buildJoinView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.video_call, size: 100, color: Colors.blue),
          const SizedBox(height: 24),
          const Text(
            'Ready to join conference',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Channel: $channelName',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _joinChannel,
            icon: const Icon(Icons.video_call),
            label: const Text('Join Conference'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConferenceView() {
    return Stack(
      children: [
        // Video grid
        _buildVideoGrid(),

        // Bottom control bar
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  label: _isMuted ? 'Unmute' : 'Mute',
                  onPressed: _toggleMute,
                  color: _isMuted ? Colors.red : Colors.white,
                ),
                _buildControlButton(
                  icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoGrid() {
    final List<Widget> videoViews = [];

    // Add local video
    videoViews.add(_buildVideoTile(
      uid: _localUid ?? 0,
      isLocal: true,
    ));

    // Add remote videos
    for (final uid in _remoteUsers) {
      videoViews.add(_buildVideoTile(
        uid: uid,
        isLocal: false,
      ));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getGridColumns(videoViews.length),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: videoViews.length,
      itemBuilder: (context, index) => videoViews[index],
    );
  }

  int _getGridColumns(int participantCount) {
    if (participantCount <= 1) return 1;
    if (participantCount <= 4) return 2;
    return 3;
  }

  Widget _buildVideoTile({required int uid, required bool isLocal}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLocal ? Colors.blue : Colors.grey,
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: isLocal
                ? (_isCameraOff
                    ? _buildPlaceholder('Camera Off', Icons.videocam_off)
                    : AgoraVideoView(
                        controller: VideoViewController(
                          rtcEngine: _engine!,
                          canvas: const VideoCanvas(uid: 0),
                        ),
                      ))
                : AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: _engine!,
                      canvas: VideoCanvas(uid: uid),
                      connection: RtcConnection(channelId: channelName),
                    ),
                  ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isLocal && _isMuted ? Icons.mic_off : Icons.mic,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isLocal ? 'You' : 'User $uid',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String text, IconData icon) {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.white54),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
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
