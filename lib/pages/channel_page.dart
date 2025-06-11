import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/model.dart';
import '../widgets/message_bubble.dart';

class ChannelPage extends StatefulWidget {
  final String serverId;
  final String channelId;
  final String channelName;

  const ChannelPage({super.key,
    required this.serverId,
    required this.channelId,
    required this.channelName,
  });

  @override
  _ChannelPageState createState() => _ChannelPageState();
}

class _ChannelPageState extends State<ChannelPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<User?>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('#${widget.channelName}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('servers/${widget.serverId}/channels/${widget.channelId}/messages')
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
                  padding: EdgeInsets.all(8),
                  itemCount: snapshot.data?.docs.length ?? 0,
                  itemBuilder: (context, index) {
                    var message = snapshot.data!.docs[index];
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(message['senderId'])
                          .get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return SizedBox();
                        }

                        var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                        return MessageBubble(
                          message: Message.fromMap(
                            message.data() as Map<String, dynamic>,
                            message.id,
                          ),
                          isMe: message['senderId'] == currentUser?.uid,
                          username: userData['username'],
                          avatarUrl: userData['avatarUrl'],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(currentUser?.uid),
        ],
      ),
    );
  }

  Widget _buildMessageInput(String? currentUserId) {
    if (currentUserId == null) return SizedBox.shrink();

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
              .collection('servers/${widget.serverId}/channels/${widget.channelId}/messages')
              .add({
            'senderId': currentUserId,
            'content': _messageController.text.trim(),
            'timestamp': FieldValue.serverTimestamp(),
          });

          _messageController.clear();
        },
      ),
      ],
    ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}