import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../services/auth_service.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  File? _profileImage;
  bool _isDarkMode = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = Provider.of<User?>(context, listen: false);
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _usernameController.text = userDoc['username'] ?? '';
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      // 這裡可以添加上傳到 Firebase Storage 的代碼
    }
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      final user = Provider.of<User?>(context, listen: false);
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'username': _usernameController.text.trim(),
          });

          // 如果需要，這裡可以更新用戶的 displayName
          await user.updateDisplayName(_usernameController.text.trim());

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('設定已儲存')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('儲存失敗: $e')),
          );
        } finally {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<User?>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('設定'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : (currentUser?.photoURL != null
                          ? NetworkImage(currentUser!.photoURL!)
                          : null),
                      child: _profileImage == null && currentUser?.photoURL == null
                          ? Icon(Icons.person, size: 50)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: '用戶名稱',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入用戶名稱';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              Text(
                '主題設定',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SwitchListTile(
                title: Text('暗黑模式'),
                value: _isDarkMode,
                onChanged: (value) {
                  setState(() {
                    _isDarkMode = value;
                  });
                },
              ),
              SizedBox(height: 24),
              Text(
                '帳號',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ListTile(
                title: Text('變更密碼'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  // 導航到變更密碼頁面
                },
              ),
              ListTile(
                title: Text(
                  '登出',
                  style: TextStyle(color: Colors.red),
                ),
                trailing: Icon(Icons.logout, color: Colors.red),
                onTap: () {
                  Provider.of<AuthService>(context, listen: false).signOut();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
}