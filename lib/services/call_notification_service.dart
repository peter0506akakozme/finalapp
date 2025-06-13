import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:typed_data';

class CallNotificationService {
  static final CallNotificationService _instance = CallNotificationService._internal();
  factory CallNotificationService() => _instance;
  CallNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<void> showIncomingCallNotification({
    required String callerName,
    required String callType,
    required String channelName,
    required String targetUserId,
  }) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'incoming_calls',
      '來電通知',
      channelDescription: '顯示來電通知',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('ringtone'),
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      ongoing: true,
      autoCancel: false,
      category: AndroidNotificationCategory.call,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'ringtone.aiff',
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notifications.show(
      1001, // 來電通知 ID
      '來電',
      '$callerName 正在${callType == 'voice' ? '語音' : '視訊'}通話',
      platformChannelSpecifics,
      payload: 'call:$channelName:$callType:$targetUserId:$callerName',
    );
  }

  Future<void> cancelIncomingCallNotification() async {
    await _notifications.cancel(1001);
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null && response.payload!.startsWith('call:')) {
      final parts = response.payload!.split(':');
      if (parts.length >= 5) {
        final channelName = parts[1];
        final callType = parts[2];
        final targetUserId = parts[3];
        final callerName = parts[4];
        
        // 這裡可以導航到通話頁面
        // 注意：在通知回調中直接導航可能會有問題
        // 建議使用全局導航鍵或事件系統
        print('用戶點擊了來電通知: $callerName');
      }
    }
  }

  // 顯示通話狀態通知
  Future<void> showCallStatusNotification({
    required String title,
    required String body,
    bool isOngoing = false,
  }) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'call_status',
      '通話狀態',
      channelDescription: '顯示通話狀態通知',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: isOngoing,
      autoCancel: !isOngoing,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notifications.show(
      1002, // 通話狀態通知 ID
      title,
      body,
      platformChannelSpecifics,
    );
  }

  // 取消通話狀態通知
  Future<void> cancelCallStatusNotification() async {
    await _notifications.cancel(1002);
  }
} 