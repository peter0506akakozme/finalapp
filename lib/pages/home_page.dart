import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/model.dart';
import '../services/database_service.dart';
import 'auth_page.dart';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedServerIndex = 0;
  int _selectedChannelIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    if (user == null) return AuthPage();

    return Scaffold(
      body: Row(
        children: [
          // 服务器列表
          Container(
            width: 72,
            color: Colors.grey[900],
            child: Column(
              children: [
                _ServerButton(selected: true, onPressed: () {}),
                Divider(color: Colors.grey[800], indent: 12, endIndent: 12),
                Expanded(
                  child: StreamBuilder<List<Server>>(
                    stream: Provider.of<DatabaseService>(context)
                        .getUserServers(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      return ListView.builder(
                        itemCount: snapshot.data?.length ?? 0,
                        itemBuilder: (context, index) {
                          final server = snapshot.data![index];
                          return _ServerButton(
                            selected: _selectedServerIndex == index,
                            onPressed: () {
                              setState(() => _selectedServerIndex = index);
                            },
                            imageUrl: server.iconUrl,
                          );
                        },
                      );
                    },
                  ),
                ),
                _ServerButton(
                  icon: Icons.add,
                  onPressed: () {
                    _showCreateServerDialog(context, user.uid);
                  },
                ),
              ],
            ),
          ),

          // 频道列表
          Container(
            width: 240,
            color: Colors.grey[800],
            child: Column(
              children: [
                // 服务器名称
                Container(
                  height: 48,
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Server Name',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Divider(color: Colors.grey[700], height: 1),
                // 频道列表
                Expanded(
                  child: StreamBuilder<List<Channel>>(
                    stream: Provider.of<DatabaseService>(context)
                        .getServerChannels('server_id_here'),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      return ListView.builder(
                        itemCount: snapshot.data?.length ?? 0,
                        itemBuilder: (context, index) {
                          final channel = snapshot.data![index];
                          return ListTile(
                            selected: _selectedChannelIndex == index,
                            selectedTileColor: Colors.grey[700],
                            title: Text(
                              '# ${channel.name}',
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () {
                              setState(() => _selectedChannelIndex = index);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // 消息区域
          Expanded(
            child: Column(
              children: [
                // 消息标题栏
                Container(
                  height: 48,
                  color: Colors.grey[700],
                  child: Row(
                    children: [
                      Icon(Icons.tag, color: Colors.grey[400]),
                      SizedBox(width: 8),
                      Text(
                        'channel-name',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // 消息列表
                Expanded(
                  child: StreamBuilder<List<Message>>(
                    stream: Provider.of<DatabaseService>(context)
                        .getChannelMessages('channel_id_here'),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      return ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: snapshot.data?.length ?? 0,
                        itemBuilder: (context, index) {
                          final message = snapshot.data![index];
                          return _MessageWidget(message: message);
                        },
                      );
                    },
                  ),
                ),
                // 消息输入框
                _MessageInput(channelId: 'channel_id_here'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateServerDialog(BuildContext context, String ownerId) {
    final _nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Create New Server'),
          content: TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Server Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.isNotEmpty) {
                  await Provider.of<DatabaseService>(context, listen: false)
                      .createServer(_nameController.text, ownerId);
                  Navigator.pop(context);
                }
              },
              child: Text('Create'),
            ),
          ],
        );
      },
    );
  }
}

class _ServerButton extends StatelessWidget {
  final bool selected;
  final VoidCallback onPressed;
  final String? imageUrl;
  final IconData? icon;

  const _ServerButton({
    this.selected = false,
    required this.onPressed,
    this.imageUrl,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
        color: selected ? Colors.blue : Colors.grey[700],
        shape: CircleBorder(),
        child: IconButton(
          icon: icon != null
              ? Icon(icon, color: Colors.white)
              : (imageUrl != null && imageUrl!.isNotEmpty
              ? CircleAvatar(backgroundImage: NetworkImage(imageUrl!))
              : Icon(Icons.people, color: Colors.white)),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class _MessageWidget extends StatelessWidget {
  final Message message;

  const _MessageWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            // 这里应该使用用户头像
            child: Text(message.senderId.substring(0, 2)),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Username', // 这里应该显示用户名
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      DateFormat('HH:mm').format(message.timestamp),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  message.content,
                  style: TextStyle(color: Colors.white),
                ),
                if (message.imageUrl != null) ...[
                  SizedBox(height: 8),
                  CachedNetworkImage(
                    imageUrl: message.imageUrl!,
                    placeholder: (context, url) => CircularProgressIndicator(),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageInput extends StatefulWidget {
  final String channelId;

  const _MessageInput({required this.channelId});

  @override
  __MessageInputState createState() => __MessageInputState();
}

class __MessageInputState extends State<_MessageInput> {
  final _messageController = TextEditingController();
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      color: Colors.grey[700],
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message',
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.grey[600],
                contentPadding: EdgeInsets.all(12),
              ),
              style: TextStyle(color: Colors.white),
              onSubmitted: (text) => _sendMessage(text),
            ),
          ),
          IconButton(
            icon: _isUploading
                ? CircularProgressIndicator()
                : Icon(Icons.send, color: Colors.white),
            onPressed: () => _sendMessage(_messageController.text),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final user = Provider.of<User?>(context, listen: false);
    if (user == null) return;

    _messageController.clear();
    await Provider.of<DatabaseService>(context, listen: false).sendMessage(
      widget.channelId,
      user.uid,
      text,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}