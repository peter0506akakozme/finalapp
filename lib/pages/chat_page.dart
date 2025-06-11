import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/model.dart';
import '../widgets/message_bubble.dart';

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
      child: Row(
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
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.send),
            color: Colors.blue,
            onPressed: () async {
              if (_messageController.text.trim().isEmpty) return;

              await FirebaseFirestore.instance
                  .collection('chats/${widget.chatId}/messages')
                  .add({
                'senderId': currentUserId,
                'content': _messageController.text.trim(),
                'timestamp': FieldValue.serverTimestamp(),
              });

              // 更新聊天的最後訊息
              await FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .update({
                'lastMessage': _messageController.text.trim(),
                'lastMessageTime': FieldValue.serverTimestamp(),
              });

              _messageController.clear();
            },
          ),
        ]),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}