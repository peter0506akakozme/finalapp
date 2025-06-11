import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/model.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 搜尋用戶
  Future<List<UserModel>> searchUsers(String query) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    try {
      // 搜尋用戶名稱或電子郵件
      final usersQuery = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThan: query + '\uf8ff')
          .limit(10)
          .get();

      final emailQuery = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThan: query + '\uf8ff')
          .limit(10)
          .get();

      // 合併結果並去重
      final allDocs = [...usersQuery.docs, ...emailQuery.docs];
      final uniqueDocs = <String, DocumentSnapshot>{};
      
      for (var doc in allDocs) {
        if (doc.id != currentUser.uid) { // 排除自己
          uniqueDocs[doc.id] = doc;
        }
      }

      return uniqueDocs.values.map((doc) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('搜尋用戶錯誤: $e');
      return [];
    }
  }

  // 發送好友請求
  Future<bool> sendFriendRequest(String toUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      // 檢查是否已經發送過請求
      final existingRequest = await _firestore
          .collection('friendRequests')
          .where('fromUserId', isEqualTo: currentUser.uid)
          .where('toUserId', isEqualTo: toUserId)
          .get();

      if (existingRequest.docs.isNotEmpty) {
        return false; // 已經發送過請求
      }

      // 檢查是否已經是好友
      final existingFriendship = await _firestore
          .collection('friendships')
          .where('userIds', arrayContains: currentUser.uid)
          .get();

      for (var doc in existingFriendship.docs) {
        final userIds = List<String>.from(doc['userIds']);
        if (userIds.contains(toUserId)) {
          return false; // 已經是好友
        }
      }

      // 發送好友請求
      await _firestore.collection('friendRequests').add({
        'fromUserId': currentUser.uid,
        'toUserId': toUserId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('發送好友請求錯誤: $e');
      return false;
    }
  }

  // 獲取收到的好友請求
  Stream<List<FriendRequest>> getReceivedFriendRequests() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection('friendRequests')
        .where('toUserId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return FriendRequest.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // 接受好友請求
  Future<bool> acceptFriendRequest(String requestId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final requestDoc = await _firestore
          .collection('friendRequests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) return false;

      final requestData = requestDoc.data() as Map<String, dynamic>;
      final fromUserId = requestData['fromUserId'];

      // 更新請求狀態
      await _firestore
          .collection('friendRequests')
          .doc(requestId)
          .update({'status': 'accepted'});

      // 創建好友關係
      await _firestore.collection('friendships').add({
        'userIds': [currentUser.uid, fromUserId],
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('接受好友請求錯誤: $e');
      return false;
    }
  }

  // 拒絕好友請求
  Future<bool> rejectFriendRequest(String requestId) async {
    try {
      await _firestore
          .collection('friendRequests')
          .doc(requestId)
          .update({'status': 'rejected'});
      return true;
    } catch (e) {
      print('拒絕好友請求錯誤: $e');
      return false;
    }
  }

  // 獲取好友列表
  Stream<List<UserModel>> getFriends() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection('friendships')
        .where('userIds', arrayContains: currentUser.uid)
        .snapshots()
        .asyncMap((snapshot) async {
      final friends = <UserModel>[];

      for (var doc in snapshot.docs) {
        final userIds = List<String>.from(doc['userIds']);
        final friendId = userIds.firstWhere((id) => id != currentUser.uid);

        try {
          final userDoc = await _firestore
              .collection('users')
              .doc(friendId)
              .get();

          if (userDoc.exists) {
            friends.add(UserModel.fromMap(userDoc.data() as Map<String, dynamic>));
          }
        } catch (e) {
          print('獲取好友資訊錯誤: $e');
        }
      }

      return friends;
    });
  }

  // 移除好友
  Future<bool> removeFriend(String friendId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      // 找到並刪除好友關係
      final friendshipQuery = await _firestore
          .collection('friendships')
          .where('userIds', arrayContains: currentUser.uid)
          .get();

      for (var doc in friendshipQuery.docs) {
        final userIds = List<String>.from(doc['userIds']);
        if (userIds.contains(friendId)) {
          await doc.reference.delete();
          break;
        }
      }

      return true;
    } catch (e) {
      print('移除好友錯誤: $e');
      return false;
    }
  }

  // 檢查是否已經是好友
  Future<bool> isFriend(String userId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final friendshipQuery = await _firestore
          .collection('friendships')
          .where('userIds', arrayContains: currentUser.uid)
          .get();

      for (var doc in friendshipQuery.docs) {
        final userIds = List<String>.from(doc['userIds']);
        if (userIds.contains(userId)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('檢查好友關係錯誤: $e');
      return false;
    }
  }

  // 檢查是否有待處理的好友請求
  Future<bool> hasPendingRequest(String fromUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final requestQuery = await _firestore
          .collection('friendRequests')
          .where('fromUserId', isEqualTo: fromUserId)
          .where('toUserId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      return requestQuery.docs.isNotEmpty;
    } catch (e) {
      print('檢查待處理請求錯誤: $e');
      return false;
    }
  }
} 