import 'package:flutter/material.dart';
import '../services/media_service.dart';

class TestPage extends StatefulWidget {
  @override
  _TestPageState createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final MediaService _mediaService = MediaService();
  String _testResult = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('檔案功能測試'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _testFirebaseConnection,
              child: Text('測試 Firebase 連接'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testFileUpload,
              child: Text('測試檔案上傳'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testImageUpload,
              child: Text('測試圖片上傳'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testVideoUpload,
              child: Text('測試影片上傳'),
            ),
            SizedBox(height: 16),
            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else
              Container(),
            SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResult.isEmpty ? '測試結果將顯示在這裡' : _testResult,
                    style: TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testFirebaseConnection() async {
    setState(() {
      _isLoading = true;
      _testResult = '正在測試 Firebase 連接...\n';
    });

    try {
      final result = await _mediaService.testFirebaseConnection();
      setState(() {
        _testResult += result 
            ? '✅ Firebase 連接測試成功\n'
            : '❌ Firebase 連接測試失敗\n';
      });
    } catch (e) {
      setState(() {
        _testResult += '❌ Firebase 連接測試錯誤: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testFileUpload() async {
    setState(() {
      _isLoading = true;
      _testResult += '正在測試檔案上傳...\n';
    });

    try {
      final result = await _mediaService.testFileUploadAndDownload();
      setState(() {
        if (result['success']) {
          _testResult += '✅ 檔案上傳測試成功\n';
          _testResult += '上傳 URL: ${result['uploadUrl']}\n';
          _testResult += '訊息: ${result['message']}\n';
        } else {
          _testResult += '❌ 檔案上傳測試失敗\n';
          _testResult += '錯誤: ${result['error']}\n';
        }
      });
    } catch (e) {
      setState(() {
        _testResult += '❌ 檔案上傳測試錯誤: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testImageUpload() async {
    setState(() {
      _isLoading = true;
      _testResult += '正在測試圖片上傳...\n';
    });

    try {
      final imageUrl = await _mediaService.uploadImage();
      setState(() {
        if (imageUrl != null) {
          _testResult += '✅ 圖片上傳成功\n';
          _testResult += '圖片 URL: $imageUrl\n';
          
          // 驗證 URL
          _mediaService.validateFileUrl(imageUrl).then((isValid) {
            setState(() {
              _testResult += isValid 
                  ? '✅ 圖片 URL 驗證成功\n'
                  : '❌ 圖片 URL 驗證失敗\n';
            });
          });
        } else {
          _testResult += '❌ 圖片上傳失敗\n';
        }
      });
    } catch (e) {
      setState(() {
        _testResult += '❌ 圖片上傳錯誤: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testVideoUpload() async {
    setState(() {
      _isLoading = true;
      _testResult += '正在測試影片上傳...\n';
    });

    try {
      final videoUrl = await _mediaService.uploadVideo();
      setState(() {
        if (videoUrl != null) {
          _testResult += '✅ 影片上傳成功\n';
          _testResult += '影片 URL: $videoUrl\n';
          
          // 驗證 URL
          _mediaService.validateFileUrl(videoUrl).then((isValid) {
            setState(() {
              _testResult += isValid 
                  ? '✅ 影片 URL 驗證成功\n'
                  : '❌ 影片 URL 驗證失敗\n';
            });
          });
        } else {
          _testResult += '❌ 影片上傳失敗\n';
        }
      });
    } catch (e) {
      setState(() {
        _testResult += '❌ 影片上傳錯誤: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
} 