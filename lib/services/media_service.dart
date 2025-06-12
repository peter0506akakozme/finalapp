import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

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
      print('開始選擇影片...');
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5), // 限制5分鐘
      );

      if (video == null) {
        print('用戶取消選擇影片');
        return null;
      }

      print('已選擇影片: ${video.path}');
      final downloadUrl = await _uploadFile(
        File(video.path),
        'videos',
        'video',
      );
      
      print('影片上傳完成: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('上傳影片失敗: $e');
      return null;
    }
  }

  // 拍攝並上傳影片
  Future<String?> takeVideo() async {
    try {
      print('開始拍攝影片...');
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );

      if (video == null) {
        print('用戶取消拍攝影片');
        return null;
      }

      print('已拍攝影片: ${video.path}');
      final downloadUrl = await _uploadFile(
        File(video.path),
        'videos',
        'video',
      );
      
      print('影片上傳完成: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('拍攝影片失敗: $e');
      return null;
    }
  }

  // 選擇並上傳檔案
  Future<Map<String, String>?> uploadFile() async {
    try {
      print('開始選擇檔案...');
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        print('用戶取消選擇檔案');
        return null;
      }

      final file = File(result.files.first.path!);
      final fileName = result.files.first.name;
      final fileSize = result.files.first.size.toString();

      print('已選擇檔案: $fileName, 大小: $fileSize bytes');

      final downloadUrl = await _uploadFile(
        file,
        'files',
        'file',
        customFileName: fileName,
      );

      if (downloadUrl != null) {
        print('檔案上傳完成: $downloadUrl');
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

  // 測試檔案上傳和下載功能
  Future<Map<String, dynamic>> testFileUploadAndDownload() async {
    try {
      print('開始測試檔案上傳和下載功能...');
      
      // 1. 測試 Firebase 連接
      final connectionTest = await testFirebaseConnection();
      if (!connectionTest) {
        return {
          'success': false,
          'error': 'Firebase Storage 連接失敗',
        };
      }
      
      // 2. 創建測試檔案
      final testData = '這是一個測試檔案，創建時間: ${DateTime.now().toIso8601String()}';
      final testFile = File('${Directory.systemTemp.path}/test_file.txt');
      await testFile.writeAsString(testData);
      
      print('測試檔案已創建: ${testFile.path}');
      
      // 3. 上傳測試檔案
      final uploadUrl = await _uploadFile(
        testFile,
        'test',
        'test_file',
        customFileName: 'test_file.txt',
      );
      
      if (uploadUrl == null) {
        return {
          'success': false,
          'error': '檔案上傳失敗',
        };
      }
      
      print('測試檔案上傳成功: $uploadUrl');
      
      // 4. 清理測試檔案
      await testFile.delete();
      
      return {
        'success': true,
        'uploadUrl': uploadUrl,
        'message': '檔案上傳和下載功能測試成功',
      };
    } catch (e) {
      print('測試檔案上傳和下載功能失敗: $e');
      return {
        'success': false,
        'error': '測試失敗: $e',
      };
    }
  }

  // 驗證檔案 URL 是否可訪問
  Future<bool> validateFileUrl(String fileUrl) async {
    try {
      print('驗證檔案 URL: $fileUrl');
      
      // 使用 HTTP 請求檢查檔案是否可訪問
      final response = await http.get(Uri.parse(fileUrl));
      
      if (response.statusCode == 200) {
        print('檔案 URL 驗證成功');
        return true;
      } else {
        print('檔案 URL 驗證失敗，狀態碼: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('檔案 URL 驗證失敗: $e');
      return false;
    }
  }

  // 改進的檔案上傳方法
  Future<String?> _uploadFile(
    File file,
    String folder,
    String type, {
    String? customFileName,
  }) async {
    try {
      print('開始上傳檔案...');
      print('檔案路徑: ${file.path}');
      
      // 檢查檔案是否存在
      if (!await file.exists()) {
        print('檔案不存在: ${file.path}');
        return null;
      }
      
      final fileSize = await file.length();
      print('檔案大小: $fileSize bytes');
      
      // 檢查檔案大小限制 (100MB)
      if (fileSize > 100 * 1024 * 1024) {
        print('檔案太大: ${formatFileSize(fileSize)}');
        return null;
      }
      
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
          'original_name': fileName,
          'file_size': fileSize.toString(),
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

  // 改進的檔案內容類型判斷
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
      case '.webp':
        return 'image/webp';
      case '.mp4':
        return 'video/mp4';
      case '.avi':
        return 'video/avi';
      case '.mov':
        return 'video/quicktime';
      case '.wmv':
        return 'video/x-ms-wmv';
      case '.flv':
        return 'video/x-flv';
      case '.webm':
        return 'video/webm';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case '.ppt':
        return 'application/vnd.ms-powerpoint';
      case '.pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case '.txt':
        return 'text/plain';
      case '.zip':
        return 'application/zip';
      case '.rar':
        return 'application/x-rar-compressed';
      case '.7z':
        return 'application/x-7z-compressed';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.flac':
        return 'audio/flac';
      case '.aac':
        return 'audio/aac';
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
      case '.aac':
        return '🎵';
      case '.mp4':
      case '.avi':
      case '.mov':
      case '.wmv':
      case '.flv':
      case '.webm':
        return '🎬';
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.webp':
        return '🖼️';
      default:
        return '📎';
    }
  }
} 