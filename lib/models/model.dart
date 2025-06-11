import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;
  final String avatarUrl;
  final DateTime createdAt;
  final bool isOnline;
  final DateTime? lastSeen;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.avatarUrl,
    required this.createdAt,
    this.isOnline = false,
    this.lastSeen,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isOnline: data['isOnline'] ?? false,
      lastSeen: data['lastSeen'] != null ? (data['lastSeen'] as Timestamp).toDate() : null,
    );
  }
}

class FriendRequest {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;

  FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequest.fromMap(Map<String, dynamic> data, String id) {
    return FriendRequest(
      id: id,
      fromUserId: data['fromUserId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}

class Friendship {
  final String id;
  final List<String> userIds;
  final DateTime createdAt;

  Friendship({
    required this.id,
    required this.userIds,
    required this.createdAt,
  });

  factory Friendship.fromMap(Map<String, dynamic> data, String id) {
    return Friendship(
      id: id,
      userIds: List<String>.from(data['userIds'] ?? []),
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
  final List<String> members;
  final String? description;

  Server({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.iconUrl,
    required this.createdAt,
    required this.members,
    this.description,
  });

  factory Server.fromMap(Map<String, dynamic> data, String id) {
    return Server(
      id: id,
      name: data['name'] ?? '',
      ownerId: data['ownerId'] ?? '',
      iconUrl: data['iconUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      members: List<String>.from(data['members'] ?? []),
      description: data['description'],
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
  final String? videoUrl;
  final String? fileUrl;
  final String? fileName;
  final String? fileSize;
  final String messageType; // 'text', 'image', 'video', 'file'
  final bool isRead;
  final List<String> readBy;

  Message({
    required this.id,
    required this.channelId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.imageUrl,
    this.videoUrl,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.messageType = 'text',
    this.isRead = false,
    this.readBy = const [],
  });

  factory Message.fromMap(Map<String, dynamic> data, String id) {
    DateTime timestamp;
    if (data['timestamp'] is Timestamp) {
      timestamp = (data['timestamp'] as Timestamp).toDate();
    } else if (data['timestamp'] != null) {
      // 如果是 FieldValue.serverTimestamp() 或其他類型，使用當前時間
      timestamp = DateTime.now();
    } else {
      timestamp = DateTime.now();
    }

    return Message(
      id: id,
      channelId: data['channelId'] ?? '',
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      timestamp: timestamp,
      imageUrl: data['imageUrl'],
      videoUrl: data['videoUrl'],
      fileUrl: data['fileUrl'],
      fileName: data['fileName'],
      fileSize: data['fileSize'],
      messageType: data['messageType'] ?? 'text',
      isRead: data['isRead'] ?? false,
      readBy: List<String>.from(data['readBy'] ?? []),
    );
  }
}