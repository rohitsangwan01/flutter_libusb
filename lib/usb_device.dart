class UsbDevice {
  final String identifier;
  final int? vendorId;
  final int? productId;
  final int configurationCount;
  final int maxPacketSize;
  DeviceDescriptor? descriptor;

  UsbDevice({
    required this.identifier,
    required this.vendorId,
    required this.productId,
    required this.configurationCount,
    required this.maxPacketSize,
    this.descriptor,
  });

  @override
  String toString() {
    return 'UsbDevice{identifier: $identifier, vendorId: $vendorId, productId: $productId, configurationCount: $configurationCount, maxPacketSize: $maxPacketSize descriptor: $descriptor}';
  }
}

class DeviceDescriptor {
  String? manufacturer;
  String? product;
  String? serialNumber;

  DeviceDescriptor({
    required this.manufacturer,
    required this.product,
    required this.serialNumber,
  });

  @override
  String toString() {
    return "DeviceDescriptor{manufacturer: $manufacturer, product: $product, serialNumber: $serialNumber}";
  }
}
