## Flutter LibUsb

A Flutter plugin that provides a wrapper around libusb, enabling USB device access and management across multiple platforms.

## Getting Started

Add this plugin to your Flutter project as a dependency.

Before using any LibUSB APIs, ensure the library is properly initialized:

```dart
bool result = FlutterLibusb.init();
print("Libusb initialized: $result");
```

To fetch a list of currently connected USB devices:

```dart
List<UsbDevice> devices = FlutterLibusb.getDeviceList(withDescriptor: true);
print("Devices: $devices");
```

You can listen for USB device connections and disconnections:

```dart
await FlutterLibusb.startUsbDetection(
  onDeviceConnect: (device) {
    print("Connected: $device");
  },
  onDeviceDisconnect: (device) {
    print("Disconnected: $device");
  },
);
```

## Platform-Specific Setup

### MacOS

Disable sandbox from entitlements

### Windows & Linux

No additional configuration is needed—should work out of the box.

## Notes

Not all libusb APIs are implemented yet.

You can extend functionality using low-level libusb APIs exposed via FFI (using ffigen).
