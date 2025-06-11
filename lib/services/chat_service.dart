import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // 初始化通知
  Future<void> initializeNotifications() async {
    // 請求通知權限
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 獲取 FCM token
      String? token = await _messaging.getToken();
      if (token != null) {
        await _updateUserFCMToken(token);
      }

      // 監聽 token 更新
      _messaging.onTokenRefresh.listen((newToken) {
        _updateUserFCMToken(newToken);
      });

      // 初始化本地通知
      await _initializeLocalNotifications();
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(initializationSettings);
  }

  Future<void> _updateUserFCMToken(String token) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
  }

  // 更新用戶在線狀態
  Future<void> updateOnlineStatus(bool isOnline) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
  }

  // 創建或獲取聊天室
  Future<String> createOrGetChat(String otherUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('用戶未登入');

    // 檢查是否已存在聊天室
    final existingChat = await _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUser.uid)
        .get();

    for (var doc in existingChat.docs) {
      List<String> participants = List<String>.from(doc['participants']);
      if (participants.contains(otherUserId)) {
        return doc.id;
      }
    }

    // 創建新的聊天室
    final chatDoc = await _firestore.collection('chats').add({
      'participants': [currentUser.uid, otherUserId],
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'type': 'private', // private 或 group
    });

    return chatDoc.id;
  }

  // 發送訊息
  Future<void> sendMessage(String chatId, String content, {String? imageUrl}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('用戶未登入');

    final messageData = {
      'senderId': currentUser.uid,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'readBy': [currentUser.uid],
    };

    if (imageUrl != null) {
      messageData['imageUrl'] = imageUrl;
      messageData['type'] = 'image';
    } else {
      messageData['type'] = 'text';
    }

    // 添加訊息到聊天室
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(messageData);

    // 更新聊天室的最後訊息
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': content,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    // 發送推播通知
    await _sendPushNotification(chatId, content);
  }

  // 發送推播通知
  Future<void> _sendPushNotification(String chatId, String content) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // 獲取聊天室參與者
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    final participants = List<String>.from(chatDoc['participants']);
    participants.remove(currentUser.uid);

    // 獲取發送者資訊
    final senderDoc = await _firestore.collection('users').doc(currentUser.uid).get();
    final senderData = senderDoc.data() as Map<String, dynamic>;

    // 為每個參與者發送通知
    for (String participantId in participants) {
      final userDoc = await _firestore.collection('users').doc(participantId).get();
      final userData = userDoc.data() as Map<String, dynamic>;
      final fcmToken = userData['fcmToken'];

      if (fcmToken != null) {
        // 這裡可以整合 Firebase Cloud Functions 來發送推播通知
        // 或者使用第三方服務如 OneSignal
        await _sendLocalNotification(senderData['username'], content);
      }
    }
  }

  Future<void> _sendLocalNotification(String senderName, String content) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'chat_channel',
      '聊天通知',
      channelDescription: '聊天訊息通知',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      0,
      senderName,
      content,
      platformChannelSpecifics,
    );
  }

  // 標記訊息為已讀
  Future<void> markMessageAsRead(String chatId, String messageId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'readBy': FieldValue.arrayUnion([currentUser.uid]),
      'isRead': true,
    });
  }

  // 獲取聊天室列表
  Stream<QuerySnapshot> getChatsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.empty();

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUser.uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // 獲取聊天訊息
  Stream<QuerySnapshot> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // 獲取用戶在線狀態
  Stream<DocumentSnapshot> getUserOnlineStatus(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  // 上傳圖片
  Future<String> uploadImage(File imageFile) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('用戶未登入');

    final fileName = 'chat_images/${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    // 這裡需要整合 Firebase Storage
    // 暫時返回一個假 URL
    return 'https://example.com/image.jpg';
  }

  // 刪除訊息
  Future<void> deleteMessage(String chatId, String messageId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final messageDoc = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .get();

    if (messageDoc.exists && messageDoc['senderId'] == currentUser.uid) {
      await messageDoc.reference.delete();
    }
  }

  // 檢查網路連接
  Stream<ConnectivityResult> get connectivityStream {
    return Connectivity().onConnectivityChanged;
  }
} 