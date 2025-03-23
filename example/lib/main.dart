import 'package:flutter/material.dart';
import 'package:flutter_libusb/flutter_libusb.dart';
import 'package:flutter_libusb/usb_device.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<UsbDevice> devices = [];

  @override
  void initState() {
    initialize();
    super.initState();
  }

  void initialize() async {
    bool result = FlutterLibusb.init();
    print("LibusbInit $result");

    await FlutterLibusb.startUsbDetection(
      onDeviceConnect: (device) {
        print("Connected $device");
      },
      onDeviceDisconnect: (device) {
        print("Disconnected $device");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Flutter LibUsb'), elevation: 4),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  devices = FlutterLibusb.getDeviceList(withDescriptor: true);
                  print("Deices $devices");
                  setState(() {});
                },
                child: const Text("Load Devices"),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.separated(
                itemCount: devices.length,
                itemBuilder: (BuildContext context, int index) {
                  UsbDevice device = devices[index];
                  return ListTile(title: Text(device.toString()));
                },
                separatorBuilder: (context, index) {
                  return Divider();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
