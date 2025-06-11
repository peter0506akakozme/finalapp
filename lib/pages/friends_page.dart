import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/model.dart';
import '../services/friend_service.dart';
import '../services/chat_service.dart';
import '../pages/chat_page.dart';

class FriendsPage extends StatefulWidget {
  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> with SingleTickerProviderStateMixin {
  final FriendService _friendService = FriendService();
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  
  late TabController _tabController;
  List<UserModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _friendService.searchUsers(query.trim());
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('搜尋失敗: $e')),
      );
    }
  }

  Future<void> _sendFriendRequest(String userId) async {
    final success = await _friendService.sendFriendRequest(userId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('好友請求已發送')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('無法發送好友請求')),
      );
    }
  }

  Future<void> _startChat(String friendId, String friendName) async {
    try {
      final chatId = await _chatService.createOrGetChat(friendId);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            chatId: chatId,
            otherUserId: friendId,
            otherUserName: friendName,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('無法開始聊天: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('好友'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: '好友'),
            Tab(text: '搜尋'),
            Tab(text: '請求'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsTab(),
          _buildSearchTab(),
          _buildRequestsTab(),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    return StreamBuilder<List<UserModel>>(
      stream: _friendService.getFriends(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('錯誤: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final friends = snapshot.data ?? [];

        if (friends.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('還沒有好友', style: TextStyle(color: Colors.grey)),
                SizedBox(height: 16),
                Text('搜尋並添加好友開始聊天吧！', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return _buildFriendTile(friend);
          },
        );
      },
    );
  }

  Widget _buildFriendTile(UserModel friend) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: friend.avatarUrl.isNotEmpty
            ? CachedNetworkImageProvider(friend.avatarUrl)
            : null,
        child: friend.avatarUrl.isEmpty
            ? Text(friend.username[0].toUpperCase())
            : null,
      ),
      title: Text(friend.username),
      subtitle: Text(friend.isOnline ? '在線' : '離線'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.chat),
            onPressed: () => _startChat(friend.uid, friend.username),
          ),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () => _showFriendOptions(friend),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜尋用戶名稱或電子郵件',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (value) {
              if (value.length >= 2) {
                _searchUsers(value);
              } else {
                setState(() {
                  _searchResults = [];
                });
              }
            },
          ),
        ),
        Expanded(
          child: _isSearching
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return _buildSearchResultTile(user);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchResultTile(UserModel user) {
    return FutureBuilder<bool>(
      future: _friendService.isFriend(user.uid),
      builder: (context, snapshot) {
        final isFriend = snapshot.data ?? false;
        
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: user.avatarUrl.isNotEmpty
                ? CachedNetworkImageProvider(user.avatarUrl)
                : null,
            child: user.avatarUrl.isEmpty
                ? Text(user.username[0].toUpperCase())
                : null,
          ),
          title: Text(user.username),
          subtitle: Text(user.email),
          trailing: isFriend
              ? Chip(label: Text('已是好友'))
              : ElevatedButton(
                  onPressed: () => _sendFriendRequest(user.uid),
                  child: Text('添加好友'),
                ),
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    return StreamBuilder<List<FriendRequest>>(
      stream: _friendService.getReceivedFriendRequests(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('錯誤: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('沒有待處理的好友請求', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _buildRequestTile(request);
          },
        );
      },
    );
  }

  Widget _buildRequestTile(FriendRequest request) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(request.fromUserId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return ListTile(
            title: Text('未知用戶'),
            subtitle: Text('用戶不存在'),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final username = userData['username'] ?? '未知用戶';

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: userData['avatarUrl'] != null && userData['avatarUrl'].isNotEmpty
                ? CachedNetworkImageProvider(userData['avatarUrl'])
                : null,
            child: (userData['avatarUrl'] == null || userData['avatarUrl'].isEmpty)
                ? Text(username[0].toUpperCase())
                : null,
          ),
          title: Text(username),
          subtitle: Text('想要添加您為好友'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.check, color: Colors.green),
                onPressed: () => _acceptFriendRequest(request.id),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.red),
                onPressed: () => _rejectFriendRequest(request.id),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _acceptFriendRequest(String requestId) async {
    final success = await _friendService.acceptFriendRequest(requestId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已接受好友請求')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('無法接受好友請求')),
      );
    }
  }

  Future<void> _rejectFriendRequest(String requestId) async {
    final success = await _friendService.rejectFriendRequest(requestId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已拒絕好友請求')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('無法拒絕好友請求')),
      );
    }
  }

  void _showFriendOptions(UserModel friend) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.chat),
              title: Text('發送訊息'),
              onTap: () {
                Navigator.pop(context);
                _startChat(friend.uid, friend.username);
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('查看資料'),
              onTap: () {
                Navigator.pop(context);
                // 實作查看用戶資料
              },
            ),
            ListTile(
              leading: Icon(Icons.remove_circle, color: Colors.red),
              title: Text('移除好友', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showRemoveFriendDialog(friend);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveFriendDialog(UserModel friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('移除好友'),
        content: Text('確定要移除 ${friend.username} 嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _friendService.removeFriend(friend.uid);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已移除好友')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('無法移除好友')),
                );
              }
            },
            child: Text('移除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
} 