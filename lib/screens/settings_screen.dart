import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/jarvis_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlCtrl;
  bool _testing = false;
  String? _testResult;
  bool? _testSuccess;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: JarvisApiService.instance.baseUrl);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await JarvisApiService.instance.saveSettings(_urlCtrl.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved'),
          backgroundColor: JarvisTheme.arcBlueDim,
        ),
      );
    }
  }

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    await JarvisApiService.instance.saveSettings(_urlCtrl.text.trim());
    final ok = await JarvisApiService.instance.ping();
    setState(() {
      _testing = false;
      _testSuccess = ok;
      _testResult = ok ? '✓ Connected to Jarvis!' : '✗ Could not reach server';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JarvisTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: JarvisTheme.bgDeep,
        foregroundColor: JarvisTheme.textPrimary,
        title: const Text(
          'SETTINGS',
          style: TextStyle(
            letterSpacing: 4,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: JarvisTheme.divider,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: 'SERVER CONFIGURATION',
              icon: Icons.dns_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jarvis API URL',
                    style: TextStyle(
                      color: JarvisTheme.textSecondary,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _urlCtrl,
                    style: const TextStyle(
                      color: JarvisTheme.textPrimary,
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'http://192.168.1.100:5000',
                      hintStyle: const TextStyle(
                          color: JarvisTheme.textDim, fontFamily: 'monospace'),
                      filled: true,
                      fillColor: JarvisTheme.bgCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: JarvisTheme.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: JarvisTheme.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: JarvisTheme.arcBlue),
                      ),
                      prefixIcon: const Icon(
                        Icons.link,
                        color: JarvisTheme.arcBlueDim,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _testing ? null : _test,
                          icon: _testing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: JarvisTheme.arcBlue,
                                  ),
                                )
                              : const Icon(Icons.wifi_tethering, size: 18),
                          label: Text(_testing ? 'Testing...' : 'Test Connection'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: JarvisTheme.arcBlue,
                            side: const BorderSide(color: JarvisTheme.arcBlue),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.save_outlined, size: 18),
                          label: const Text('Save'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: JarvisTheme.arcBlue,
                            foregroundColor: JarvisTheme.bgDeep,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_testResult != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (_testSuccess == true
                                ? JarvisTheme.arcBlue
                                : JarvisTheme.redAlert)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (_testSuccess == true
                                  ? JarvisTheme.arcBlue
                                  : JarvisTheme.redAlert)
                              .withOpacity(0.4),
                        ),
                      ),
                      child: Text(
                        _testResult!,
                        style: TextStyle(
                          color: _testSuccess == true
                              ? JarvisTheme.arcBlue
                              : JarvisTheme.redAlert,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'SETUP GUIDE',
              icon: Icons.help_outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStep(
                    '1',
                    'Start your Python API server',
                    'Run: python api.py in your jarvis_ai directory',
                  ),
                  _buildStep(
                    '2',
                    'Find your WSL IP address',
                    'Run: hostname -I in WSL terminal',
                  ),
                  _buildStep(
                    '3',
                    'Make sure api.py listens on 0.0.0.0',
                    'Use host="0.0.0.0" in Flask/FastAPI run()',
                  ),
                  _buildStep(
                    '4',
                    'Ensure phone & PC are on same WiFi',
                    'Then enter the IP above and test',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'API ENDPOINTS EXPECTED',
              icon: Icons.api_outlined,
              child: Column(
                children: [
                  _buildEndpoint('POST', '/ask', 'Text query → reply'),
                  _buildEndpoint('POST', '/voice', 'Audio file → transcript + reply'),
                  _buildEndpoint('GET', '/ping', 'Health check'),
                  _buildEndpoint('GET', '/memory', 'Fetch stored memories'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JarvisTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JarvisTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: JarvisTheme.arcBlue, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: JarvisTheme.arcBlue,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Divider(color: JarvisTheme.divider, height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildStep(String num, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: JarvisTheme.arcBlue.withOpacity(0.15),
              border: Border.all(color: JarvisTheme.arcBlue.withOpacity(0.4)),
            ),
            alignment: Alignment.center,
            child: Text(
              num,
              style: const TextStyle(
                  color: JarvisTheme.arcBlue, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      color: JarvisTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  desc,
                  style: const TextStyle(
                      color: JarvisTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndpoint(String method, String path, String desc) {
    final methodColor = method == 'POST' ? JarvisTheme.goldAccent : JarvisTheme.arcBlue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: methodColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: methodColor.withOpacity(0.3)),
            ),
            child: Text(method,
                style: TextStyle(
                    color: methodColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1)),
          ),
          const SizedBox(width: 10),
          Text(path,
              style: const TextStyle(
                  color: JarvisTheme.textPrimary,
                  fontFamily: 'monospace',
                  fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(desc,
                style: const TextStyle(
                    color: JarvisTheme.textDim, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
