import 'package:finalapp/pages/server_page.dart';
import 'package:finalapp/pages/setting_page.dart';
import 'package:finalapp/pages/friends_page.dart';
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
        title: Text(_getTitle()),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          FriendsPage(),
          ChatPage(),
          ServerPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: '好友',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: '聊天',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dns),
            label: '伺服器',
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return '好友';
      case 1:
        return '聊天';
      case 2:
        return '伺服器';
      default:
        return '應用程式';
    }
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
            title: Text('好友'),
            selected: _selectedIndex == 0,
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 0);
            },
          ),
          ListTile(
            leading: Icon(Icons.chat),
            title: Text('聊天'),
            selected: _selectedIndex == 1,
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 1);
            },
          ),
          ListTile(
            leading: Icon(Icons.dns),
            title: Text('伺服器'),
            selected: _selectedIndex == 2,
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 2);
            },
          ),
          Divider(),
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
        ],
      ),
    );
  }
}
