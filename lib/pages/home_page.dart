import 'package:finalapp/pages/server_page.dart';
import 'package:finalapp/pages/setting_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'chat_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerOpen = false;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<User?>(context);

    if (currentUser == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(currentUser),
      drawerEnableOpenDragGesture: false,
      onDrawerChanged: (isOpened) => setState(() => _isDrawerOpen = isOpened),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(_isDrawerOpen ? Icons.close : Icons.menu),
          onPressed: () {
            if (_isDrawerOpen) {
              _scaffoldKey.currentState?.openEndDrawer();
            } else {
              _scaffoldKey.currentState?.openDrawer();
            }
          },
        ),
        title: Text(_selectedIndex == 0 ? '我的伺服器' : '好友聊天'),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          ServerPage(),
          ChatPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dns),
            label: '伺服器',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: '聊天',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(User currentUser) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(currentUser.displayName ?? '未設定用戶名'),
            accountEmail: Text(currentUser.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundImage: currentUser.photoURL != null
                  ? NetworkImage(currentUser.photoURL!)
                  : null,
              child: currentUser.photoURL == null
                  ? Icon(Icons.person, size: 40)
                  : null,
            ),
          ),
          ListTile(
            leading: Icon(Icons.people),
            title: Text('好友列表'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 1);
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('設定'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
          Spacer(),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('登出'),
            onTap: () {
              Provider.of<AuthService>(context, listen: false).signOut();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
