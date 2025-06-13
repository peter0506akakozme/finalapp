import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/call_service.dart';

class CallSettingsPage extends StatefulWidget {
  @override
  _CallSettingsPageState createState() => _CallSettingsPageState();
}

class _CallSettingsPageState extends State<CallSettingsPage> {
  final TextEditingController _appIdController = TextEditingController();
  final TextEditingController _appCertificateController = TextEditingController();
  final TextEditingController _signalingServerController = TextEditingController();
  
  bool _autoAcceptCalls = false;
  bool _showCallerId = true;
  bool _vibrateOnIncomingCall = true;
  bool _playRingtone = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    // 這裡可以從 SharedPreferences 或其他存儲中載入設定
    // 暫時使用預設值
    _appIdController.text = 'YOUR_AGORA_APP_ID';
    _appCertificateController.text = 'YOUR_AGORA_APP_CERTIFICATE';
    _signalingServerController.text = 'https://your-signaling-server.com';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通話設定'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Agora 設定
            _buildSectionHeader('Agora 設定'),
            _buildTextField(
              controller: _appIdController,
              label: 'App ID',
              hint: '輸入您的 Agora App ID',
              icon: Icons.vpn_key,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _appCertificateController,
              label: 'App Certificate',
              hint: '輸入您的 Agora App Certificate',
              icon: Icons.security,
              isPassword: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _signalingServerController,
              label: '信令伺服器',
              hint: '輸入您的信令伺服器 URL',
              icon: Icons.cloud_circle,
            ),
            
            const SizedBox(height: 32),
            
            // 通話設定
            _buildSectionHeader('通話設定'),
            _buildSwitchTile(
              title: '自動接聽通話',
              subtitle: '收到來電時自動接聽',
              value: _autoAcceptCalls,
              onChanged: (value) {
                setState(() {
                  _autoAcceptCalls = value;
                });
              },
            ),
            _buildSwitchTile(
              title: '顯示來電者資訊',
              subtitle: '在來電通知中顯示來電者姓名',
              value: _showCallerId,
              onChanged: (value) {
                setState(() {
                  _showCallerId = value;
                });
              },
            ),
            _buildSwitchTile(
              title: '來電震動',
              subtitle: '收到來電時震動提醒',
              value: _vibrateOnIncomingCall,
              onChanged: (value) {
                setState(() {
                  _vibrateOnIncomingCall = value;
                });
              },
            ),
            _buildSwitchTile(
              title: '來電鈴聲',
              subtitle: '收到來電時播放鈴聲',
              value: _playRingtone,
              onChanged: (value) {
                setState(() {
                  _playRingtone = value;
                });
              },
            ),
            
            const SizedBox(height: 32),
            
            // 音訊設定
            _buildSectionHeader('音訊設定'),
            _buildAudioSettings(),
            
            const SizedBox(height: 32),
            
            // 視訊設定
            _buildSectionHeader('視訊設定'),
            _buildVideoSettings(),
            
            const SizedBox(height: 32),
            
            // 測試按鈕
            _buildSectionHeader('測試'),
            _buildTestButtons(),
            
            const SizedBox(height: 32),
            
            // 保存按鈕
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '保存設定',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.blue,
    );
  }

  Widget _buildAudioSettings() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.mic),
          title: const Text('麥克風音量'),
          subtitle: const Text('調整麥克風輸入音量'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            _showVolumeDialog('麥克風音量', 0.5);
          },
        ),
        ListTile(
          leading: const Icon(Icons.volume_up),
          title: const Text('揚聲器音量'),
          subtitle: const Text('調整揚聲器輸出音量'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            _showVolumeDialog('揚聲器音量', 0.7);
          },
        ),
        ListTile(
          leading: const Icon(Icons.noise_control_off),
          title: const Text('噪音抑制'),
          subtitle: const Text('啟用噪音抑制功能'),
          trailing: Switch(
            value: true,
            onChanged: (value) {},
            activeColor: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildVideoSettings() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.videocam),
          title: const Text('視訊品質'),
          subtitle: const Text('選擇視訊通話品質'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            _showVideoQualityDialog();
          },
        ),
        ListTile(
          leading: const Icon(Icons.camera_alt),
          title: const Text('預設攝影機'),
          subtitle: const Text('選擇預設使用的攝影機'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            _showCameraSelectionDialog();
          },
        ),
        ListTile(
          leading: const Icon(Icons.face),
          title: const Text('美顏效果'),
          subtitle: const Text('啟用視訊美顏效果'),
          trailing: Switch(
            value: false,
            onChanged: (value) {},
            activeColor: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildTestButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _testMicrophone,
            icon: const Icon(Icons.mic),
            label: const Text('測試麥克風'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _testCamera,
            icon: const Icon(Icons.camera_alt),
            label: const Text('測試攝影機'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _testConnection,
            icon: const Icon(Icons.wifi),
            label: const Text('測試網路連接'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _showVolumeDialog(String title, double initialValue) {
    double currentValue = initialValue;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: currentValue,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: '${(currentValue * 100).round()}%',
                onChanged: (value) {
                  setState(() {
                    currentValue = value;
                  });
                },
              ),
              Text('${(currentValue * 100).round()}%'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              // 保存音量設定
              Navigator.pop(context);
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  void _showVideoQualityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('視訊品質'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('低品質 (240p)'),
              subtitle: const Text('節省流量'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('已設定為低品質視訊');
              },
            ),
            ListTile(
              title: const Text('中品質 (480p)'),
              subtitle: const Text('平衡品質與流量'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('已設定為中品質視訊');
              },
            ),
            ListTile(
              title: const Text('高品質 (720p)'),
              subtitle: const Text('最佳視訊品質'),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('已設定為高品質視訊');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCameraSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('選擇攝影機'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('前置攝影機'),
              leading: const Icon(Icons.camera_front),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('已設定為前置攝影機');
              },
            ),
            ListTile(
              title: const Text('後置攝影機'),
              leading: const Icon(Icons.camera_rear),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('已設定為後置攝影機');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _testMicrophone() {
    _showSnackBar('正在測試麥克風...');
    // 這裡可以實現麥克風測試邏輯
  }

  void _testCamera() {
    _showSnackBar('正在測試攝影機...');
    // 這裡可以實現攝影機測試邏輯
  }

  void _testConnection() {
    _showSnackBar('正在測試網路連接...');
    // 這裡可以實現網路連接測試邏輯
  }

  void _saveSettings() {
    // 保存設定到 SharedPreferences 或其他存儲
    _showSnackBar('設定已保存');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  void dispose() {
    _appIdController.dispose();
    _appCertificateController.dispose();
    _signalingServerController.dispose();
    super.dispose();
  }
} 