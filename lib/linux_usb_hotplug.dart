import 'dart:async';
import 'package:udev/udev.dart';
import 'package:flutter_usb_event/flutter_usb_event.dart';

abstract class HotplugInterface {
  Future<void> startUsbDetection(
    Function(String) onDeviceConnect,
    Function(String) onDeviceDisconnect,
  );

  Future<void> stopUsbDetection();
}

class USbHotplug extends HotplugInterface {
  StreamSubscription? _devicesStreamSubscription;
  bool _isListening = false;

  @override
  Future<void> startUsbDetection(
    Function(String) onDeviceConnect,
    Function(String) onDeviceDisconnect,
  ) async {
    if (_isListening) return;
    await FlutterUsbEvent.startListening(
      onDeviceConnected: onDeviceConnect,
      onDeviceDisconnected: onDeviceDisconnect,
    );
    _isListening = true;
  }

  @override
  Future<void> stopUsbDetection() async {
    await FlutterUsbEvent.stopListening();
    _isListening = false;
  }
}

class LinuxUsbHotplug extends HotplugInterface {
  late final _udevContext = UdevContext();
  StreamSubscription? _devicesStreamSubscription;
  bool _waitingLinuxEvents = false;

  @override
  Future<void> startUsbDetection(
    Function(String) onDeviceConnect,
    Function(String) onDeviceDisconnect,
  ) async {
    _devicesStreamSubscription ??= _udevContext
        .monitorDevices(subsystems: ['usb'])
        .listen((UdevDevice device) {
          if (_waitingLinuxEvents) return;
          _waitingLinuxEvents = true;
          Future.delayed(const Duration(seconds: 1)).then((_) {
            // Complete this..
            onDeviceConnect(device.devpath);
            _waitingLinuxEvents = false;
          });
        });
  }

  @override
  Future<void> stopUsbDetection() async {
    _devicesStreamSubscription?.cancel();
    _devicesStreamSubscription = null;
  }
}
