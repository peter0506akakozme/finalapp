

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/model.dart';
import 'channel_page.dart';

class ServerPage extends StatelessWidget {
  const ServerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<User?>(context);

    if (currentUser == null) {
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () => _showCreateServerDialog(context, currentUser.uid),
            child: Text('創建新伺服器'),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('servers')
                .where('members', arrayContains: currentUser.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('錯誤: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              return GridView.builder(
                padding: EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: snapshot.data?.docs.length ?? 0,
                itemBuilder: (context, index) {
                  var server = snapshot.data!.docs[index];
                  return _ServerCard(
                    server: Server.fromMap(server.data() as Map<String, dynamic>, server.id),
                    onTap: () async {
                      // 獲取伺服器的第一個頻道
                      final channelSnapshot = await FirebaseFirestore.instance
                          .collection('servers/${server.id}/channels')
                          .limit(1)
                          .get();

                      if (channelSnapshot.docs.isNotEmpty) {
                        final channel = channelSnapshot.docs.first;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChannelPage(
                              serverId: server.id,
                              channelId: channel.id,
                              channelName: channel['name'],
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('此伺服器沒有頻道')),
                        );
                      }
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

  void _showCreateServerDialog(BuildContext context, String ownerId) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('創建新伺服器'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: '伺服器名稱'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('servers').add({
                    'name': nameController.text,
                    'ownerId': ownerId,
                    'members': [ownerId],
                    'iconUrl': '',
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context);
                }
              },
              child: Text('創建'),
            ),
          ],
        );
      },
    );
  }
}

class _ServerCard extends StatelessWidget {
  final Server server;
  final VoidCallback onTap;

  const _ServerCard({required this.server, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: server.iconUrl.isNotEmpty
                  ? NetworkImage(server.iconUrl)
                  : null,
              child: server.iconUrl.isEmpty
                  ? Text(server.name[0].toUpperCase())
                  : null,
            ),
            SizedBox(height: 8),
            Text(
              server.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}