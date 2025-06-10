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
  Future signOut() async {
    try {
      // 更新用戶狀態為離線
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'status': 'offline',
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }

      return await _auth.signOut();
    } catch (e) {
      print(e.toString());
      return null;
    }
  }
}