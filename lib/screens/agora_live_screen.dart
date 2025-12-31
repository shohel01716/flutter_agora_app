import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraLiveScreen extends StatefulWidget {
  const AgoraLiveScreen({super.key});

  @override
  State<AgoraLiveScreen> createState() => _AgoraLiveScreenState();
}

class _AgoraLiveScreenState extends State<AgoraLiveScreen> {
  final String appId = '2968e6d74e034c34b0dc6fa12f21c468';
  final String channelName = 'live_room';
  final String token = '007eJxTYKjevtlVOPffzFUai5eyiyTwbmRh02Y7JWytkXRk6bfGJi4FBiNLM4tUsxRzk1QDY5NkY5Mkg5Rks7REQ6M0I8NkEzOL8pDQzIZARobb2fGsjAwQCOJzMuRklqXGF+Xn5zIwAAD3MB5e'; // Set to empty if token auth is disabled

  RtcEngine? _engine;
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isInitialized = false;
  bool _isHost = false; // Host or Audience
  int? _localUid;
  
  // Remote users and co-hosts
  final Set<int> _remoteUsers = {};
  final Set<int> _coHosts = {};
  
  // Live room stats
  int _viewerCount = 1;
  int _likesCount = 0;
  final List<String> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Show dialog after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showRoleSelectionDialog();
    });
  }

  void _showRoleSelectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Join Live Room'),
        content: const Text('Choose your role:'),
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                _isHost = false;
              });
              Navigator.pop(context);
              _initAgora();
            },
            icon: const Icon(Icons.people),
            label: const Text('Join as Audience'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isHost = true;
              });
              Navigator.pop(context);
              _initAgora();
            },
            icon: const Icon(Icons.videocam),
            label: const Text('Start as Host'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
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
              _viewerCount++;
            });
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            debugPrint('Remote user offline: $remoteUid');
            setState(() {
              _remoteUsers.remove(remoteUid);
              _coHosts.remove(remoteUid);
              _viewerCount--;
            });
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            debugPrint('Local user left channel');
            setState(() {
              _isJoined = false;
              _remoteUsers.clear();
              _coHosts.clear();
            });
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('Agora Error: $err - $msg');
          },
        ),
      );

      await _engine!.enableVideo();
      
      if (_isHost) {
        await _engine!.enableLocalVideo(true);
        await _engine!.startPreview();
      }

      setState(() {
        _isInitialized = true;
      });

      _joinChannel();

      debugPrint('Agora live initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Agora: $e');
      _showSnackBar('Failed to initialize: $e');
    }
  }

  Future<void> _joinChannel() async {
    if (!_isInitialized || _engine == null) {
      _showSnackBar('Initializing, please wait...');
      return;
    }

    try {
      debugPrint('Joining live channel: $channelName as ${_isHost ? "Host" : "Audience"}');

      await _engine!.setChannelProfile(
        ChannelProfileType.channelProfileLiveBroadcasting,
      );
      
      await _engine!.setClientRole(
        role: _isHost 
            ? ClientRoleType.clientRoleBroadcaster 
            : ClientRoleType.clientRoleAudience,
      );

      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: 0,
        options: ChannelMediaOptions(
          publishCameraTrack: _isHost,
          publishMicrophoneTrack: _isHost,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
          clientRoleType: _isHost 
              ? ClientRoleType.clientRoleBroadcaster 
              : ClientRoleType.clientRoleAudience,
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
    Navigator.pop(context);
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

  Future<void> _requestToBecomeCoHost() async {
    // In a real app, this would send a request to the host
    // For demo, we'll directly switch to broadcaster role
    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine!.enableLocalVideo(true);
    await _engine!.startPreview();
    
    setState(() {
      _isHost = true;
      if (_localUid != null) {
        _coHosts.add(_localUid!);
      }
    });
    
    _showSnackBar('You are now a co-host!');
  }

  void _sendLike() {
    setState(() {
      _likesCount++;
    });
    // In a real app, broadcast this to all users
  }

  void _sendMessage() {
    if (_chatController.text.trim().isEmpty) return;
    
    setState(() {
      _chatMessages.add('You: ${_chatController.text}');
    });
    _chatController.clear();
    
    // In a real app, send via RTM or similar messaging service
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _chatController.dispose();
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isInitialized
          ? _isJoined
              ? _buildLiveRoomView()
              : const Center(child: CircularProgressIndicator())
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

  Widget _buildLiveRoomView() {
    return Stack(
      children: [
        // Main video view - Host or first co-host
        _buildMainVideoView(),

        // Top bar with stats
        _buildTopBar(),

        // Co-hosts grid (if any)
        if (_coHosts.isNotEmpty || (_isHost && _remoteUsers.isNotEmpty))
          _buildCoHostsGrid(),

        // Chat messages
        _buildChatOverlay(),

        // Bottom controls
        _buildBottomControls(),

        // Like animation overlay
        _buildLikeButton(),
      ],
    );
  }

  Widget _buildMainVideoView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: _isHost
            ? AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: _engine!,
                  canvas: const VideoCanvas(uid: 0),
                ),
              )
            : _remoteUsers.isNotEmpty
                ? AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: _engine!,
                      canvas: VideoCanvas(uid: _remoteUsers.first),
                      connection: RtcConnection(channelId: channelName),
                    ),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videocam_off, size: 64, color: Colors.white54),
                      SizedBox(height: 16),
                      Text(
                        'Waiting for host to start...',
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: _leaveChannel,
              icon: const Icon(Icons.close, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.remove_red_eye, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '$_viewerCount',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (!_isHost)
              ElevatedButton.icon(
                onPressed: _requestToBecomeCoHost,
                icon: const Icon(Icons.pan_tool, size: 16),
                label: const Text('Request', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoHostsGrid() {
    final coHostsList = _isHost 
        ? _remoteUsers.where((uid) => _coHosts.contains(uid)).toList()
        : _coHosts.toList();
    
    if (coHostsList.isEmpty) return const SizedBox.shrink();

    return Positioned(
      top: 120,
      right: 12,
      child: Column(
        children: coHostsList.take(3).map((uid) {
          return Container(
            width: 90,
            height: 120,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: _engine!,
                  canvas: VideoCanvas(uid: uid),
                  connection: RtcConnection(channelId: channelName),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChatOverlay() {
    return Positioned(
      left: 16,
      right: 100,
      bottom: 120,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 200),
        child: ListView.builder(
          reverse: true,
          itemCount: _chatMessages.length,
          itemBuilder: (context, index) {
            final reversedIndex = _chatMessages.length - 1 - index;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _chatMessages[reversedIndex],
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLikeButton() {
    return Positioned(
      right: 16,
      bottom: 200,
      child: Column(
        children: [
          IconButton(
            onPressed: _sendLike,
            icon: const Icon(Icons.favorite, color: Colors.red, size: 32),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
          ),
          if (_likesCount > 0)
            Text(
              '$_likesCount',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
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
            // Chat input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Say something...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.black54,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send, color: Colors.blue),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            
            if (_isHost) ...[
              const SizedBox(height: 16),
              // Host controls
              Row(
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
                    label: 'Flip',
                    onPressed: _switchCamera,
                  ),
                  _buildControlButton(
                    icon: Icons.call_end,
                    label: 'End',
                    onPressed: _leaveChannel,
                    color: Colors.red,
                  ),
                ],
              ),
            ],
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
          iconSize: 24,
          color: color ?? Colors.white,
          style: IconButton.styleFrom(
            backgroundColor: Colors.black54,
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
