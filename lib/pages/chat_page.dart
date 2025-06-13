import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/model.dart';
import '../widgets/message_bubble.dart';
import '../services/media_service.dart';
import 'call_page.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<User?>(context);

    if (currentUser == null) {
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chats')
                .where('participants', arrayContains: currentUser.uid)
                .orderBy('lastMessageTime', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('錯誤: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.data?.docs.isEmpty ?? true) {
                return Center(child: Text('沒有聊天記錄'));
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

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: userData['avatarUrl'] != null && userData['avatarUrl'].isNotEmpty
                              ? NetworkImage(userData['avatarUrl'])
                              : null,
                          child: userData['avatarUrl'] == null || userData['avatarUrl'].isEmpty
                              ? Text(userData['username'][0].toUpperCase())
                              : null,
                        ),
                        title: Text(userData['username']),
                        subtitle: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          '${lastMessageTime.hour}:${lastMessageTime.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(color: Colors.grey),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatDetailScreen(
                                chatId: chat.id,
                                otherUserId: participants.first,
                                otherUserName: userData['username'],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatDetailScreen extends StatelessWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;

  const ChatDetailScreen({
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(otherUserName),
        actions: [
          // 語音通話按鈕
          IconButton(
            icon: const Icon(Icons.call, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CallPage(
                    targetUserId: otherUserId,
                    targetUserName: otherUserName,
                    callType: 'voice',
                  ),
                ),
              );
            },
            tooltip: '語音通話',
          ),
          // 視訊通話按鈕
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CallPage(
                    targetUserId: otherUserId,
                    targetUserName: otherUserName,
                    callType: 'video',
                  ),
                ),
              );
            },
            tooltip: '視訊通話',
          ),
        ],
      ),
      body: _ChatDetailBody(
        chatId: chatId,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
      ),
    );
  }
}

class _ChatDetailBody extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;

  const _ChatDetailBody({
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  __ChatDetailBodyState createState() => __ChatDetailBodyState();
}

class __ChatDetailBodyState extends State<_ChatDetailBody> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MediaService _mediaService = MediaService();
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<User?>(context);

    if (currentUser == null) {
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chats/${widget.chatId}/messages')
                .orderBy('timestamp', descending: false)
                .snapshots(),
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
                  return MessageBubble(
                    message: Message.fromMap(
                      message.data() as Map<String, dynamic>,
                      message.id,
                    ),
                    isMe: message['senderId'] == currentUser.uid,
                  );
                },
              );
            },
          ),
        ),
        _buildMessageInput(currentUser.uid),
      ],
    );
  }

  Widget _buildMessageInput(String currentUserId) {
    return Container(
      padding: EdgeInsets.all(8),
      color: Colors.grey[200],
      child: Column(
        children: [
          // 媒體選擇按鈕
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.photo_library, color: Colors.blue),
                onPressed: _isSending ? null : () => _sendImage(currentUserId),
                tooltip: '選擇圖片',
              ),
              IconButton(
                icon: Icon(Icons.camera_alt, color: Colors.blue),
                onPressed: _isSending ? null : () => _takePhoto(currentUserId),
                tooltip: '拍攝圖片',
              ),
              IconButton(
                icon: Icon(Icons.videocam, color: Colors.blue),
                onPressed: _isSending ? null : () => _sendVideo(currentUserId),
                tooltip: '選擇影片',
              ),
              IconButton(
                icon: Icon(Icons.attach_file, color: Colors.blue),
                onPressed: _isSending ? null : () => _sendFile(currentUserId),
                tooltip: '選擇檔案',
              ),
              Spacer(),
            ],
          ),
          // 訊息輸入區域
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: '輸入訊息...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  enabled: !_isSending,
                ),
              ),
              SizedBox(width: 8),
              IconButton(
                icon: _isSending 
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.send),
                color: Colors.blue,
                onPressed: _isSending ? null : () => _sendMessage(currentUserId),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String currentUserId) async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      final messageContent = _messageController.text.trim();
      _messageController.clear();

      await FirebaseFirestore.instance
          .collection('chats/${widget.chatId}/messages')
          .add({
        'senderId': currentUserId,
        'content': messageContent,
        'messageType': 'text',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'lastMessage': messageContent,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _messageController.text = _messageController.text;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('發送失敗: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _sendImage(String currentUserId) async {
    print('開始發送圖片...');
    setState(() {
      _isSending = true;
    });

    try {
      print('調用 MediaService.uploadImage()...');
      final imageUrl = await _mediaService.uploadImage();
      print('MediaService 返回: $imageUrl');
      
      if (imageUrl != null) {
        print('開始保存訊息到 Firestore...');
        await FirebaseFirestore.instance
            .collection('chats/${widget.chatId}/messages')
            .add({
          'senderId': currentUserId,
          'content': '圖片',
          'messageType': 'image',
          'imageUrl': imageUrl,
          'timestamp': FieldValue.serverTimestamp(),
        });

        print('更新聊天最後訊息...');
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatId)
            .update({
          'lastMessage': '圖片',
          'lastMessageTime': FieldValue.serverTimestamp(),
        });
        
        print('圖片發送成功！');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('圖片發送成功'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('圖片上傳失敗，返回 null');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('圖片上傳失敗，請檢查網路連接'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('圖片發送過程中發生錯誤: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('圖片發送失敗: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _takePhoto(String currentUserId) async {
    setState(() {
      _isSending = true;
    });

    try {
      final imageUrl = await _mediaService.takePhoto();
      if (imageUrl != null) {
        await FirebaseFirestore.instance
            .collection('chats/${widget.chatId}/messages')
            .add({
          'senderId': currentUserId,
          'content': '圖片',
          'messageType': 'image',
          'imageUrl': imageUrl,
          'timestamp': FieldValue.serverTimestamp(),
        });

        await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatId)
            .update({
          'lastMessage': '圖片',
          'lastMessageTime': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('圖片發送失敗: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _sendVideo(String currentUserId) async {
    setState(() {
      _isSending = true;
    });

    try {
      final videoUrl = await _mediaService.uploadVideo();
      if (videoUrl != null) {
        await FirebaseFirestore.instance
            .collection('chats/${widget.chatId}/messages')
            .add({
          'senderId': currentUserId,
          'content': '影片',
          'messageType': 'video',
          'videoUrl': videoUrl,
          'timestamp': FieldValue.serverTimestamp(),
        });

        await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatId)
            .update({
          'lastMessage': '影片',
          'lastMessageTime': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('影片發送失敗: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _sendFile(String currentUserId) async {
    setState(() {
      _isSending = true;
    });

    try {
      final fileData = await _mediaService.uploadFile();
      if (fileData != null) {
        await FirebaseFirestore.instance
            .collection('chats/${widget.chatId}/messages')
            .add({
          'senderId': currentUserId,
          'content': '檔案',
          'messageType': 'file',
          'fileUrl': fileData['url'],
          'fileName': fileData['fileName'],
          'fileSize': fileData['fileSize'],
          'timestamp': FieldValue.serverTimestamp(),
        });

        await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatId)
            .update({
          'lastMessage': '檔案: ${fileData['fileName']}',
          'lastMessageTime': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('檔案發送失敗: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}