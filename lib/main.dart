import 'dart:io';
import 'package:flutter/material.dart';
import 'blue_thermal_printer.dart';
import 'package:flutter/services.dart';
import 'testprint.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  List<BluetoothDevice> _devices = [];
  late BluetoothDevice _device;
  bool _connected = false;
  late TestPrint testPrint;

  @override
  void initState() {
    super.initState();
    initPlatFormState();
    testPrint = TestPrint();
  }
  Future<void> initPlatFormState () async {
    bool? isConnected = await bluetooth.isConnected;
    List <BluetoothDevice> devices = [];
    try{
      devices = await bluetooth.getBondedDevices();
    }on PlatformException{
      // 
    }

    bluetooth.onStateChanged().listen((state) { 
      switch (state) {
        case BlueThermalPrinter.CONNECTED:
        setState(() {
          _connected = true;
        });
        break;
        case BlueThermalPrinter.DISCONNECTED: 
        setState(() {
          _connected = false;
        });
        break;
        default:
        print(state);
        break;
      }
    });
    if (!mounted) return;
      setState(() {
        _devices = devices;
      });
    
    if (isConnected!){
      setState(() {
        _connected = true;
      });
    }
  }

  

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text ('Demo Printer Zebra'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child :ListView(
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(
                    width: 10,
                  ),
                  const Text(
                    'Device: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    width: 30,
                  ),
                  Expanded(child: DropdownButton(
                    items: _getDeviceItems(),
                    onChanged: (value)=> setState(() {
                      _device = value as BluetoothDevice;
                    
                    }),
                  ))
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Row (
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(primary: Colors.brown),
                    onPressed: (){
                      initPlatFormState();
                    },
                    child: const Text(
                      'Actualizar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(primary: _connected ? Colors.red : Colors.green),
                    onPressed: _connected ? _disconnect : _connect,
                    child: Text(
                      _connected ? 'Desconectar' : 'Conectar',
                      style: const TextStyle(color: Colors.white),
                    ),)
                ],
              ),
              Padding(
                padding:
                    const EdgeInsets.only(left: 10.0, right: 10.0, top: 50),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(primary: Colors.brown),
                  onPressed: () {
                    testPrint.sample();
                  },
                  child: const Text('PRINT TEST',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          )
        ),
      ),
    );
  }

  List<DropdownMenuItem<BluetoothDevice>> _getDeviceItems() {
    List<DropdownMenuItem<BluetoothDevice>> items = [];
    if (_devices.isEmpty) {
      items.add(const DropdownMenuItem(
        child: Text('NONE'),
      ));
    } else {
      for (var device in _devices) {
        items.add(DropdownMenuItem(
          child: Text(device.name!),
          value: device,
        ));
      }
    }
    return items;
  }

  void _connect() {
    
      bluetooth.isConnected.then((isConnected) {
        if (!isConnected! ) {
          bluetooth.connect(_device).catchError((error) {
            setState(() => _connected = false);
          });
          setState(() => _connected = true);
        }
      });
    
  }

  void _disconnect() {
    bluetooth.disconnect();
    setState(() => _connected = true);
  }

//write to app path
  Future<void> writeToFile(ByteData data, String path) {
    final buffer = data.buffer;
    return File(path).writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

  Future show(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        duration: duration,
      ),
    );
  }
}

