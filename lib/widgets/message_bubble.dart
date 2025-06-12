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
      print('開始初始化影片: ${widget.message.videoUrl}');
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.message.videoUrl!));
      await _videoController!.initialize();
      setState(() {
        _isVideoInitialized = true;
      });
      print('影片初始化成功');
    } catch (e) {
      print('影片初始化失敗: $e');
      setState(() {
        _isVideoInitialized = false;
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!widget.isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(widget.avatarUrl!)
                  : null,
              child: widget.avatarUrl == null || widget.avatarUrl!.isEmpty
                  ? Text(widget.username?.substring(0, 1).toUpperCase() ?? 'U')
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isMe ? Colors.blue : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
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
                  const SizedBox(height: 4),
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
          if (widget.isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundImage: widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(widget.avatarUrl!)
                  : null,
              child: widget.avatarUrl == null || widget.avatarUrl!.isEmpty
                  ? const Text('我')
                  : null,
            ),
          ],
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
      return Container(
        width: 200,
        height: 150,
        color: Colors.grey[300],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 32),
              SizedBox(height: 8),
              Text('圖片載入失敗', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      );
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
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 32),
                  SizedBox(height: 8),
                  Text('圖片載入失敗', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildVideoMessage() {
    if (widget.message.videoUrl == null) {
      return Container(
        width: 200,
        height: 150,
        color: Colors.grey[300],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 32),
              SizedBox(height: 8),
              Text('影片載入失敗', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      );
    }

    if (!_isVideoInitialized || _videoController == null) {
      return Container(
        width: 200,
        height: 150,
        color: Colors.grey[300],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text('載入影片中...', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
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
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => Container(
                  width: 300,
                  height: 300,
                  color: Colors.grey[300],
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 300,
                  height: 300,
                  color: Colors.grey[300],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 48),
                        SizedBox(height: 16),
                        Text('圖片載入失敗', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVideoDialog(String videoUrl) {
    if (_videoController == null || !_isVideoInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('影片尚未載入完成')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                children: [
                  Expanded(
                    child: VideoPlayer(_videoController!),
                  ),
                  VideoProgressIndicator(
                    _videoController!,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: Colors.red,
                      bufferedColor: Colors.grey,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_videoController!.value.isPlaying) {
                              _videoController!.pause();
                            } else {
                              _videoController!.play();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () {
                  _videoController!.pause();
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadFile(String fileUrl) async {
    try {
      print('嘗試開啟檔案: $fileUrl');
      
      // 檢查 URL 是否有效
      if (fileUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('檔案連結無效')),
        );
        return;
      }

      // 嘗試使用 url_launcher 開啟檔案
      final Uri uri = Uri.parse(fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // 如果無法直接開啟，顯示錯誤訊息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('無法開啟此檔案類型，請使用瀏覽器開啟'),
            action: SnackBarAction(
              label: '複製連結',
              onPressed: () {
                // 這裡可以實作複製連結到剪貼簿的功能
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('連結已複製到剪貼簿')),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('檔案開啟失敗: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('檔案開啟失敗: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}