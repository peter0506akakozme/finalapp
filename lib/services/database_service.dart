import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/model.dart';



class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 创建新服务器
  Future<void> createServer(String name, String ownerId) async {
    try {
      await _firestore.collection('servers').add({
        'name': name,
        'ownerId': ownerId,
        'iconUrl': '',
        'createdAt': DateTime.now(),
      });
    } catch (e) {
      print(e.toString());
    }
  }

  // 获取用户加入的服务器列表
  Stream<List<Server>> getUserServers(String userId) {
    return _firestore
        .collection('servers')
        .where('members', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Server.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // 创建频道
  Future<void> createChannel(String serverId, String name, String? description) async {
    try {
      await _firestore.collection('servers/$serverId/channels').add({
        'name': name,
        'description': description,
        'createdAt': DateTime.now(),
      });
    } catch (e) {
      print(e.toString());
    }
  }

  // 获取服务器中的频道列表
  Stream<List<Channel>> getServerChannels(String serverId) {
    return _firestore
        .collection('servers/$serverId/channels')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Channel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // 发送消息
  Future<void> sendMessage(
      String channelId,
      String senderId,
      String content, {
        String? imageUrl,
      }) async {
    try {
      await _firestore.collection('channels/$channelId/messages').add({
        'senderId': senderId,
        'content': content,
        'imageUrl': imageUrl,
        'timestamp': DateTime.now(),
      });
    } catch (e) {
      print(e.toString());
    }
  }

  // 获取频道消息
  Stream<List<Message>> getChannelMessages(String channelId) {
    return _firestore
        .collection('channels/$channelId/messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Message.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
}