import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_libusb/generated/generated_bindings.dart';
import 'package:flutter_libusb/linux_usb_hotplug.dart';
import 'package:flutter_libusb/usb_device.dart';
import 'package:ffi/ffi.dart' as ffi;

class FlutterLibusb {
  const FlutterLibusb._();

  static LibUsb? _libusb;

  static final HotplugInterface _hotplugInterface =
      (defaultTargetPlatform == TargetPlatform.linux)
          ? LinuxUsbHotplug()
          : USbHotplug();

  static LibUsb? get libUsb {
    if (_libusb != null) return _libusb;
    String? libUsbPath = _libUsbBinaryPath;
    if (libUsbPath == null) throw "LibUsb not found";
    _libusb = LibUsb(DynamicLibrary.open(libUsbPath));
    return _libusb;
  }

  static bool init() {
    return libUsb?.libusb_init(nullptr) == libusb_error.LIBUSB_SUCCESS.value;
  }

  static void dispose() {
    libUsb?.libusb_exit(nullptr);
  }

  static Future<void> startUsbDetection({
    required Function(String) onDeviceConnect,
    required Function(String) onDeviceDisconnect,
  }) =>
      _hotplugInterface.startUsbDetection(onDeviceConnect, onDeviceDisconnect);

  static Future<void> stopUsbDetection() =>
      _hotplugInterface.stopUsbDetection();

  static List<UsbDevice> getDeviceList({bool withDescriptor = false}) {
    var deviceListPtr = ffi.calloc<Pointer<Pointer<libusb_device>>>();
    try {
      var count = libUsb?.libusb_get_device_list(nullptr, deviceListPtr);
      if (count == null || count < 0) return [];
      try {
        return _iterateDevice(deviceListPtr.value, withDescriptor).toList();
      } finally {
        libUsb?.libusb_free_device_list(deviceListPtr.value, 1);
      }
    } finally {
      ffi.calloc.free(deviceListPtr);
    }
  }

  static Iterable<UsbDevice> _iterateDevice(
    Pointer<Pointer<libusb_device>> deviceList,
    bool withDescriptor,
  ) sync* {
    var descPtr = ffi.calloc<libusb_device_descriptor>();
    for (var i = 0; deviceList[i] != nullptr; i++) {
      var dev = deviceList[i];
      var addr = libUsb?.libusb_get_device_address(dev);
      var getDesc =
          libUsb?.libusb_get_device_descriptor(dev, descPtr) ==
          libusb_error.LIBUSB_SUCCESS.value;

      int? vendorId = getDesc ? descPtr.ref.idVendor : null;
      int? productId = getDesc ? descPtr.ref.idProduct : null;
      Pointer<libusb_device_handle>? handle;
      DeviceDescriptor? descriptor;

      if (withDescriptor && vendorId != null && productId != null) {
        handle = openDevice(vendorId, productId);
      }

      if (handle != null) descriptor = loadDescription(handle);

      yield UsbDevice(
        identifier: addr.toString(),
        vendorId: vendorId,
        productId: productId,
        configurationCount: getDesc ? descPtr.ref.bNumConfigurations : 0,
        maxPacketSize: getDesc ? descPtr.ref.bMaxPacketSize0 : 0,
        descriptor: descriptor,
      );

      if (handle != null) closeDevice(handle);
    }
    ffi.calloc.free(descPtr);
  }

  static Pointer<libusb_device_handle>? openDevice(
    int vendorId,
    int productId,
  ) {
    var handle = libUsb?.libusb_open_device_with_vid_pid(
      nullptr,
      vendorId,
      productId,
    );
    if (handle == nullptr) return null;
    return handle;
  }

  static void closeDevice(Pointer<libusb_device_handle> handle) {
    libUsb?.libusb_close(handle);
  }

  static DeviceDescriptor? loadDescription(
    Pointer<libusb_device_handle> handle,
  ) {
    var descPtr = ffi.calloc<libusb_device_descriptor>();
    try {
      var device = libUsb?.libusb_get_device(handle);
      if (device != null && device != nullptr) {
        String? manufacturer;
        String? product;
        String? serialNumber;
        var getDesc =
            libUsb?.libusb_get_device_descriptor(device, descPtr) ==
            libusb_error.LIBUSB_SUCCESS.value;
        if (getDesc) {
          if (descPtr.ref.iManufacturer > 0) {
            manufacturer = _getStringDescriptorASCII(
              handle,
              descPtr.ref.iManufacturer,
            );
          }
          if (descPtr.ref.iProduct > 0) {
            product = _getStringDescriptorASCII(handle, descPtr.ref.iProduct);
          }
          if (descPtr.ref.iSerialNumber > 0) {
            serialNumber = _getStringDescriptorASCII(
              handle,
              descPtr.ref.iSerialNumber,
            );
          }
        }

        return DeviceDescriptor(
          manufacturer: manufacturer,
          product: product,
          serialNumber: serialNumber,
        );
      }
    } finally {
      ffi.calloc.free(descPtr);
    }
    return null;
  }

  static String? _getStringDescriptorASCII(
    Pointer<libusb_device_handle> handle,
    int descIndex,
  ) {
    String? result;
    Pointer<ffi.Utf8> string = ffi.calloc<Uint8>(256).cast();
    try {
      var ret = libUsb?.libusb_get_string_descriptor_ascii(
        handle,
        descIndex,
        string.cast(),
        256,
      );
      if (ret == null || ret > 0) {
        result = string.toDartString();
      }
    } finally {
      ffi.calloc.free(string);
    }
    return result;
  }

  static final _executablePath = File(Platform.resolvedExecutable).parent.path;

  static String? get _libUsbBinaryPath => switch (defaultTargetPlatform) {
    TargetPlatform.macOS => "libusb.dylib",
    TargetPlatform.windows => "libusb.dll",
    TargetPlatform.linux => "$_executablePath/lib/libusb.so",
    _ => null,
  };
}
