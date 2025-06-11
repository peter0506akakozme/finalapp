import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import '../models/model.dart';
import '../services/chat_service.dart';
import '../widgets/enhanced_message_bubble.dart';

class EnhancedChatPage extends StatefulWidget {
  @override
  _EnhancedChatPageState createState() => _EnhancedChatPageState();
}

class _EnhancedChatPageState extends State<EnhancedChatPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _chatService.initializeNotifications();
    _chatService.updateOnlineStatus(true);
  }

  @override
  void dispose() {
    _chatService.updateOnlineStatus(false);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<User?>(context);

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text('聊天')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('聊天'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // 實作搜尋功能
            },
          ),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {
              _showChatOptions();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getChatsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('錯誤: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.data?.docs.isEmpty ?? true) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('沒有聊天記錄', style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            _showNewChatDialog();
                          },
                          child: Text('開始新聊天'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var chat = snapshot.data!.docs[index];
                    var participants = List<String>.from(chat['participants']);
                    participants.remove(currentUser.uid);

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(participants.first)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return ListTile(
                            title: Text('載入中...'),
                          );
                        }

                        var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                        var lastMessage = chat['lastMessage'] ?? '';
                        var lastMessageTime = (chat['lastMessageTime'] as Timestamp).toDate();

                        return _buildChatTile(
                          chat.id,
                          userData,
                          lastMessage,
                          lastMessageTime,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showNewChatDialog();
        },
        child: Icon(Icons.chat),
        tooltip: '新聊天',
      ),
    );
  }

  Widget _buildChatTile(String chatId, Map<String, dynamic> userData, String lastMessage, DateTime lastMessageTime) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundImage: userData['avatarUrl'] != null && userData['avatarUrl'].isNotEmpty
                ? NetworkImage(userData['avatarUrl'])
                : null,
            child: userData['avatarUrl'] == null || userData['avatarUrl'].isEmpty
                ? Text(userData['username'][0].toUpperCase())
                : null,
          ),
          // 在線狀態指示器
          StreamBuilder<DocumentSnapshot>(
            stream: _chatService.getUserOnlineStatus(userData['uid']),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                final isOnline = data['isOnline'] ?? false;
                
                return Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                );
              }
              return SizedBox.shrink();
            },
          ),
        ],
      ),
      title: Text(userData['username']),
      subtitle: Text(
        lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${lastMessageTime.hour}:${lastMessageTime.minute.toString().padLeft(2, '0')}',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          // 未讀訊息計數
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chats/$chatId/messages')
                .where('senderId', isNotEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .where('readBy', whereNotIn: [[FirebaseAuth.instance.currentUser?.uid]])
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                return Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${snapshot.data!.docs.length}',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                );
              }
              return SizedBox.shrink();
            },
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EnhancedChatDetailScreen(
              chatId: chatId,
              otherUserId: userData['uid'],
              otherUserName: userData['username'],
            ),
          ),
        );
      },
    );
  }

  void _showNewChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('開始新聊天'),
        content: TextField(
          decoration: InputDecoration(
            hintText: '輸入用戶名稱或電子郵件',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) async {
            // 實作搜尋用戶功能
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () {
              // 實作搜尋用戶功能
              Navigator.pop(context);
            },
            child: Text('搜尋'),
          ),
        ],
      ),
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.group_add),
              title: Text('創建群組聊天'),
              onTap: () {
                Navigator.pop(context);
                // 實作創建群組聊天
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('聊天設定'),
              onTap: () {
                Navigator.pop(context);
                // 實作聊天設定
              },
            ),
          ],
        ),
      ),
    );
  }
}

class EnhancedChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;

  const EnhancedChatDetailScreen({
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  _EnhancedChatDetailScreenState createState() => _EnhancedChatDetailScreenState();
}

class _EnhancedChatDetailScreenState extends State<EnhancedChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<User?>(context);

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.otherUserName)),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: _chatService.getUserOnlineStatus(widget.otherUserId),
              builder: (context, snapshot) {
                bool isOnline = false;
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  isOnline = data['isOnline'] ?? false;
                }
                
                return Row(
                  children: [
                    CircleAvatar(
                      child: Text(widget.otherUserName[0].toUpperCase()),
                    ),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.otherUserName),
                        Text(
                          isOnline ? '在線' : '離線',
                          style: TextStyle(
                            fontSize: 12,
                            color: isOnline ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.call),
            onPressed: () {
              // 實作語音通話
            },
          ),
          IconButton(
            icon: Icon(Icons.videocam),
            onPressed: () {
              // 實作視訊通話
            },
          ),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {
              _showMessageOptions();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessagesStream(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('錯誤: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                WidgetsBinding.instance?.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: snapshot.data?.docs.length ?? 0,
                  itemBuilder: (context, index) {
                    var message = snapshot.data!.docs[index];
                    var messageData = message.data() as Map<String, dynamic>;
                    
                    // 標記訊息為已讀
                    if (messageData['senderId'] != currentUser.uid) {
                      _chatService.markMessageAsRead(widget.chatId, message.id);
                    }

                    return EnhancedMessageBubble(
                      message: Message.fromMap(messageData, message.id),
                      isMe: messageData['senderId'] == currentUser.uid,
                      onLongPress: () {
                        _showMessageActionSheet(message.id, messageData);
                      },
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(currentUser.uid),
        ],
      ),
    );
  }

  Widget _buildMessageInput(String currentUserId) {
    return Container(
      padding: EdgeInsets.all(8),
      color: Colors.grey[200],
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attach_file),
            onPressed: () {
              _showAttachmentOptions();
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: '輸入訊息...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onChanged: (value) {
                // 實作輸入狀態
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            color: Colors.blue,
            onPressed: () async {
              if (_messageController.text.trim().isEmpty) return;

              await _chatService.sendMessage(
                widget.chatId,
                _messageController.text.trim(),
              );

              _messageController.clear();
            },
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo),
              title: Text('拍照'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.image),
              title: Text('從相簿選擇'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.file_copy),
              title: Text('選擇檔案'),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      try {
        final imageUrl = await _chatService.uploadImage(file);
        await _chatService.sendMessage(
          widget.chatId,
          '圖片',
          imageUrl: imageUrl,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上傳圖片失敗: $e')),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        File file = File(result.files.single.path!);
        // 實作檔案上傳
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('檔案上傳功能開發中')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('選擇檔案失敗: $e')),
      );
    }
  }

  void _showMessageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.search),
              title: Text('搜尋訊息'),
              onTap: () {
                Navigator.pop(context);
                // 實作搜尋訊息
              },
            ),
            ListTile(
              leading: Icon(Icons.block),
              title: Text('封鎖用戶'),
              onTap: () {
                Navigator.pop(context);
                // 實作封鎖用戶
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageActionSheet(String messageId, Map<String, dynamic> messageData) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (messageData['senderId'] == currentUser.uid)
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('刪除訊息'),
                onTap: () {
                  Navigator.pop(context);
                  _chatService.deleteMessage(widget.chatId, messageId);
                },
              ),
            ListTile(
              leading: Icon(Icons.copy),
              title: Text('複製訊息'),
              onTap: () {
                Navigator.pop(context);
                // 實作複製訊息
              },
            ),
          ],
        ),
      ),
    );
  }
}
