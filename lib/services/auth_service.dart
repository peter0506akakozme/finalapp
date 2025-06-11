import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 認證狀態變化流
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 使用電子郵件和密碼註冊
  Future<User?> registerWithEmailAndPassword(
      String email,
      String password,
      String username,
      ) async {
    try {
      // 1. 創建用戶帳戶
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // 2. 將用戶信息保存到Firestore
        await _saveUserToFirestore(
          uid: user.uid,
          email: email,
          username: username,
        );

        // 3. 更新用戶顯示名稱
        await user.updateDisplayName(username);

        return user;
      }
      return null;
    } catch (e) {
      print('註冊錯誤: $e');
      rethrow;
    }
  }

  // 將用戶信息保存到Firestore
  Future<void> _saveUserToFirestore({
    required String uid,
    required String email,
    required String username,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'username': username,
      'avatarUrl': '',
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeen': FieldValue.serverTimestamp(),
      'status': 'offline',
      'friends': [],
      'servers': [],
    });
  }

  // 使用電子郵件和密碼登入
  Future<String?> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return 'success';
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // 登出
  Future<void> signOut() async {
    try {
      // 更新用戶狀態為離線
      final user = _auth.currentUser;
      if (user != null) {
        // 先檢查用戶文檔是否存在
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        if (userDoc.exists) {
          // 如果文檔存在，更新狀態
          await _firestore.collection('users').doc(user.uid).update({
            'isOnline': false,
            'lastSeen': FieldValue.serverTimestamp(),
            'fcmToken': null, // 清除推播通知 token
          });
        } else {
          // 如果文檔不存在，創建基本文檔
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email ?? '',
            'username': user.displayName ?? '用戶',
            'avatarUrl': '',
            'isOnline': false,
            'lastSeen': FieldValue.serverTimestamp(),
            'fcmToken': null,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // 執行 Firebase Auth 登出
      await _auth.signOut();
    } catch (e) {
      print('登出錯誤: $e');
      throw Exception('登出失敗: $e');
    }
  }
}