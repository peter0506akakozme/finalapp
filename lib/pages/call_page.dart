import 'package:flutter/material.dart';
import '../services/call_service.dart';

class CallPage extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;
  final String callType; // 'voice' 或 'video'
  final bool isIncoming;

  const CallPage({
    required this.targetUserId,
    required this.targetUserName,
    required this.callType,
    this.isIncoming = false,
  });

  @override
  _CallPageState createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final CallService _callService = CallService();
  String? _remoteUid;
  bool _isConnecting = true;
  bool _isCallEnded = false;
  bool _isTestMode = false; // 測試模式

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    try {
      // 設置回調函數
      _callService.onUserJoined = (String uid) {
        setState(() {
          _remoteUid = uid;
          _isConnecting = false;
        });
      };

      _callService.onUserOffline = (String uid) {
        setState(() {
          _remoteUid = null;
        });
      };

      _callService.onCallEnded = () {
        setState(() {
          _isCallEnded = true;
        });
        Navigator.pop(context);
      };

      _callService.onCallStarted = () {
        setState(() {
          _isConnecting = false;
        });
      };

      // 初始化 Socket.IO
      _callService.initializeSocket();

      if (!widget.isIncoming) {
        // 發起通話
        if (widget.callType == 'voice') {
          await _callService.startVoiceCall(widget.targetUserId, widget.targetUserName);
        } else {
          await _callService.startVideoCall(widget.targetUserId, widget.targetUserName);
        }
      }
    } catch (e) {
      print('初始化通話失敗: $e');
      
      // 如果是測試模式，顯示測試介面
      if (_isTestMode) {
        setState(() {
          _isConnecting = false;
          _remoteUid = 'test_user_123'; // 模擬遠程用戶
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('測試模式：${widget.callType == 'voice' ? '語音' : '視訊'}通話介面'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('通話初始化失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 視訊通話的視訊視圖
            if (widget.callType == 'video') ...[
              // 遠程視訊視圖 (全螢幕)
              if (_remoteUid != null)
                _isTestMode 
                    ? _buildTestVideoView()
                    : _callService.getRemoteVideoView(_remoteUid!),
              
              // 本地視訊視圖 (小視窗)
              Positioned(
                top: 50,
                right: 20,
                child: Container(
                  width: 120,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _isTestMode 
                        ? _buildTestLocalVideoView()
                        : _callService.getLocalVideoView(),
                  ),
                ),
              ),
            ] else ...[
              // 語音通話的背景
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.blue[900]!,
                      Colors.blue[700]!,
                      Colors.blue[500]!,
                    ],
                  ),
                ),
              ),
            ],

            // 測試模式提示
            if (_isTestMode)
              Positioned(
                top: 20,
                left: 20,
                right: 20,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '測試模式 - 請設定 Agora App ID',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // 用戶資訊
            Positioned(
              top: _isTestMode ? 60 : 50,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white24,
                    child: Icon(
                      widget.callType == 'voice' ? Icons.person : Icons.videocam,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.targetUserName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isTestMode 
                        ? '測試模式 - 通話中'
                        : (_isConnecting ? '連接中...' : (_remoteUid != null ? '通話中' : '等待對方接聽')),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  if (widget.callType == 'voice') ...[
                    const SizedBox(height: 20),
                    Text(
                      '語音通話',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 通話控制按鈕
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // 主要控制按鈕
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 靜音按鈕
                      _buildControlButton(
                        icon: _callService.isMuted ? Icons.mic_off : Icons.mic,
                        color: _callService.isMuted ? Colors.red : Colors.white,
                        onPressed: () async {
                          if (_isTestMode) {
                            setState(() {
                              // 在測試模式下切換靜音狀態
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('測試模式：靜音功能')),
                            );
                          } else {
                            await _callService.toggleMute();
                            setState(() {});
                          }
                        },
                      ),
                      
                      // 結束通話按鈕
                      _buildControlButton(
                        icon: Icons.call_end,
                        color: Colors.red,
                        onPressed: () async {
                          if (_isTestMode) {
                            Navigator.pop(context);
                          } else {
                            await _callService.endCall();
                            Navigator.pop(context);
                          }
                        },
                      ),
                      
                      // 視訊切換按鈕 (僅視訊通話)
                      if (widget.callType == 'video')
                        _buildControlButton(
                          icon: _callService.isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                          color: _callService.isVideoEnabled ? Colors.white : Colors.red,
                          onPressed: () async {
                            if (_isTestMode) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('測試模式：視訊切換功能')),
                              );
                            } else {
                              await _callService.toggleVideo();
                              setState(() {});
                            }
                          },
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // 次要控制按鈕
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 揚聲器按鈕
                      _buildControlButton(
                        icon: _callService.isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                        color: _callService.isSpeakerOn ? Colors.blue : Colors.white,
                        onPressed: () async {
                          if (_isTestMode) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('測試模式：揚聲器切換功能')),
                            );
                          } else {
                            await _callService.toggleSpeaker();
                            setState(() {});
                          }
                        },
                      ),
                      
                      // 視訊切換按鈕 (語音通話時顯示)
                      if (widget.callType == 'voice')
                        _buildControlButton(
                          icon: Icons.videocam,
                          color: Colors.white,
                          onPressed: () async {
                            if (_isTestMode) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CallPage(
                                    targetUserId: widget.targetUserId,
                                    targetUserName: widget.targetUserName,
                                    callType: 'video',
                                  ),
                                ),
                              );
                            } else {
                              // 切換到視訊通話
                              await _callService.endCall();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CallPage(
                                    targetUserId: widget.targetUserId,
                                    targetUserName: widget.targetUserName,
                                    callType: 'video',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // 來電接聽/拒絕按鈕 (僅來電時顯示)
            if (widget.isIncoming && _isConnecting)
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 拒絕按鈕
                    _buildControlButton(
                      icon: Icons.call_end,
                      color: Colors.red,
                      onPressed: () {
                        if (_isTestMode) {
                          Navigator.pop(context);
                        } else {
                          _callService.rejectCall(_callService.channelName ?? '');
                          Navigator.pop(context);
                        }
                      },
                    ),
                    
                    // 接聽按鈕
                    _buildControlButton(
                      icon: widget.callType == 'voice' ? Icons.call : Icons.videocam,
                      color: Colors.green,
                      onPressed: () async {
                        if (_isTestMode) {
                          setState(() {
                            _isConnecting = false;
                            _remoteUid = 'test_user_123';
                          });
                        } else {
                          try {
                            await _callService.acceptCall(
                              _callService.channelName ?? '',
                              widget.callType,
                            );
                          } catch (e) {
                            print('接聽通話失敗: $e');
                            Navigator.pop(context);
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 測試用的視訊視圖
  Widget _buildTestVideoView() {
    return Container(
      color: Colors.grey[800],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam,
              size: 100,
              color: Colors.white54,
            ),
            SizedBox(height: 20),
            Text(
              '遠程視訊視圖\n(測試模式)',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 測試用的本地視訊視圖
  Widget _buildTestLocalVideoView() {
    return Container(
      color: Colors.grey[600],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person,
              size: 30,
              color: Colors.white,
            ),
            SizedBox(height: 5),
            Text(
              '本地\n(測試)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 30),
        onPressed: onPressed,
        iconSize: 30,
      ),
    );
  }

  @override
  void dispose() {
    if (!_isCallEnded && !_isTestMode) {
      _callService.endCall();
    }
    super.dispose();
  }
} 