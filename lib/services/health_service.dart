import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class HealthService {
  final Health _health = Health();

  Future<bool> requestPermissions() async {
    // Configure Health Connect on Android
    if (Platform.isAndroid) {
      await _health.configure(useHealthConnectIfAvailable: true);
    }
    
    // Request activity recognition permission on Android
    if (Platform.isAndroid) {
      await Permission.activityRecognition.request();
    }
    
    // Define types
    var types = [HealthDataType.STEPS];
    
    // Request access
    // permissions need to be list of permissions matching types
    // Using READ only for now as we only read steps
    // But if we want to write? No, we read from device.
    // The prompt says "Pull step data from device health APIs".
    
    bool requested = await _health.requestAuthorization(types);
    return requested;
  }

  Future<int> getTodaySteps() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    
    try {
      int? steps = await _health.getTotalStepsInInterval(midnight, now);
      return steps ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
