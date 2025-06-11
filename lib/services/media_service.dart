import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class MediaService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // 選擇並上傳圖片
  Future<String?> uploadImage() async {
    try {
      print('開始選擇圖片...');
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
      );

      if (image == null) {
        print('用戶取消選擇圖片');
        return null;
      }

      print('已選擇圖片: ${image.path}');
      final downloadUrl = await _uploadFile(
        File(image.path),
        'images',
        'image',
      );
      
      print('圖片上傳完成: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('上傳圖片失敗: $e');
      return null;
    }
  }

  // 拍攝並上傳圖片
  Future<String?> takePhoto() async {
    try {
      print('開始拍攝圖片...');
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
      );

      if (image == null) {
        print('用戶取消拍攝圖片');
        return null;
      }

      print('已拍攝圖片: ${image.path}');
      final downloadUrl = await _uploadFile(
        File(image.path),
        'images',
        'image',
      );
      
      print('圖片上傳完成: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('拍攝圖片失敗: $e');
      return null;
    }
  }

  // 選擇並上傳影片
  Future<String?> uploadVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5), // 限制5分鐘
      );

      if (video == null) return null;

      return await _uploadFile(
        File(video.path),
        'videos',
        'video',
      );
    } catch (e) {
      print('上傳影片失敗: $e');
      return null;
    }
  }

  // 拍攝並上傳影片
  Future<String?> takeVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );

      if (video == null) return null;

      return await _uploadFile(
        File(video.path),
        'videos',
        'video',
      );
    } catch (e) {
      print('拍攝影片失敗: $e');
      return null;
    }
  }

  // 選擇並上傳檔案
  Future<Map<String, String>?> uploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return null;

      final file = File(result.files.first.path!);
      final fileName = result.files.first.name;
      final fileSize = result.files.first.size.toString();

      final downloadUrl = await _uploadFile(
        file,
        'files',
        'file',
        customFileName: fileName,
      );

      if (downloadUrl != null) {
        return {
          'url': downloadUrl,
          'fileName': fileName,
          'fileSize': fileSize,
        };
      }

      return null;
    } catch (e) {
      print('上傳檔案失敗: $e');
      return null;
    }
  }

  // 測試 Firebase 連接
  Future<bool> testFirebaseConnection() async {
    try {
      print('測試 Firebase Storage 連接...');
      final ref = _storage.ref().child('test/connection.txt');
      final metadata = SettableMetadata(
        contentType: 'text/plain',
        customMetadata: {'test': 'true'},
      );
      
      final testData = 'Firebase connection test';
      final uploadTask = ref.putData(
        Uint8List.fromList(testData.codeUnits),
        metadata,
      );
      
      await uploadTask;
      print('Firebase Storage 連接測試成功');
      return true;
    } catch (e) {
      print('Firebase Storage 連接測試失敗: $e');
      return false;
    }
  }

  // 簡化的檔案上傳方法 - 避免 Google Play Services 問題
  Future<String?> _uploadFile(
    File file,
    String folder,
    String type, {
    String? customFileName,
  }) async {
    try {
      print('開始上傳檔案...');
      print('檔案路徑: ${file.path}');
      print('檔案大小: ${await file.length()} bytes');
      
      final fileName = customFileName ?? path.basename(file.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = '$folder/$timestamp/$fileName';
      
      print('Storage 路徑: $storagePath');

      // 使用基本的 Storage 引用方式
      final ref = _storage.ref().child(storagePath);
      print('開始上傳到 Firebase Storage...');
      
      // 使用 putData 而不是 putFile，避免某些權限問題
      final bytes = await file.readAsBytes();
      final metadata = SettableMetadata(
        contentType: _getContentType(fileName),
        customMetadata: {
          'uploaded_at': DateTime.now().toIso8601String(),
          'file_type': type,
        },
      );
      
      final uploadTask = ref.putData(bytes, metadata);
      
      // 監聽上傳進度
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('上傳進度: ${(progress * 100).toStringAsFixed(1)}%');
      });
      
      final snapshot = await uploadTask;
      
      print('上傳完成，開始獲取下載連結...');
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('下載連結: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('檔案上傳失敗: $e');
      print('錯誤類型: ${e.runtimeType}');
      if (e is FirebaseException) {
        print('Firebase 錯誤代碼: ${e.code}');
        print('Firebase 錯誤訊息: ${e.message}');
        print('Firebase 錯誤平台: ${e.plugin}');
      }
      return null;
    }
  }

  // 獲取檔案內容類型
  String _getContentType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.mp4':
        return 'video/mp4';
      case '.avi':
        return 'video/avi';
      case '.mov':
        return 'video/quicktime';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
      case '.docx':
        return 'application/msword';
      case '.xls':
      case '.xlsx':
        return 'application/vnd.ms-excel';
      case '.txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  // 格式化檔案大小
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // 獲取檔案圖示
  String getFileIcon(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    
    switch (extension) {
      case '.pdf':
        return '📄';
      case '.doc':
      case '.docx':
        return '📝';
      case '.xls':
      case '.xlsx':
        return '📊';
      case '.ppt':
      case '.pptx':
        return '📈';
      case '.txt':
        return '📄';
      case '.zip':
      case '.rar':
      case '.7z':
        return '📦';
      case '.mp3':
      case '.wav':
      case '.flac':
        return '🎵';
      case '.mp4':
      case '.avi':
      case '.mov':
        return '🎬';
      default:
        return '📎';
    }
  }
} 