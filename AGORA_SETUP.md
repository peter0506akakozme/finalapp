# Agora 通話功能設定指南

## 📋 前置需求

1. **Agora 帳號**：前往 https://www.agora.io/ 註冊免費帳號
2. **Flutter 專案**：確保您的專案已安裝必要的依賴套件
3. **Android/iOS 權限**：確保已設定相應的權限

## 🚀 設定步驟

### 步驟 1：註冊 Agora 帳號

1. 前往 https://www.agora.io/
2. 點擊「註冊」或「Sign Up」
3. 填寫您的電子郵件和密碼
4. 驗證您的電子郵件地址

### 步驟 2：創建專案

1. 登入 Agora Console
2. 點擊「創建專案」或「Create Project」
3. 輸入專案名稱（例如：ChatApp）
4. 選擇「RTC」服務
5. 點擊「創建」

### 步驟 3：獲取憑證

1. 在專案詳情頁面找到：
   - **App ID**：一串數字和字母的組合（例如：1234567890abcdef1234567890abcdef）
   - **App Certificate**：用於生成 Token 的憑證

2. 複製這些憑證資訊

### 步驟 4：更新程式碼

1. 開啟 `lib/services/call_service.dart`
2. 找到以下設定區域：

```dart
// ========================================
// 🔧 請在這裡設定您的 Agora 憑證
// ========================================
static const String appId = 'YOUR_AGORA_APP_ID';
static const String appCertificate = 'YOUR_AGORA_APP_CERTIFICATE';
static const String signalingServerUrl = 'https://your-signaling-server.com';
// ========================================
```

3. 將 `YOUR_AGORA_APP_ID` 替換為您的真實 App ID
4. 將 `YOUR_AGORA_APP_CERTIFICATE` 替換為您的真實 App Certificate

### 步驟 5：設定信令伺服器（可選）

如果您需要來電通知功能，您需要設定一個信令伺服器：

1. 將 `signalingServerUrl` 替換為您的信令伺服器 URL
2. 或者暫時保持預設值，來電功能將無法使用

## 🔧 Token 生成

### 開發階段（簡單設定）

在開發階段，您可以使用簡單的 Token 生成方式：

```dart
Future<String> _generateToken(String channelName) async {
  // 開發階段使用簡單 Token
  return 'test_token_$channelName';
}
```

### 生產環境（推薦）

在生產環境中，您應該實現服務器端 Token 生成：

1. 使用 Agora Token Builder
2. 或實現自己的 Token 生成服務器
3. 參考：https://docs.agora.io/en/Video/token_server

## 📱 權限設定

### Android 權限

確保 `android/app/src/main/AndroidManifest.xml` 包含：

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.VIBRATE" />
```

### iOS 權限

確保 `ios/Runner/Info.plist` 包含：

```xml
<key>NSCameraUsageDescription</key>
<string>此應用程式需要相機權限來進行視訊通話</string>
<key>NSMicrophoneUsageDescription</key>
<string>此應用程式需要麥克風權限來進行語音通話</string>
```

## 🧪 測試

### 1. 基本功能測試

1. 啟動應用程式
2. 進入聊天頁面
3. 點擊語音或視訊通話按鈕
4. 檢查控制台輸出是否有錯誤訊息

### 2. 通話測試

1. 在兩個設備上安裝應用程式
2. 使用不同的帳號登入
3. 嘗試發起通話
4. 測試接受/拒絕通話功能

### 3. 權限測試

1. 確保應用程式有相機和麥克風權限
2. 測試靜音、視訊開關等功能

## ❗ 常見問題

### 錯誤 -7 (AgoraRtcException)

**原因**：App ID 或 Token 無效
**解決方案**：
1. 檢查 App ID 是否正確設定
2. 確保 Token 生成邏輯正確
3. 檢查網路連接

### 權限錯誤

**原因**：缺少必要的權限
**解決方案**：
1. 檢查 AndroidManifest.xml 和 Info.plist
2. 確保在運行時請求權限
3. 檢查設備設定中的應用程式權限

### 視訊無法顯示

**原因**：相機權限或設定問題
**解決方案**：
1. 檢查相機權限
2. 確保設備有前置相機
3. 檢查 Agora 引擎初始化

## 📞 支援

如果遇到問題：

1. 檢查 Agora 官方文件：https://docs.agora.io/
2. 查看 Flutter 插件文件：https://pub.dev/packages/agora_rtc_engine
3. 在 Agora 社群尋求幫助

## 🔄 更新日誌

- **v1.0**：初始版本，支援基本語音和視訊通話
- **v1.1**：新增來電通知功能
- **v1.2**：改善錯誤處理和使用者體驗 