import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'call_notification_service.dart';

class CallService {
  // ========================================
  // 🔧 請在這裡設定您的 Agora 憑證
  // ========================================
  // 1. 前往 https://console.agora.io/ 註冊帳號
  // 2. 創建專案並選擇 RTC 服務
  // 3. 將下面的 'YOUR_AGORA_APP_ID' 替換為您的真實 App ID
  static const String appId = '692879741e394e17bfa61ec870017c85';
  
  // 4. 將下面的 'YOUR_AGORA_APP_CERTIFICATE' 替換為您的真實 App Certificate
  static const String appCertificate = '7f32651468ce44bd82a10afce5ff5ea3';
  
  // 5. 設定您的信令伺服器 URL（可選，用於來電通知）
  static const String signalingServerUrl = 'https://your-signaling-server.com';
  
  // 6. 測試模式：設為 true 可以測試 UI 功能（無需真實 Agora 憑證）
  static const bool testMode = false;
  // ========================================
  
  RtcEngine? _engine;
  IO.Socket? _socket;
  String? _channelName;
  String? _token;
  bool _isInCall = false;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerOn = false;
  
  final CallNotificationService _notificationService = CallNotificationService();
  
  // 回調函數
  Function(String)? onUserJoined;
  Function(String)? onUserOffline;
  Function()? onCallEnded;
  Function()? onCallStarted;
  Function(String, String, String)? onIncomingCall; // 來電回調
  
  // 單例模式
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  // 初始化
  Future<void> initialize() async {
    await _notificationService.initialize();
    
    // 檢查是否已設定 Agora 憑證
    if (appId == 'YOUR_AGORA_APP_ID' && !testMode) {
      print('⚠️ 警告: 請先設定 Agora App ID 和 App Certificate');
      print('📖 設定說明: 請編輯 lib/services/call_service.dart 檔案');
      print('💡 提示: 您可以將 testMode 設為 true 來測試 UI 功能');
      return;
    }
    
    if (testMode) {
      print('🧪 測試模式已啟用 - 您可以測試 UI 功能');
      print('📖 要啟用真實通話功能，請設定 Agora 憑證並將 testMode 設為 false');
    }
    
    // 初始化 Socket.IO 連接
    initializeSocket();
  }

  // 初始化 Agora 引擎
  Future<void> initializeAgora() async {
    if (_engine != null) return;

    try {
      // 測試模式檢查
      if (testMode) {
        print('🧪 測試模式：跳過 Agora 引擎初始化');
        return;
      }
      
      // 檢查 App ID 是否已設定
      if (appId == 'YOUR_AGORA_APP_ID' || appId.isEmpty) {
        throw Exception('請先設定有效的 Agora App ID');
      }
      
      // 創建 RTC 引擎
      _engine = createAgoraRtcEngine();
      
      await _engine!.initialize(const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // 設置事件處理器
      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          print('✅ 成功加入頻道: ${connection.channelId}');
          _isInCall = true;
          onCallStarted?.call();
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          print('👤 用戶加入: $remoteUid');
          onUserJoined?.call(remoteUid.toString());
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          print('👤 用戶離線: $remoteUid');
          onUserOffline?.call(remoteUid.toString());
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          print('🚪 離開頻道');
          _isInCall = false;
          onCallEnded?.call();
        },
        onError: (ErrorCodeType err, String msg) {
          print('❌ Agora 錯誤: $err - $msg');
        },
      ));

      // 啟用音訊和視訊
      await _engine!.enableAudio();
      await _engine!.enableVideo();
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      
      print('✅ Agora 引擎初始化成功');
    } catch (e) {
      print('❌ Agora 引擎初始化失敗: $e');
      rethrow;
    }
  }

  // 初始化 Socket.IO 連接
  void initializeSocket() {
    try {
      if (testMode) {
        print('🧪 測試模式：跳過 Socket.IO 初始化');
        return;
      }
      
      if (signalingServerUrl == 'https://your-signaling-server.com') {
        print('⚠️ 警告: 信令伺服器未設定，來電功能可能無法正常工作');
        return;
      }
      
      _socket = IO.io(signalingServerUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      _socket!.onConnect((_) {
        print('✅ Socket.IO 連接成功');
      });

      _socket!.onDisconnect((_) {
        print('❌ Socket.IO 連接斷開');
      });

      _socket!.on('call-request', (data) {
        // 處理來電請求
        _handleIncomingCall(data);
      });

      _socket!.on('call-accepted', (data) {
        // 處理通話接受
        _handleCallAccepted(data);
      });

      _socket!.on('call-rejected', (data) {
        // 處理通話拒絕
        _handleCallRejected(data);
      });

      _socket!.on('call-ended', (data) {
        // 處理通話結束
        _handleCallEnded(data);
      });

      _socket!.connect();
    } catch (e) {
      print('❌ Socket.IO 初始化失敗: $e');
    }
  }

  // 發起語音通話
  Future<void> startVoiceCall(String targetUserId, String targetUserName) async {
    try {
      await _requestPermissions();
      await initializeAgora();

      _channelName = 'voice_${DateTime.now().millisecondsSinceEpoch}';
      _token = await _generateToken(_channelName!);
      if (_token == null) _token = '';

      _sendCallRequest(targetUserId, 'voice', _channelName!);

      // 語音專用
      await _engine!.enableAudio();
      await _engine!.muteLocalVideoStream(true);

      await _engine!.joinChannel(
        token: _token!,
        channelId: _channelName!,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      await _notificationService.showCallStatusNotification(
        title: '通話中',
        body: '正在與 $targetUserName 進行語音通話',
        isOngoing: true,
      );

      print('✅ 語音通話已發起');
    } catch (e) {
      print('❌ 發起語音通話失敗: $e');
      throw Exception('通話初始化失敗，請檢查網路連接或稍後再試');
    }
  }

  // 發起視訊通話
  Future<void> startVideoCall(String targetUserId, String targetUserName) async {
    try {
      await _requestPermissions();
      await initializeAgora();

      _channelName = 'video_${DateTime.now().millisecondsSinceEpoch}';
      _token = await _generateToken(_channelName!);
      if (_token == null) _token = '';

      _sendCallRequest(targetUserId, 'video', _channelName!);

      // 視訊專用
      await _engine!.enableVideo();
      await _engine!.muteLocalVideoStream(false);

      await _engine!.joinChannel(
        token: _token!,
        channelId: _channelName!,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      await _notificationService.showCallStatusNotification(
        title: '視訊通話中',
        body: '正在與 $targetUserName 進行視訊通話',
        isOngoing: true,
      );

      print('✅ 視訊通話已發起');
    } catch (e) {
      print('❌ 發起視訊通話失敗: $e');
      throw Exception('視訊通話初始化失敗，請檢查網路連接或稍後再試');
    }
  }

  // 接受通話
  Future<void> acceptCall(String channelName, String callType) async {
    try {
      await _requestPermissions();
      await initializeAgora();

      _channelName = channelName;
      _token = await _generateToken(_channelName!);
      if (_token == null) _token = '';

      // 語音或視訊分流
      if (callType == 'voice') {
        await _engine!.enableAudio();
        await _engine!.muteLocalVideoStream(true);
      } else {
        await _engine!.enableVideo();
        await _engine!.muteLocalVideoStream(false);
      }

      await _engine!.joinChannel(
        token: _token!,
        channelId: _channelName!,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      if (_socket != null) {
        _socket!.emit('call-accepted', {
          'channelName': channelName,
          'callType': callType,
        });
      }

      await _notificationService.cancelIncomingCallNotification();

      print('✅ 通話已接受');
    } catch (e) {
      print('❌ 接受通話失敗: $e');
      rethrow;
    }
  }

  // 拒絕通話
  void rejectCall(String channelName) {
    if (testMode) {
      print('🧪 測試模式：模擬拒絕通話');
      _notificationService.cancelIncomingCallNotification();
      print('❌ 通話已拒絕（測試模式）');
      return;
    }
    
    if (_socket != null) {
      _socket!.emit('call-rejected', {
        'channelName': channelName,
      });
    }
    
    // 取消來電通知
    _notificationService.cancelIncomingCallNotification();
    print('❌ 通話已拒絕');
  }

  // 結束通話
  Future<void> endCall() async {
    try {
      if (testMode) {
        print('🧪 測試模式：模擬結束通話');
        _isInCall = false;
        onCallEnded?.call();
        
        // 取消通話狀態通知
        await _notificationService.cancelCallStatusNotification();
        print('✅ 通話已結束（測試模式）');
        return;
      }
      
      if (_engine != null && _isInCall) {
        await _engine!.leaveChannel();
        _isInCall = false;
        
        // 發送結束通話信號
        if (_socket != null) {
          _socket!.emit('call-ended', {
            'channelName': _channelName,
          });
        }
        
        // 取消通話狀態通知
        await _notificationService.cancelCallStatusNotification();
        print('✅ 通話已結束');
      }
    } catch (e) {
      print('❌ 結束通話失敗: $e');
    }
  }

  // 切換靜音
  Future<void> toggleMute() async {
    if (testMode) {
      _isMuted = !_isMuted;
      print(_isMuted ? '🔇 已靜音（測試模式）' : '🔊 已取消靜音（測試模式）');
      return;
    }
    
    if (_engine != null) {
      _isMuted = !_isMuted;
      await _engine!.muteLocalAudioStream(_isMuted);
      print(_isMuted ? '🔇 已靜音' : '🔊 已取消靜音');
    }
  }

  // 切換視訊
  Future<void> toggleVideo() async {
    if (testMode) {
      _isVideoEnabled = !_isVideoEnabled;
      print(_isVideoEnabled ? '📹 視訊已開啟（測試模式）' : '📹 視訊已關閉（測試模式）');
      return;
    }
    
    if (_engine != null) {
      _isVideoEnabled = !_isVideoEnabled;
      await _engine!.muteLocalVideoStream(!_isVideoEnabled);
      print(_isVideoEnabled ? '📹 視訊已開啟' : '📹 視訊已關閉');
    }
  }

  // 切換揚聲器
  Future<void> toggleSpeaker() async {
    if (testMode) {
      _isSpeakerOn = !_isSpeakerOn;
      print(_isSpeakerOn ? '🔊 揚聲器已開啟（測試模式）' : '🔊 揚聲器已關閉（測試模式）');
      return;
    }
    
    if (_engine != null) {
      await _engine!.setEnableSpeakerphone(!_isSpeakerOn);
      _isSpeakerOn = !_isSpeakerOn;
      print(_isSpeakerOn ? '🔊 揚聲器已開啟' : '🔊 揚聲器已關閉');
    }
  }

  // 請求權限
  Future<void> _requestPermissions() async {
    await [
      Permission.microphone,
      Permission.camera,
    ].request();
  }

  // 生成 Agora Token
  Future<String> _generateToken(String channelName) async {
    // 測試用，正式請串接 Token Server
    return '';
  }

  // 發送通話請求
  void _sendCallRequest(String targetUserId, String callType, String channelName) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && _socket != null) {
      _socket!.emit('call-request', {
        'fromUserId': currentUser.uid,
        'toUserId': targetUserId,
        'callType': callType,
        'channelName': channelName,
        'timestamp': DateTime.now().toIso8601String(),
      });
      print('📞 通話請求已發送');
    }
  }

  // 處理來電
  void _handleIncomingCall(dynamic data) {
    print('📞 收到來電: $data');
    
    // 解析來電數據
    final fromUserId = data['fromUserId'];
    final callType = data['callType'];
    final channelName = data['channelName'];
    
    // 獲取來電者資訊
    FirebaseFirestore.instance
        .collection('users')
        .doc(fromUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        final userData = doc.data() as Map<String, dynamic>;
        final callerName = userData['username'] ?? '未知用戶';
        
        // 顯示來電通知
        _notificationService.showIncomingCallNotification(
          callerName: callerName,
          callType: callType,
          channelName: channelName,
          targetUserId: fromUserId,
        );
        
        // 觸發來電回調
        onIncomingCall?.call(channelName, callType, callerName);
      }
    });
  }

  // 處理通話接受
  void _handleCallAccepted(dynamic data) {
    print('✅ 通話被接受: $data');
  }

  // 處理通話拒絕
  void _handleCallRejected(dynamic data) {
    print('❌ 通話被拒絕: $data');
    endCall();
  }

  // 處理通話結束
  void _handleCallEnded(dynamic data) {
    print('🚪 通話結束: $data');
    endCall();
  }

  // 獲取本地視訊視圖
  Widget getLocalVideoView() {
    if (testMode) {
      return Container(
        width: 120,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(
            Icons.videocam,
            size: 40,
            color: Colors.grey,
          ),
        ),
      );
    }
    
    if (_engine == null) return Container();
    
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _engine!,
        canvas: const VideoCanvas(uid: 0),
      ),
    );
  }

  // 獲取遠程視訊視圖
  Widget getRemoteVideoView(String remoteUid) {
    if (testMode) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person,
                size: 60,
                color: Colors.grey,
              ),
              SizedBox(height: 8),
              Text(
                '遠程視訊（測試模式）',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_engine == null) return Container();
    
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine!,
        canvas: VideoCanvas(uid: int.parse(remoteUid)),
        connection: RtcConnection(channelId: _channelName!),
      ),
    );
  }

  // 清理資源
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    _socket?.disconnect();
    _socket?.dispose();
    _notificationService.cancelIncomingCallNotification();
    _notificationService.cancelCallStatusNotification();
  }

  // 獲取狀態
  bool get isInCall => _isInCall;
  bool get isMuted => _isMuted;
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isSpeakerOn => _isSpeakerOn;
  String? get channelName => _channelName;
  bool get isTestMode => testMode;
} 