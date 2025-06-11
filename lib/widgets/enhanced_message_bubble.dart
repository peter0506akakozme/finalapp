import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/model.dart';

class EnhancedMessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final String? username;
  final String? avatarUrl;
  final VoidCallback? onLongPress;

  const EnhancedMessageBubble({
    required this.message,
    required this.isMe,
    this.username,
    this.avatarUrl,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe && avatarUrl != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(avatarUrl!)
                    : null,
                child: (avatarUrl == null || avatarUrl!.isEmpty)
                    ? Text(username != null && username!.isNotEmpty ? username![0].toUpperCase() : '?')
                    : null,
              ),
            ),
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: isMe ? theme.primaryColor : theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMe && username != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          username!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: message.imageUrl!,
                            width: 180,
                            height: 180,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 180,
                              height: 180,
                              color: Colors.grey[300],
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                    if (message.content.isNotEmpty)
                      Text(
                        message.content,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black,
                        ),
                      ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(message.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                        SizedBox(width: 4),
                        if (isMe)
                          Icon(
                            message.isRead == true ? Icons.done_all : Icons.done,
                            size: 14,
                            color: message.isRead == true ? Colors.blue : Colors.white70,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 