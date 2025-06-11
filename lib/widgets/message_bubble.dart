import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/model.dart';
import '../services/media_service.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final String? username;
  final String? avatarUrl;

  const MessageBubble({
    required this.message,
    required this.isMe,
    this.username,
    this.avatarUrl,
  });

  @override
  _MessageBubbleState createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.message.messageType == 'video' && widget.message.videoUrl != null) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.network(widget.message.videoUrl!);
      await _videoController!.initialize();
      setState(() {
        _isVideoInitialized = true;
      });
    } catch (e) {
      print('影片初始化失敗: $e');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!widget.isMe && widget.avatarUrl != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundImage: CachedNetworkImageProvider(widget.avatarUrl!),
              ),
            ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 12,
              ),
              decoration: BoxDecoration(
                color: widget.isMe
                    ? theme.primaryColor
                    : theme.cardColor,
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
                  if (!widget.isMe && widget.username != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        widget.username!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: widget.isMe ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  _buildMessageContent(),
                  SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(widget.message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: widget.isMe ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (widget.message.messageType) {
      case 'image':
        return _buildImageMessage();
      case 'video':
        return _buildVideoMessage();
      case 'file':
        return _buildFileMessage();
      default:
        return Text(
          widget.message.content,
          style: TextStyle(
            color: widget.isMe ? Colors.white : Colors.black,
          ),
        );
    }
  }

  Widget _buildImageMessage() {
    if (widget.message.imageUrl == null) {
      return Text('圖片載入失敗', style: TextStyle(color: Colors.red));
    }

    return GestureDetector(
      onTap: () => _showImageDialog(widget.message.imageUrl!),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: widget.message.imageUrl!,
          placeholder: (context, url) => Container(
            width: 200,
            height: 150,
            color: Colors.grey[300],
            child: Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            width: 200,
            height: 150,
            color: Colors.grey[300],
            child: Icon(Icons.error, color: Colors.red),
          ),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildVideoMessage() {
    if (widget.message.videoUrl == null) {
      return Text('影片載入失敗', style: TextStyle(color: Colors.red));
    }

    if (!_isVideoInitialized || _videoController == null) {
      return Container(
        width: 200,
        height: 150,
        color: Colors.grey[300],
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: () => _showVideoDialog(widget.message.videoUrl!),
      child: Container(
        width: 200,
        height: 150,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 50,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileMessage() {
    final mediaService = MediaService();
    final fileIcon = mediaService.getFileIcon(widget.message.fileName ?? '');
    final fileSize = widget.message.fileSize != null 
        ? mediaService.formatFileSize(int.parse(widget.message.fileSize!))
        : '';

    return GestureDetector(
      onTap: () => _downloadFile(widget.message.fileUrl!),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.isMe ? Colors.white24 : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(fileIcon, style: TextStyle(fontSize: 24)),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.message.fileName ?? '未知檔案',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.isMe ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (fileSize.isNotEmpty)
                    Text(
                      fileSize,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isMe ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.download,
              color: widget.isMe ? Colors.white70 : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVideoDialog(String videoUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.6,
              child: VideoPlayer(_videoController!),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadFile(String fileUrl) async {
    try {
      if (await canLaunch(fileUrl)) {
        await launch(fileUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('無法開啟檔案')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('下載失敗: $e')),
      );
    }
  }
}