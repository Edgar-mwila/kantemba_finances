import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kantemba_finances/models/sale.dart';
import 'package:kantemba_finances/providers/returns_provider.dart';
import 'package:kantemba_finances/widgets/return_modal.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/providers/sales_provider.dart';
import 'package:kantemba_finances/providers/shop_provider.dart';
import 'package:kantemba_finances/screens/sales_screen.dart';
import 'package:kantemba_finances/widgets/new_sale_modal.dart';
import 'package:kantemba_finances/helpers/platform_helper.dart';
import 'package:flutter/services.dart';
import 'dart:async';
// import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';  // Temporarily disabled
// import 'package:esc_pos_utils/esc_pos_utils.dart';  // Temporarily disabled
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart' as btp;
import '../helpers/analytics_service.dart';

const int ESC = 27;
const int PULSE = 112;

/// POS Device Integration Manager
class PosDeviceManager {
  // Device connection states
  bool _barcodeScannerConnected = false;
  bool _receiptPrinterConnected = false;
  bool _cashDrawerConnected = false;

  // Device info
  String _scannerDeviceName = '';
  String _printerDeviceName = '';

  // Stream controllers for device events
  final StreamController<String> _barcodeController =
      StreamController<String>.broadcast();
  final StreamController<String> _deviceStatusController =
      StreamController<String>.broadcast();

  List<UsbDevice> usbDevices = [];
  List<BluetoothDevice> bluetoothDevices = [];

  btp.BlueThermalPrinter? _bluetoothPrinter;
  btp.BluetoothDevice? _selectedBluetoothPrinter;
  UsbPort? _usbPrinterPort;

  List<UsbDevice> getUsbDevices() => usbDevices;
  List<BluetoothDevice> getBluetoothDevices() => bluetoothDevices;

  // Getters
  bool get barcodeScannerConnected => _barcodeScannerConnected;
  bool get receiptPrinterConnected => _receiptPrinterConnected;
  bool get cashDrawerConnected => _cashDrawerConnected;
  String get scannerDeviceName => _scannerDeviceName;
  String get printerDeviceName => _printerDeviceName;
  Stream<String> get barcodeStream => _barcodeController.stream;
  Stream<String> get deviceStatusStream => _deviceStatusController.stream;

  /// Initialize POS device connections
  Future<void> initializeDevices() async {
    try {
      // Initialize device channels
      // _channel.setMethodCallHandler(_handleMethodCall); // Removed MethodChannel

      // Scan for available devices
      await _scanForDevices();

      // Auto-connect to previously paired devices
      await _autoConnectDevices();
    } catch (e) {
      print('Error initializing POS devices: $e');
    }
  }

  /// Handle method calls from platform
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'barcodeScanned':
        _barcodeController.add(call.arguments as String);
        break;
      case 'deviceConnected':
        _updateDeviceStatus(call.arguments as Map<String, dynamic>);
        break;
      case 'deviceDisconnected':
        _updateDeviceStatus(call.arguments as Map<String, dynamic>);
        break;
    }
  }

  /// Scan for available POS devices
  Future<void> _scanForDevices() async {
    try {
      usbDevices = await UsbSerial.listDevices();
      // Scan for Bluetooth devices - just get connected devices for now
      bluetoothDevices = await FlutterBluePlus.connectedDevices;
      print('USB Devices found:');
      for (var device in usbDevices) {
        print(
          'USB: ${device.productName} (VID: ${device.vid}, PID: ${device.pid})',
        );
      }
      print('Bluetooth Devices found:');
      for (var device in bluetoothDevices) {
        print('Bluetooth: ${device.name} (ID: ${device.id})');
      }
    } catch (e) {
      print('Error scanning for devices: $e');
    }
  }

  /// Auto-connect to previously paired devices
  Future<void> _autoConnectDevices() async {
    try {
      // await _channel.invokeMethod('autoConnectDevices'); // Removed MethodChannel
    } catch (e) {
      print('Error auto-connecting devices: $e');
    }
  }

  /// Connect to barcode scanner (USB or Bluetooth)
  Future<bool> connectBarcodeScanner(String deviceId) async {
    try {
      // Try USB first
      final usbDevice = usbDevices.firstWhereOrNull(
        (d) => d.deviceId.toString() == deviceId,
      );
      if (usbDevice != null) {
        final port = await usbDevice.create();
        if (port != null) {
          await port.open();
          await port.setDTR(true);
          await port.setRTS(true);
          await port.setPortParameters(
            9600,
            UsbPort.DATABITS_8,
            UsbPort.STOPBITS_1,
            UsbPort.PARITY_NONE,
          );
          port.inputStream?.listen((data) {
            final barcode = String.fromCharCodes(data).trim();
            if (barcode.isNotEmpty) {
              _barcodeController.add(barcode);
            }
          });
          _barcodeScannerConnected = true;
          _scannerDeviceName = usbDevice.productName ?? 'USB Scanner';
          _deviceStatusController.add('Barcode scanner connected');
          return true;
        }
      }
      // Try Bluetooth
      final btDevice = bluetoothDevices.firstWhereOrNull(
        (d) => d.id.toString() == deviceId,
      );
      if (btDevice != null) {
        _barcodeScannerConnected = true;
        _scannerDeviceName = btDevice.name;
        _deviceStatusController.add('Bluetooth barcode scanner ready');
        return true;
      }
      return false;
    } catch (e) {
      print('Error connecting barcode scanner: $e');
      return false;
    }
  }

  /// Connect to receipt printer (Bluetooth only for Android)
  Future<bool> connectReceiptPrinter(String deviceId) async {
    try {
      final btPrinter =
          await btp.BlueThermalPrinter.instance.getBondedDevices();
      final selected = btPrinter.firstWhereOrNull((d) => d.address == deviceId);
      if (selected != null) {
        _bluetoothPrinter = btp.BlueThermalPrinter.instance;
        _selectedBluetoothPrinter = selected;
        await _bluetoothPrinter!.connect(_selectedBluetoothPrinter!);
        _receiptPrinterConnected = true;
        _printerDeviceName = selected.name ?? 'Bluetooth Printer';
        _deviceStatusController.add('Receipt printer connected');
        return true;
      }
      return false;
    } catch (e) {
      print('Error connecting receipt printer: $e');
      return false;
    }
  }

  /// Print receipt using Bluetooth printer
  Future<bool> printReceipt(Map<String, dynamic> receiptData) async {
    if (!_receiptPrinterConnected ||
        _bluetoothPrinter == null ||
        _selectedBluetoothPrinter == null) {
      print('Receipt printer not connected');
      return false;
    }
    try {
      await _bluetoothPrinter!.connect(_selectedBluetoothPrinter!);
      await _bluetoothPrinter!.write("Kantemba Finances\n");
      await _bluetoothPrinter!.write("-----------------------------\n");
      await _bluetoothPrinter!.write(
        "Sale ID: " + (receiptData['id'] ?? '') + "\n",
      );
      await _bluetoothPrinter!.write(
        "Date: " + (receiptData['date'] ?? '') + "\n",
      );
      await _bluetoothPrinter!.write("-----------------------------\n");
      for (final item in (receiptData['items'] ?? [])) {
        await _bluetoothPrinter!.write(
          "${item['name']} x${item['quantity']}  K${item['price']}\n",
        );
      }
      await _bluetoothPrinter!.write("-----------------------------\n");
      await _bluetoothPrinter!.write("Total: K${receiptData['grandTotal']}\n");
      await _bluetoothPrinter!.write("Thank you!\n\n\n");
      await _bluetoothPrinter!.disconnect();
      return true;
    } catch (e) {
      print('Error printing receipt: $e');
      return false;
    }
  }

  /// Open cash drawer
  Future<bool> openCashDrawer() async {
    try {
      // Try Bluetooth printer first
      if (_bluetoothPrinter != null && _selectedBluetoothPrinter != null) {
        await _bluetoothPrinter!.connect(_selectedBluetoothPrinter!);
        // ESC/POS open drawer command
        await _bluetoothPrinter!.writeBytes(
          Uint8List.fromList([ESC, PULSE, 0, 25, 250]),
        );
        return true;
      }
      // Try USB printer
      if (_usbPrinterPort != null) {
        await _usbPrinterPort!.write(
          Uint8List.fromList([ESC, PULSE, 0, 25, 250]),
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Error opening cash drawer: $e');
      return false;
    }
  }

  /// Update device connection status
  void _updateDeviceStatus(Map<String, dynamic> status) {
    final deviceType = status['deviceType'] as String;
    final connected = status['connected'] as bool;
    final deviceName = status['deviceName'] as String;

    switch (deviceType) {
      case 'barcode_scanner':
        _barcodeScannerConnected = connected;
        _scannerDeviceName = deviceName;
        break;
      case 'receipt_printer':
        _receiptPrinterConnected = connected;
        _printerDeviceName = deviceName;
        break;
      case 'cash_drawer':
        _cashDrawerConnected = connected;
        break;
    }

    _deviceStatusController.add(
      '$deviceType ${connected ? 'connected' : 'disconnected'}',
    );
  }

  /// Dispose resources
  void dispose() {
    _barcodeController.close();
    _deviceStatusController.close();
  }

  /// Device selection dialog (updated for real devices)
  Future<void> showDeviceSelectionDialog(
    BuildContext context,
    String type,
  ) async {
    await _scanForDevices();
    List devices =
        type == 'printer'
            ? await btp.BlueThermalPrinter.instance.getBondedDevices()
            : [...usbDevices, ...bluetoothDevices];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Select  ${type == 'printer' ? 'Printer' : 'Barcode Device'}',
          ),
          content: SizedBox(
            width: 300,
            height: 400,
            child: ListView(
              children: [
                ...devices.map(
                  (d) => ListTile(
                    title: Text(
                      type == 'printer'
                          ? (d.name ?? 'Unknown Printer')
                          : (d.productName ?? d.name ?? 'Unknown Device'),
                    ),
                    subtitle: Text(
                      type == 'printer'
                          ? d.address
                          : (d.deviceId?.toString() ?? d.id?.toString() ?? ''),
                    ),
                    onTap: () async {
                      Navigator.of(context).pop();
                      if (type == 'printer') {
                        await connectReceiptPrinter(d.address);
                      } else {
                        await connectBarcodeScanner(
                          d.deviceId?.toString() ?? d.id?.toString() ?? '',
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

extension IterableX<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final PosDeviceManager _deviceManager = PosDeviceManager();
  final TextEditingController _barcodeController = TextEditingController();
  final _lastScannedBarcode = '';
  bool _isDeviceInitialized = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logEvent('screen_open', data: {'screen': 'POS'});
    _initializeDevices();
  }

  void _onDeviceScanned(String deviceType) {
    AnalyticsService.logEvent(
      'pos_device_scanned',
      data: {'deviceType': deviceType},
    );
  }

  void _onDeviceConnected(String deviceType) {
    AnalyticsService.logEvent(
      'pos_device_connected',
      data: {'deviceType': deviceType},
    );
  }

  void _onPOSAction(String action, {String? deviceType}) {
    AnalyticsService.logEvent(
      'pos_action',
      data: {'action': action, 'deviceType': deviceType},
    );
  }

  @override
  void dispose() {
    _deviceManager.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  /// Initialize POS devices
  Future<void> _initializeDevices() async {
    await _deviceManager.initializeDevices();
    setState(() {
      _isDeviceInitialized = true;
    });
  }

  /// Print current sale receipt
  Future<void> _printReceipt(Sale sale) async {
    _onPOSAction('print_receipt', deviceType: 'receipt_printer');
    final receiptData = {
      'saleId': sale.id,
      'date': sale.date.toIso8601String(),
      'items':
          sale.items
              .map(
                (item) => {
                  'name': item.product.name,
                  'quantity': item.quantity,
                  'price': item.product.price,
                  'total': item.quantity * item.product.price,
                },
              )
              .toList(),
      'total': sale.grandTotal,
      'businessName': 'Kantemba Finances',
    };

    final success = await _deviceManager.printReceipt(receiptData);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt printed successfully')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to print receipt')));
    }
  }

  /// Open cash drawer
  Future<void> _openCashDrawer() async {
    _onPOSAction('open_cash_drawer', deviceType: 'cash_drawer');
    final success = await _deviceManager.openCashDrawer();

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cash drawer opened')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open cash drawer')),
      );
    }
  }

  /// Show device management dialog
  void _showDeviceManagementDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('POS Device Management'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDeviceStatusCard(
                  'Barcode Scanner',
                  _deviceManager.barcodeScannerConnected,
                  _deviceManager.scannerDeviceName,
                  Icons.qr_code_scanner,
                ),
                const SizedBox(height: 8),
                _buildDeviceStatusCard(
                  'Receipt Printer',
                  _deviceManager.receiptPrinterConnected,
                  _deviceManager.printerDeviceName,
                  Icons.print,
                ),
                const SizedBox(height: 8),
                _buildDeviceStatusCard(
                  'Cash Drawer',
                  _deviceManager.cashDrawerConnected,
                  'Connected',
                  Icons.point_of_sale,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _scanForDevices();
                },
                child: const Text('Scan for Devices'),
              ),
            ],
          ),
    );
  }

  /// Show device selection modal
  void _showDeviceSelectionModal() {
    showDialog(
      context: context,
      builder:
          (context) => _DeviceSelectionDialog(
            onDeviceSelected: (String deviceId) async {
              await _deviceManager.connectBarcodeScanner(deviceId);
              Navigator.of(context).pop();
            },
            onRefresh: _scanForDevices,
            deviceManager: _deviceManager,
          ),
    );
  }

  /// Build device status card
  Widget _buildDeviceStatusCard(
    String name,
    bool connected,
    String status,
    IconData icon,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: connected ? Colors.green : Colors.grey),
        title: Text(name),
        subtitle: Text(connected ? status : 'Not connected'),
        trailing: Icon(
          connected ? Icons.check_circle : Icons.error,
          color: connected ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  /// Scan for new devices
  Future<void> _scanForDevices() async {
    await _deviceManager._scanForDevices();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Scanning for devices...')));
  }

  @override
  Widget build(BuildContext context) {
    final salesData = Provider.of<SalesProvider>(context);

    return Consumer<ShopProvider>(
      builder: (context, shopProvider, child) {
        // Get filtered sales based on current shop and take only the 5 most recent
        final filteredSales = salesData.getSalesForShop(
          shopProvider.currentShop,
        );
        final recentSales =
            filteredSales.reversed.take(5).toList().reversed.toList();

        if (isWindows(context)) {
          // Desktop layout: Centered, max width, dialogs for details
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'POS',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    _deviceManager.barcodeScannerConnected
                        ? Icons.qr_code_scanner
                        : Icons.qr_code,
                  ),
                  tooltip:
                      _deviceManager.barcodeScannerConnected
                          ? 'Scanner Connected'
                          : 'Connect Scanner',
                  onPressed:
                      () => _deviceManager.showDeviceSelectionDialog(
                        context,
                        'scanner',
                      ),
                ),
              ],
            ),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: Actions and Device Controls
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Add Sale Card
                            Card(
                              elevation: 4,
                              child: InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (_) => Dialog(
                                          child: NewSaleModal(
                                            deviceManager: _deviceManager,
                                            lastScannedBarcode:
                                                _lastScannedBarcode,
                                          ),
                                        ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_shopping_cart,
                                        size: 32,
                                        color: Colors.green.shade700,
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        'Add New Sale',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.headlineSmall!.copyWith(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Device Status Card
                            Card(
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.devices,
                                              color: Colors.blue.shade700,
                                            ),
                                            const SizedBox(width: 4),
                                            const Text(
                                              'POS Devices',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            _showDeviceManagementDialog();
                                          },
                                          icon: Icon(
                                            Icons.details,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Scanner: ${_deviceManager.barcodeScannerConnected ? "Connected - ${_deviceManager._scannerDeviceName}" : "Disconnected"}',
                                    ),
                                    Text(
                                      'Printer: ${_deviceManager.receiptPrinterConnected ? "Connected - ${_deviceManager._printerDeviceName}" : "Disconnected"}',
                                    ),
                                    const SizedBox(height: 8),
                                    Column(
                                      children: [
                                        _deviceManager._cashDrawerConnected
                                            ? ElevatedButton.icon(
                                              onPressed: _openCashDrawer,
                                              icon: const Icon(
                                                Icons.point_of_sale,
                                              ),
                                              label: const Text('Open Drawer'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.orange,
                                                foregroundColor: Colors.white,
                                              ),
                                            )
                                            : Text('CashDrawer not connected'),
                                        const SizedBox(height: 8),
                                        ElevatedButton.icon(
                                          onPressed: _scanForDevices,
                                          icon: const Icon(Icons.refresh),
                                          label: const Text('Scan Devices'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40),
                      // Right: Recent Sales
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Recent Sales',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleLarge!.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => const SalesScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text('See All'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (recentSales.isEmpty)
                              const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('No sales recorded yet'),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: recentSales.length,
                                itemBuilder:
                                    (ctx, i) => Card(
                                      child: ListTile(
                                        title: Text(
                                          'Sale ID: ${recentSales[recentSales.length - i - 1].id}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                          'Items: ${recentSales[recentSales.length - i - 1].items.length} | ${DateFormat('yyyy-MM-dd - kk:mm').format(recentSales[recentSales.length - i - 1].date)}',
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'K ${recentSales[recentSales.length - i - 1].grandTotal.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.print),
                                              onPressed:
                                                  () => _printReceipt(
                                                    recentSales[recentSales
                                                            .length -
                                                        i -
                                                        1],
                                                  ),
                                              tooltip: 'Print Receipt',
                                            ),
                                          ],
                                        ),
                                        onTap: () {
                                          _showSaleDetailsDialog(
                                            context,
                                            recentSales[recentSales.length -
                                                i -
                                                1],
                                            shopProvider,
                                          );
                                        },
                                      ),
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // Mobile layout
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'POS',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _deviceManager.barcodeScannerConnected
                      ? Icons.qr_code_scanner
                      : Icons.qr_code,
                ),
                tooltip:
                    _deviceManager.barcodeScannerConnected
                        ? 'Scanner Connected'
                        : 'Connect Scanner',
                onPressed:
                    () => _deviceManager.showDeviceSelectionDialog(
                      context,
                      'scanner',
                    ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add Sale Card
                  Card(
                    elevation: 4,
                    child: InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder:
                              (_) => NewSaleModal(
                                deviceManager: _deviceManager,
                                lastScannedBarcode: _lastScannedBarcode,
                              ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_shopping_cart,
                              size: 32,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Add New Sale',
                              style: Theme.of(
                                context,
                              ).textTheme.headlineSmall!.copyWith(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Device Status Card
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.devices,
                                    color: Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'POS Devices',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                onPressed: () {
                                  _showDeviceManagementDialog();
                                },
                                icon: Icon(
                                  Icons.details,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Scanner: ${_deviceManager.barcodeScannerConnected ? "Connected - ${_deviceManager._scannerDeviceName}" : "Disconnected"}',
                          ),
                          Text(
                            'Printer: ${_deviceManager.receiptPrinterConnected ? "Connected - ${_deviceManager._printerDeviceName}" : "Disconnected"}',
                          ),
                          const SizedBox(height: 8),
                          Column(
                            children: [
                              _deviceManager._cashDrawerConnected
                                  ? ElevatedButton.icon(
                                    onPressed: _openCashDrawer,
                                    icon: const Icon(Icons.point_of_sale),
                                    label: const Text('Open Drawer'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                    ),
                                  )
                                  : Text('CashDrawer not connected'),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed:
                                    () => _deviceManager
                                        .showDeviceSelectionDialog(
                                          context,
                                          'scanner',
                                        ),
                                icon: const Icon(Icons.devices),
                                label: const Text('Select Device'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _scanForDevices,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Scan Devices'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Recent Sales Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Sales',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SalesScreen(),
                            ),
                          );
                        },
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (recentSales.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No sales recorded yet'),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recentSales.length,
                      itemBuilder:
                          (ctx, i) => Card(
                            child: ListTile(
                              title: Text(
                                'Sale ID: ${recentSales[recentSales.length - i - 1].id}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                'Items: ${recentSales[recentSales.length - i - 1].items.length} | ${DateFormat('yyyy-MM-dd - kk:mm').format(recentSales[recentSales.length - i - 1].date)}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'K${recentSales[recentSales.length - i - 1].grandTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.print),
                                    onPressed:
                                        () => _printReceipt(
                                          recentSales[recentSales.length -
                                              i -
                                              1],
                                        ),
                                    tooltip: 'Print Receipt',
                                  ),
                                ],
                              ),
                              onTap: () {
                                _showSaleDetailsDialog(
                                  context,
                                  recentSales[recentSales.length - i - 1],
                                  shopProvider,
                                );
                              },
                            ),
                          ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

void _showSaleDetailsDialog(
  BuildContext context,
  Sale sale,
  ShopProvider shopProvider,
) {
  final shop = shopProvider.shops.firstWhere(
    (s) => s.id == sale.shopId,
    orElse: () => shopProvider.shops.first,
  );

  showDialog(
    context: context,
    builder:
        (ctx) => Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxWidth: 800,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Sale Details',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Sale Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.receipt,
                                color: Colors.blue.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Sale ID: ${sale.id}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.store,
                                color: Colors.green.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Shop: ${shop.name}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (sale.customerName != null &&
                              sale.customerName!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  color: Colors.orange.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Customer: ${sale.customerName}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (sale.customerPhone != null &&
                              sale.customerPhone!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone,
                                  color: Colors.orange.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Phone: ${sale.customerPhone}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Colors.purple.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Date: ${DateFormat('MMM dd, yyyy HH:mm').format(sale.date)}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Items List
                    Text(
                      'Items Sold:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: sale.items.length,
                        itemBuilder: (context, index) {
                          final item = sale.items[index];
                          final hasReturns = item.returnedQuantity > 0;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.product.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        'K${item.product.price.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Quantity: ${item.quantity}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        'Subtotal: K${(item.quantity * item.product.price).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (hasReturns) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.assignment_return,
                                            color: Colors.orange.shade700,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Returned: ${item.returnedQuantity} units - ${item.returnedReason}',
                                              style: TextStyle(
                                                color: Colors.orange.shade700,
                                                fontSize: 12,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Subtotal:',
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                'K${sale.totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (sale.discount > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Discount:',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  '-K${sale.discount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (sale.vat > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'VAT:',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  'K${sale.vat.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (sale.turnoverTax > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Turnover Tax:',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  'K${sale.turnoverTax.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (sale.levy > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Levy:',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  'K${sale.levy.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total:',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'K${sale.grandTotal.toStringAsFixed(2)}',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Returns Info
                    Consumer<ReturnsProvider>(
                      builder: (context, returnsProvider, child) {
                        final hasReturns = returnsProvider.hasReturns(sale.id);
                        final totalReturnAmount = returnsProvider
                            .getTotalReturnAmountForSale(sale.id);

                        if (hasReturns) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.assignment_return,
                                  color: Colors.orange.shade700,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Returns: K${totalReturnAmount.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: Colors.orange.shade700,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        'This sale has returned items',
                                        style: TextStyle(
                                          color: Colors.orange.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: 16),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              showDialog(
                                context: context,
                                builder:
                                    (_) =>
                                        Dialog(child: ReturnModal(sale: sale)),
                              );
                            },
                            icon: const Icon(Icons.assignment_return),
                            label: const Text('Return Items'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade600,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Close'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
  );
}

// Device selection dialog widget
class _DeviceSelectionDialog extends StatefulWidget {
  final void Function(String deviceId) onDeviceSelected;
  final VoidCallback onRefresh;
  final PosDeviceManager deviceManager;

  const _DeviceSelectionDialog({
    required this.onDeviceSelected,
    required this.onRefresh,
    required this.deviceManager,
  });

  @override
  State<_DeviceSelectionDialog> createState() => _DeviceSelectionDialogState();
}

class _DeviceSelectionDialogState extends State<_DeviceSelectionDialog> {
  List<Map<String, String>> _devices = [];
  bool _loading = true;
  String? _selectedDeviceId;

  @override
  void initState() {
    super.initState();
    _fetchDevices();
  }

  Future<void> _fetchDevices() async {
    setState(() {
      _loading = true;
    });
    // Simulate device scan (replace with actual device scan logic)
    await Future.delayed(const Duration(seconds: 1));
    // Example devices
    _devices = [
      {'id': 'usb-123', 'name': 'USB Barcode Scanner'},
      {'id': 'bt-456', 'name': 'Bluetooth Scanner'},
    ];
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Barcode Device'),
      content:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _devices.isEmpty
              ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No devices found.'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      _fetchDevices();
                      widget.onRefresh();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Scan Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              )
              : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ..._devices.map(
                    (device) => RadioListTile<String>(
                      value: device['id']!,
                      groupValue: _selectedDeviceId,
                      onChanged: (value) {
                        setState(() {
                          _selectedDeviceId = value;
                        });
                      },
                      title: Text(device['name']!),
                    ),
                  ),
                ],
              ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (_devices.isNotEmpty)
          ElevatedButton(
            onPressed:
                _selectedDeviceId == null
                    ? null
                    : () => widget.onDeviceSelected(_selectedDeviceId!),
            child: const Text('Connect'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }
}

Future<void> showDeviceSelectionDialog(
  BuildContext context,
  PosDeviceManager manager,
) async {
  await manager._scanForDevices();
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Select Device'),
        content: SizedBox(
          width: 300,
          height: 400,
          child: ListView(
            children: [
              ...manager.usbDevices.map(
                (d) => ListTile(
                  title: Text(d.productName ?? 'Unknown USB Device'),
                  subtitle: Text('VID: ${d.vid}, PID: ${d.pid}'),
                  onTap: () {
                    Navigator.of(context).pop();
                    // TODO: Connect to USB device
                  },
                ),
              ),
              ...manager.bluetoothDevices.map(
                (d) => ListTile(
                  title: Text(d.name),
                  subtitle: Text(d.id.toString()),
                  onTap: () {
                    Navigator.of(context).pop();
                    // TODO: Connect to Bluetooth device
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
