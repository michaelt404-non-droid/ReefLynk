import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ReefControllerProvider with ChangeNotifier {
  String? _manualIpAddress;
  String? _activeIpAddress;
  bool _isManuallyConnected = false;
  bool _isConnected = false;

  String? get manualIpAddress => _manualIpAddress;
  String? get activeIpAddress => _activeIpAddress;
  bool get isManuallyConnected => _isManuallyConnected;
  bool get isConnected => _isConnected;

  void setManualIpAddress(String? ip) {
    _manualIpAddress = ip;
    if (ip != null && ip.isNotEmpty) {
      startDiscovery();
    }
    notifyListeners();
  }

  void setActiveIpAddress(String? ip) {
    _activeIpAddress = ip;
    notifyListeners();
  }

  void setManuallyConnected(bool value) {
    _isManuallyConnected = value;
    startDiscovery();
    notifyListeners();
  }

  void setIsConnected(bool value) {
    _isConnected = value;
    notifyListeners();
  }

  Future<void> startDiscovery() async {
    if (_isManuallyConnected && _manualIpAddress != null && _manualIpAddress!.isNotEmpty) {
      // Attempt to connect to manual IP
      await _checkManualIp(_manualIpAddress!);
    } else {
      // No automatic discovery, so ensure we are in a disconnected state.
      setActiveIpAddress(null);
      setIsConnected(false);
    }
  }

  Future<void> _checkManualIp(String ip) async {
    try {
      // Use a longer timeout to give the device time to respond.
      final request = await HttpClient()
          .getUrl(Uri.parse('http://$ip:80/data'))
          .timeout(const Duration(seconds: 5));
      final response = await request.close();

      if (response.statusCode == 200) {
        setActiveIpAddress(ip);
        setIsConnected(true);
      } else {
        setActiveIpAddress(null);
        setIsConnected(false);
      }
    } catch (e) {
      setActiveIpAddress(null);
      setIsConnected(false);
    }
  }

  void stopDiscovery() {
    // No-op, discovery is now manual
  }

  @override
  void dispose() {
    // Nothing to dispose related to discovery
    super.dispose();
  }
}