import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;
  final String avatarUrl;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.avatarUrl,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}

class Server {
  final String id;
  final String name;
  final String ownerId;
  final String iconUrl;
  final DateTime createdAt;

  Server({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.iconUrl,
    required this.createdAt,
  });

  factory Server.fromMap(Map<String, dynamic> data, String id) {
    return Server(
      id: id,
      name: data['name'] ?? '',
      ownerId: data['ownerId'] ?? '',
      iconUrl: data['iconUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}

class Channel {
  final String id;
  final String serverId;
  final String name;
  final String? description;
  final DateTime createdAt;

  Channel({
    required this.id,
    required this.serverId,
    required this.name,
    this.description,
    required this.createdAt,
  });

  factory Channel.fromMap(Map<String, dynamic> data, String id) {
    return Channel(
      id: id,
      serverId: data['serverId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}

class Message {
  final String id;
  final String channelId;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final String? imageUrl;

  Message({
    required this.id,
    required this.channelId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.imageUrl,
  });

  factory Message.fromMap(Map<String, dynamic> data, String id) {
    return Message(
      id: id,
      channelId: data['channelId'] ?? '',
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'],
    );
  }
}