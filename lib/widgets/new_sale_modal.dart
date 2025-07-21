import 'package:flutter/material.dart';
import 'package:kantemba_finances/providers/business_provider.dart';
import 'package:kantemba_finances/providers/shop_provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as mobile_scanner;
import 'package:provider/provider.dart';
import 'package:kantemba_finances/models/inventory_item.dart';
import 'package:kantemba_finances/models/sale.dart';
import 'package:kantemba_finances/providers/inventory_provider.dart';
import 'package:kantemba_finances/providers/sales_provider.dart';
import 'package:kantemba_finances/providers/users_provider.dart';
import 'package:kantemba_finances/helpers/platform_helper.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:usb_serial/usb_serial.dart';
import 'dart:io' show Platform;
import 'package:blue_thermal_printer/blue_thermal_printer.dart' as btp;

// Import POS device manager from POS screen
import '../screens/pos_screen.dart';

// Add fallback alignment constants if not defined by the package
const int ALIGN_LEFT = 0;
const int ALIGN_CENTER = 1;
const int ALIGN_RIGHT = 2;

class NewSaleModal extends StatefulWidget {
  final PosDeviceManager? deviceManager;
  final String? lastScannedBarcode;

  const NewSaleModal({super.key, this.deviceManager, this.lastScannedBarcode});

  @override
  State<NewSaleModal> createState() => _NewSaleModalState();
}

class _NewSaleModalState extends State<NewSaleModal> {
  final List<SaleItem> _cartItems = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  double _grandTotal = 0.0;
  double _discountAmount = 0.0;
  String _searchQuery = '';
  String _barcodeQuery = '';
  bool _isProcessing = false;

  // POS Device Manager for barcode scanning
  late final PosDeviceManager _deviceManager;
  String _lastScannedBarcode = '';
  bool _isDeviceInitialized = false;

  BluetoothDevice? _connectedBluetoothDevice;
  Stream<List<int>>? _bluetoothDataStream;
  bool _isBluetoothConnecting = false;

  UsbPort? _usbPort;
  UsbDevice? _connectedUsbDevice;
  bool _isUsbConnecting = false;

  // PrinterBluetoothManager _printerManager = PrinterBluetoothManager();  // Temporarily disabled
  // PrinterBluetooth? _selectedPrinter;  // Temporarily disabled
  // bool _isPrinterConnecting = false;  // Temporarily disabled
  // bool _isPrinting = false;  // Temporarily disabled

  // 1. Add a field to store the last completed sale:
  Sale? _lastCompletedSale;

  btp.BlueThermalPrinter _bluetooth = btp.BlueThermalPrinter.instance;
  btp.BluetoothDevice? _selectedBluetoothPrinter;
  bool _isBluetoothPrinterConnecting = false;
  bool _isBluetoothPrinting = false;

  UsbPort? _usbPrinterPort;
  UsbDevice? _selectedUsbPrinter;
  bool _isUsbPrinterConnecting = false;
  bool _isUsbPrinting = false;

  @override
  void initState() {
    super.initState();

    // Use passed device manager or create new one
    _deviceManager = widget.deviceManager ?? PosDeviceManager();

    // Use passed barcode or empty string
    _lastScannedBarcode = widget.lastScannedBarcode ?? '';
    if (_lastScannedBarcode.isNotEmpty) {
      _barcodeController.text = _lastScannedBarcode;
      _barcodeQuery = _lastScannedBarcode;
    }

    _initializeDevices();
    _setupBarcodeListener();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _barcodeController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _discountController.dispose();
    // Only dispose if we created the device manager locally
    if (widget.deviceManager == null) {
      _deviceManager.dispose();
    }
    super.dispose();
  }

  /// Initialize POS devices
  Future<void> _initializeDevices() async {
    // Only initialize if we created the device manager locally
    if (widget.deviceManager == null) {
      await _deviceManager.initializeDevices();
    }
    setState(() {
      _isDeviceInitialized = true;
    });
  }

  /// Setup barcode scanner listener
  void _setupBarcodeListener() {
    _deviceManager.barcodeStream.listen((barcode) {
      setState(() {
        _lastScannedBarcode = barcode;
      });
      _handleBarcodeScanned(barcode);
    });
  }

  /// Handle scanned barcode
  void _handleBarcodeScanned(String barcode) {
    // Focus on barcode field for manual entry
    _barcodeController.text = barcode;
    setState(() {
      _barcodeQuery = barcode;
    });

    // Look up product by barcode
    _lookupProductByBarcode(barcode);
  }

  /// Look up product by barcode
  void _lookupProductByBarcode(String barcode) {
    final inventoryProvider = Provider.of<InventoryProvider>(
      context,
      listen: false,
    );
    final product = inventoryProvider.findItemByBarcode(barcode);

    if (product != null) {
      _addProductToCart(product);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} added to cart'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No product found with barcode: $barcode'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _addProductToCart(InventoryItem product) {
    if (product.quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product is out of stock'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      final existingItemIndex = _cartItems.indexWhere(
        (item) => item.product.id == product.id,
      );
      if (existingItemIndex != -1) {
        final currentCartQuantity = _cartItems[existingItemIndex].quantity;
        if (currentCartQuantity >= product.quantity) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Insufficient stock available'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        _cartItems[existingItemIndex].quantity++;
      } else {
        _cartItems.add(SaleItem(product: product, quantity: 1));
      }
      _calculateTotal();
    });
  }

  void _removeProductFromCart(String productId) {
    setState(() {
      _cartItems.removeWhere((item) => item.product.id == productId);
      _calculateTotal();
    });
  }

  void _updateQuantity(String productId, int newQuantity) {
    final item = _cartItems.firstWhere(
      (item) => item.product.id == productId,
      orElse: () => throw StateError('Item not found'),
    );

    if (newQuantity > item.product.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot exceed available stock (${item.product.quantity})',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      final index = _cartItems.indexWhere(
        (item) => item.product.id == productId,
      );
      if (index != -1) {
        if (newQuantity > 0) {
          _cartItems[index].quantity = newQuantity;
        } else {
          _cartItems.removeAt(index);
        }
        _calculateTotal();
      }
    });
  }

  void _clearCart() {
    final previousCart = List<SaleItem>.from(
      _cartItems.map(
        (item) => SaleItem(product: item.product, quantity: item.quantity),
      ),
    );
    setState(() {
      _cartItems.clear();
      _calculateTotal();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Cart cleared'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _cartItems.clear();
              _cartItems.addAll(previousCart);
              _calculateTotal();
            });
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _calculateTotal() {
    _grandTotal = 0.0;
    for (var item in _cartItems) {
      _grandTotal += item.product.price * item.quantity;
    }
    // Apply discount
    _grandTotal -= _discountAmount;
    if (_grandTotal < 0) _grandTotal = 0.0;
  }

  void _updateDiscount(String value) {
    setState(() {
      _discountAmount = double.tryParse(value) ?? 0.0;
      _calculateTotal();
    });
  }

  Future<void> _addSale() async {
    if (_cartItems.isEmpty) return;

    final currentUser =
        Provider.of<UsersProvider>(context, listen: false).currentUser;
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No user is logged in!')));
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final currentShop = shopProvider.currentShop;
    if (currentShop == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No shop is selected!')));
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    try {
      final newSale = Sale(
        id:
            '${currentShop.name.replaceAll(' ', '_')}_sale_${DateTime.now().millisecondsSinceEpoch}', // ID will be generated by provider
        items: List<SaleItem>.from(_cartItems),
        totalAmount:
            _grandTotal + _discountAmount, // Original total before discount
        grandTotal: _grandTotal, // Final total after discount
        vat: 0.0,
        turnoverTax: 0.0,
        levy: 0.0,
        date: DateTime.now(),
        shopId: currentShop.id,
        createdBy: currentUser.id, // Will be set by provider
        customerName: _customerNameController.text.trim(),
        customerPhone: _customerPhoneController.text.trim(),
        discount: _discountAmount,
      );

      await Provider.of<SalesProvider>(context, listen: false).addSaleHybrid(
        newSale,
        currentUser.id,
        currentShop.id,
        Provider.of<BusinessProvider>(context, listen: false),
      );

      for (var item in _cartItems) {
        await Provider.of<InventoryProvider>(
          context,
          listen: false,
        ).saleStock(item.product.id, item.quantity);
      }

      // Print receipt and open cash drawer if printer is connected
      bool printed = false;
      bool drawerOpened = false;
      if (_deviceManager != null) {
        try {
          // Print receipt (implement your own formatting as needed)
          // Example: just print total
          if (_deviceManager.receiptPrinterConnected) {
            await _deviceManager.printReceipt({
              'saleId': newSale.id,
              'date': newSale.date.toIso8601String(),
              'items': newSale.items.map((item) => {
                'name': item.product.name,
                'quantity': item.quantity,
                'price': item.product.price,
                'total': item.quantity * item.product.price,
              }).toList(),
              'total': newSale.grandTotal,
              'businessName': 'Kantemba Finances',
            });
            printed = true;
          }
          // Open cash drawer
          drawerOpened = await _deviceManager.openCashDrawer();
        } catch (e) {
          // Ignore print/drawer errors, show below
        }
      }

      if (mounted) {
        setState(() {
          _lastCompletedSale = newSale;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sale added! Total: K${_grandTotal.toStringAsFixed(2)}'
              + (printed ? '\nReceipt printed.' : '')
              + (drawerOpened ? '\nDrawer opened.' : ''),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add sale: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  List<InventoryItem> _getFilteredProducts() {
    final availableProducts =
        Provider.of<InventoryProvider>(
          context,
        ).items.where((product) => product.quantity > 0).toList();

    // Filter by search query
    List<InventoryItem> filtered = availableProducts;

    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered.where((product) {
            return product.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                (product.barcode?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false);
          }).toList();
    }

    // Filter by barcode query
    if (_barcodeQuery.isNotEmpty) {
      filtered =
          filtered.where((product) {
            return product.barcode?.toLowerCase().contains(
                  _barcodeQuery.toLowerCase(),
                ) ??
                false;
          }).toList();
    }

    return filtered;
  }

  /// Camera-based barcode scan
  Future<void> _scanBarcodeWithCamera() async {
    try {
      // Navigate to scanner screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => MobileScanner(
                onDetect: (capture) {
                  final List<mobile_scanner.Barcode> barcodes =
                      capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    final barcode = barcodes.first.rawValue;
                    if (barcode != null && barcode.isNotEmpty) {
                      setState(() {
                        _barcodeController.text = barcode;
                      });
                      _handleBarcodeScanned(barcode);
                      Navigator.pop(context, barcode);
                    }
                  }
                },
              ),
        ),
      );

      if (result != null && result is String) {
        setState(() {
          _barcodeController.text = result;
        });
        _handleBarcodeScanned(result);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Camera scan failed: $e')));
    }
  }

  Future<void> _connectBluetoothScanner() async {
    setState(() {
      _isBluetoothConnecting = true;
    });
    List<BluetoothDevice> devices = [];
    try {
      // Get connected devices
      devices = await FlutterBluePlus.connectedDevices;
      // Start scanning for new devices
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
      await Future.delayed(const Duration(seconds: 4));
      await FlutterBluePlus.stopScan();
      // Get scan results
      final scanResults = FlutterBluePlus.scanResults;
      await for (var results in scanResults) {
        for (var result in results) {
          if (!devices.contains(result.device)) {
            devices.add(result.device);
          }
        }
      }
    } catch (e) {
      setState(() {
        _isBluetoothConnecting = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Bluetooth scan failed: $e')));
      return;
    }
    setState(() {
      _isBluetoothConnecting = false;
    });
    // Show device selection dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Bluetooth Scanner'),
            content:
                devices.isEmpty
                    ? const Text('No Bluetooth devices found.')
                    : SizedBox(
                      width: 300,
                      height: 300,
                      child: ListView.builder(
                        itemCount: devices.length,
                        itemBuilder:
                            (ctx, i) => ListTile(
                              title: Text(
                                devices[i].name.isNotEmpty
                                    ? devices[i].name
                                    : devices[i].id.toString(),
                              ),
                              subtitle: Text(devices[i].id.toString()),
                              onTap: () async {
                                Navigator.of(context).pop();
                                await _connectToBluetoothDevice(devices[i]);
                              },
                            ),
                      ),
                    ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  Future<void> _connectToBluetoothDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      setState(() {
        _connectedBluetoothDevice = device;
      });
      // Listen for data from the device
      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);
            characteristic.value.listen((value) {
              final barcode = String.fromCharCodes(value);
              if (barcode.isNotEmpty) {
                setState(() {
                  _barcodeController.text = barcode;
                });
                _handleBarcodeScanned(barcode);
              }
            });
          }
        }
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Connected to ${device.name}')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to connect: $e')));
    }
  }

  Future<void> _connectUsbScanner() async {
    setState(() {
      _isUsbConnecting = true;
    });
    List<UsbDevice> devices = await UsbSerial.listDevices();
    setState(() {
      _isUsbConnecting = false;
    });
    // Show device selection dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select USB Scanner'),
            content:
                devices.isEmpty
                    ? const Text('No USB devices found.')
                    : SizedBox(
                      width: 300,
                      height: 300,
                      child: ListView.builder(
                        itemCount: devices.length,
                        itemBuilder:
                            (ctx, i) => ListTile(
                              title: Text(
                                devices[i].productName ?? 'Unknown USB Device',
                              ),
                              subtitle: Text(
                                'VID: ${devices[i].vid}, PID: ${devices[i].pid}',
                              ),
                              onTap: () async {
                                Navigator.of(context).pop();
                                await _connectToUsbDevice(devices[i]);
                              },
                            ),
                      ),
                    ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  Future<void> _connectToUsbDevice(UsbDevice device) async {
    try {
      _usbPort = await device.create();
      if (_usbPort == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to open USB device.')));
        return;
      }
      await _usbPort!.open();
      await _usbPort!.setDTR(true);
      await _usbPort!.setRTS(true);
      await _usbPort!.setPortParameters(
        9600,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );
      _usbPort!.inputStream?.listen((data) {
        final barcode = String.fromCharCodes(data).trim();
        if (barcode.isNotEmpty) {
          setState(() {
            _barcodeController.text = barcode;
          });
          _handleBarcodeScanned(barcode);
        }
      });
      setState(() {
        _connectedUsbDevice = device;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Connected to USB device: ${device.productName ?? device.deviceId}',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to connect USB: $e')));
    }
  }

  // Enable printer connection and printing logic
  Future<void> _connectPrinter() async {
    await _deviceManager.showDeviceSelectionDialog(context, 'printer');
    setState(() {});
  }

  Future<void> _printReceipt(Sale sale) async {
    final receiptData = {
      'id': sale.id,
      'date': sale.date.toString(),
      'items': sale.items.map((item) => {
        'name': item.product.name,
        'quantity': item.quantity,
        'price': item.product.price.toStringAsFixed(2),
      }).toList(),
      'grandTotal': sale.grandTotal.toStringAsFixed(2),
    };
    final success = await _deviceManager.printReceipt(receiptData);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to print receipt.')),
      );
    }
  }

  // 1. Add Bluetooth printer scan/connect dialog and test print
  Future<void> _scanAndConnectBluetoothPrinter() async {
    setState(() => _isBluetoothPrinterConnecting = true);
    final List<btp.BluetoothDevice> devices = await _bluetooth.getBondedDevices();
    setState(() => _isBluetoothPrinterConnecting = false);
    if (devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No Bluetooth printers found.')),
      );
      return;
    }
    btp.BluetoothDevice? selected = await showDialog<btp.BluetoothDevice>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Bluetooth Printer'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: ListView.builder(
            itemCount: devices.length,
            itemBuilder: (ctx, i) => ListTile(
              title: Text(devices[i].name ?? 'Unknown'),
              subtitle: Text(devices[i].address ?? ''),
              onTap: () => Navigator.of(context).pop(devices[i]),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (selected != null) {
      setState(() => _selectedBluetoothPrinter = selected);
      final res = await _bluetooth.connect(selected);
      if (res == btp.BlueThermalPrinter.CONNECTED) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connected to ${selected.name}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect: $res')),
        );
      }
    }
  }

  // Add fallback alignment constants if not defined by the package
  // const int ALIGN_LEFT = 0;
  // const int ALIGN_CENTER = 1;
  // const int ALIGN_RIGHT = 2;

  Future<void> _testBluetoothPrint() async {
    if (_selectedBluetoothPrinter == null) return;
    setState(() => _isBluetoothPrinting = true);
    await _bluetooth.printNewLine();
    await _bluetooth.printCustom(
      'Test Print',
      3, // SIZE_LARGE
      ALIGN_CENTER,
    );
    await _bluetooth.printCustom(
      'Kantemba Finances',
      2, // SIZE_MEDIUM
      ALIGN_CENTER,
    );
    await _bluetooth.printNewLine();
    setState(() => _isBluetoothPrinting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sent test print to Bluetooth printer.')),
    );
  }

  // 2. Add USB printer list/connect dialog and test print
  Future<void> _scanAndConnectUsbPrinter() async {
    setState(() => _isUsbPrinterConnecting = true);
    final devices = await UsbSerial.listDevices();
    setState(() => _isUsbPrinterConnecting = false);
    if (devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No USB printers found.')),
      );
      return;
    }
    UsbDevice? selected = await showDialog<UsbDevice>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select USB Printer'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: ListView.builder(
            itemCount: devices.length,
            itemBuilder: (ctx, i) => ListTile(
              title: Text(devices[i].productName ?? 'Unknown'),
              subtitle: Text('VID: ${devices[i].vid}, PID: ${devices[i].pid}'),
              onTap: () => Navigator.of(context).pop(devices[i]),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (selected != null) {
      setState(() => _selectedUsbPrinter = selected);
      _usbPrinterPort = await selected.create();
      if (_usbPrinterPort != null) {
        await _usbPrinterPort!.open();
        await _usbPrinterPort!.setDTR(true);
        await _usbPrinterPort!.setRTS(true);
        await _usbPrinterPort!.setPortParameters(
          9600,
          UsbPort.DATABITS_8,
          UsbPort.STOPBITS_1,
          UsbPort.PARITY_NONE,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connected to ${selected.productName}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open USB printer.')),
        );
      }
    }
  }

  Future<void> _testUsbPrint() async {
    if (_usbPrinterPort == null) return;
    setState(() => _isUsbPrinting = true);
    // Example: Send raw ESC/POS command for test print
    final List<int> bytes = [];
    bytes.addAll([27, 64]); // Initialize
    bytes.addAll('Test Print\nKantemba Finances\n'.codeUnits);
    bytes.addAll([10, 10, 10]); // Feed
    await _usbPrinterPort!.write(Uint8List.fromList(bytes));
    setState(() => _isUsbPrinting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sent test print to USB printer.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _getFilteredProducts();
    final barcodeConnected = _deviceManager.barcodeScannerConnected;
    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    if (isWindows(context)) {
      // Desktop layout: 3 columns, wide, responsive
      final screenWidth = MediaQuery.of(context).size.width;
      final maxModalWidth =
          screenWidth < 1200
              ? (screenWidth * 0.8).clamp(900.0, 1200.0)
              : 1200.0;
      final maxModalHeight = MediaQuery.of(context).size.height * 0.9;

      return Material(
        child: Center(
          child: Container(
            width: maxModalWidth,
            height: maxModalHeight,
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: Theme.of(context).dialogBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'New Sale',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Barcode device status indicator
                Row(
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      color:
                          barcodeConnected
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      barcodeConnected
                          ? '${_deviceManager.scannerDeviceName} Connected'
                          : 'No Barcode Scanner Connected',
                      style: TextStyle(
                        color:
                            barcodeConnected
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (!barcodeConnected)
                      ElevatedButton.icon(
                        onPressed: _initializeDevices,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Connect/Refresh'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    if (!barcodeConnected)
                      ElevatedButton.icon(
                        onPressed: _scanBarcodeWithCamera,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Scan with Camera'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child:
                      (maxModalWidth < 600 || screenWidth < 600)
                          ? SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildColumn1(
                                  context,
                                  BoxConstraints(),
                                  true,
                                  barcodeConnected,
                                ),
                                const SizedBox(height: 16),
                                _buildColumn2(context, BoxConstraints(), true),
                                const SizedBox(height: 16),
                                _buildColumn3(context, BoxConstraints(), true),
                              ],
                            ),
                          )
                          : (maxModalWidth < 900 || screenWidth < 900)
                          ? Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildColumn1(
                                  context,
                                  BoxConstraints(),
                                  true,
                                  barcodeConnected,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 3,
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      _buildColumn2(
                                        context,
                                        BoxConstraints(),
                                        true,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildColumn3(
                                        context,
                                        BoxConstraints(),
                                        true,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                          : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildColumn1(
                                  context,
                                  BoxConstraints(),
                                  false,
                                  barcodeConnected,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 3,
                                child: _buildColumn2(
                                  context,
                                  BoxConstraints(),
                                  false,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 2,
                                child: _buildColumn3(
                                  context,
                                  BoxConstraints(),
                                  false,
                                ),
                              ),
                            ],
                          ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Mobile layout
    return Material(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'New Sale',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              // Barcode device status indicator
              Row(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    color:
                        barcodeConnected
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    barcodeConnected ? 'Connected' : 'Disconnected',
                    style: TextStyle(
                      color:
                          barcodeConnected
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (!barcodeConnected) ...[
                    IconButton(
                      onPressed: _initializeDevices,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh Devices',
                      color: Colors.green.shade700,
                    ),
                    IconButton(
                      onPressed: _scanBarcodeWithCamera,
                      icon: const Icon(Icons.camera_alt),
                      tooltip: 'Scan with Camera',
                      color: Colors.green.shade700,
                    ),
                    IconButton(
                      onPressed: _connectBluetoothScanner,
                      icon: const Icon(Icons.bluetooth_searching),
                      tooltip: 'Connect Bluetooth Scanner',
                      color: Colors.blue.shade700,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              // Search bar (searches both name and barcode)
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search product (name or barcode)',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _handleBarcodeScanned(
                      value,
                    ); // Use the same handler for barcode/manual
                  }
                },
              ),
              const SizedBox(height: 12),
              // Remove barcode scan input and use only the main search bar
              if (barcodeConnected && _lastScannedBarcode.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Last scanned: $_lastScannedBarcode',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
              // Product list
              SizedBox(
                height: 180,
                child:
                    filteredProducts.isEmpty
                        ? const Center(child: Text('No products found'))
                        : ListView.builder(
                          itemCount: filteredProducts.length,
                          itemBuilder: (ctx, i) {
                            final product = filteredProducts[i];
                            return ListTile(
                              title: Text(product.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Price: ${product.price.toStringAsFixed(2)} | Stock: ${product.quantity}',
                                  ),
                                  if (product.barcode != null) ...[
                                    Text(
                                      'Barcode: ${product.barcode}',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontSize: 12,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.add),
                                onPressed:
                                    product.quantity == 0
                                        ? null
                                        : () => _addProductToCart(product),
                                color:
                                    product.quantity == 0
                                        ? Colors.grey
                                        : Theme.of(context).iconTheme.color,
                                tooltip:
                                    product.quantity == 0
                                        ? 'Out of stock'
                                        : 'Add to cart',
                              ),
                            );
                          },
                        ),
              ),
              const Divider(),
              // Cart items
              if (_cartItems.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Cart', style: Theme.of(context).textTheme.titleMedium),
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    itemCount: _cartItems.length,
                    itemBuilder: (ctx, i) {
                      final cartItem = _cartItems[i];
                      return ListTile(
                        title: Text(cartItem.product.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Unit: ${cartItem.product.price.toStringAsFixed(2)} | Qty: ${cartItem.quantity} | Total: ${(cartItem.product.price * cartItem.quantity).toStringAsFixed(2)}',
                            ),
                            if (cartItem.product.barcode != null) ...[
                              Text(
                                'Barcode: ${cartItem.product.barcode}',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ],
                        ),
                        leading: IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed:
                              () => _removeProductFromCart(cartItem.product.id),
                          tooltip: 'Remove from cart',
                          iconSize: 28,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                if (cartItem.quantity > 1) {
                                  _updateQuantity(
                                    cartItem.product.id,
                                    cartItem.quantity - 1,
                                  );
                                }
                              },
                              tooltip: 'Decrease quantity',
                              iconSize: 28,
                            ),
                            Text('${cartItem.quantity}'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                _updateQuantity(
                                  cartItem.product.id,
                                  cartItem.quantity + 1,
                                );
                              },
                              tooltip: 'Increase quantity',
                              iconSize: 28,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // Customer Information Section
                Text(
                  'Customer Information',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _customerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _customerPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 8),
                TextField(
                  controller: _discountController,
                  decoration: const InputDecoration(
                    labelText: 'Discount Amount',
                    border: OutlineInputBorder(),
                    prefixText: 'K',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged: _updateDiscount,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      (_grandTotal + _discountAmount).toStringAsFixed(2),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                if (_discountAmount > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Discount:',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.red),
                      ),
                      Text(
                        '-${_discountAmount.toStringAsFixed(2)}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.red),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _grandTotal.toStringAsFixed(2),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear Cart'),
                      onPressed: _clearCart,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.print),
                    tooltip: _selectedBluetoothPrinter == null ? 'Connect Bluetooth Printer' : 'Bluetooth Printer Connected',
                    color: _selectedBluetoothPrinter == null ? Colors.grey : Colors.blue,
                    onPressed: _scanAndConnectBluetoothPrinter,
                  ),
                  if (_selectedBluetoothPrinter != null)
                    IconButton(
                      icon: _isBluetoothPrinting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.receipt_long),
                      tooltip: 'Test Print (Bluetooth)',
                      color: Colors.blue,
                      onPressed: _isBluetoothPrinting ? null : _testBluetoothPrint,
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.usb),
                    tooltip: _selectedUsbPrinter == null ? 'Connect USB Printer' : 'USB Printer Connected',
                    color: _selectedUsbPrinter == null ? Colors.grey : Colors.deepOrange,
                    onPressed: _scanAndConnectUsbPrinter,
                  ),
                  if (_selectedUsbPrinter != null)
                    IconButton(
                      icon: _isUsbPrinting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.receipt_long),
                      tooltip: 'Test Print (USB)',
                      color: Colors.deepOrange,
                      onPressed: _isUsbPrinting ? null : _testUsbPrint,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Add Sale button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _isProcessing || _cartItems.isEmpty ? null : _addSale,
                  child:
                      _isProcessing
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Add Sale'),
                ),
              ),
              // Print Receipt button (after sale) - Temporarily disabled
              // if (_cartItems.isEmpty &&
              //     _selectedPrinter != null &&
              //     _lastCompletedSale != null)
              //   ElevatedButton.icon(
              //     onPressed:
              //         _isPrinting
              //             ? null
              //             : () {
              //       // _printReceipt(_lastCompletedSale!);  // Temporarily disabled
              //       ScaffoldMessenger.of(context).showSnackBar(
              //         const SnackBar(content: Text('Printing temporarily disabled')),
              //       );
              //     },
              //       icon: const Icon(Icons.receipt_long),
              //       label:
              //           _isPrinting
              //               ? const Text('Printing...')
              //               : const Text('Print Receipt'),
              //       style: ElevatedButton.styleFrom(
              //         backgroundColor: Colors.deepPurple.shade700,
              //         foregroundColor: Colors.white,
              //       ),
              //     ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColumn1(
    BuildContext context,
    BoxConstraints constraints,
    bool isNarrow,
    bool barcodeConnected,
  ) {
    final filteredProducts = _getFilteredProducts();
    Widget productList = Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child:
          filteredProducts.isEmpty
              ? const Center(child: Text('No products found'))
              : Scrollbar(
                thumbVisibility: true,
                child: ListView.builder(
                  itemCount: filteredProducts.length,
                  itemBuilder: (ctx, i) {
                    final product = filteredProducts[i];
                    return ListTile(
                      title: Text(product.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Price: ${product.price.toStringAsFixed(2)} | Stock: ${product.quantity}',
                          ),
                          if (product.barcode != null) ...[
                            Text(
                              'Barcode: ${product.barcode}',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed:
                            product.quantity == 0
                                ? null
                                : () => _addProductToCart(product),
                        color:
                            product.quantity == 0
                                ? Colors.grey
                                : Theme.of(context).iconTheme.color,
                        tooltip:
                            product.quantity == 0
                                ? 'Out of stock'
                                : 'Add to cart',
                      ),
                    );
                  },
                ),
              ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar (searches both name and barcode)
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Search product (name or barcode)',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              _handleBarcodeScanned(
                value,
              ); // Use the same handler for barcode/manual
            }
          },
        ),
        const SizedBox(height: 12),
        // Remove barcode scan input and use only the main search bar
        if (barcodeConnected && _lastScannedBarcode.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Last scanned: $_lastScannedBarcode',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
        if (!barcodeConnected) ...[const SizedBox(height: 12)],
        isNarrow
            ? SizedBox(height: 200, child: productList)
            : Expanded(child: productList),
      ],
    );
  }

  Widget _buildColumn2(
    BuildContext context,
    BoxConstraints constraints,
    bool isNarrow,
  ) {
    Widget cartList = Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child:
          _cartItems.isEmpty
              ? const Center(child: Text('No items in cart'))
              : Scrollbar(
                thumbVisibility: true,
                child: ListView.builder(
                  itemCount: _cartItems.length,
                  itemBuilder: (ctx, i) {
                    final cartItem = _cartItems[i];
                    return ListTile(
                      title: Text(cartItem.product.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unit: ${cartItem.product.price.toStringAsFixed(2)} | Qty: ${cartItem.quantity} | Total: ${(cartItem.product.price * cartItem.quantity).toStringAsFixed(2)}',
                          ),
                          if (cartItem.product.barcode != null) ...[
                            Text(
                              'Barcode: ${cartItem.product.barcode}',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ],
                      ),
                      leading: IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed:
                            () => _removeProductFromCart(cartItem.product.id),
                        tooltip: 'Remove from cart',
                        iconSize: 28,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              if (cartItem.quantity > 1) {
                                _updateQuantity(
                                  cartItem.product.id,
                                  cartItem.quantity - 1,
                                );
                              }
                            },
                            tooltip: 'Decrease quantity',
                            iconSize: 28,
                          ),
                          Text('${cartItem.quantity}'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              _updateQuantity(
                                cartItem.product.id,
                                cartItem.quantity + 1,
                              );
                            },
                            tooltip: 'Increase quantity',
                            iconSize: 28,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cart', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        isNarrow
            ? SizedBox(height: 200, child: cartList)
            : Expanded(child: cartList),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.clear),
              label: const Text('Clear Cart'),
              onPressed: _clearCart,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Subtotal:', style: Theme.of(context).textTheme.bodyMedium),
            Text(
              (_grandTotal + _discountAmount).toStringAsFixed(2),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        if (_discountAmount > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Discount:',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.red),
              ),
              Text(
                '-${_discountAmount.toStringAsFixed(2)}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.red),
              ),
            ],
          ),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total:',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              _grandTotal.toStringAsFixed(2),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColumn3(
    BuildContext context,
    BoxConstraints constraints,
    bool isNarrow,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer Information',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _customerNameController,
          decoration: const InputDecoration(
            labelText: 'Customer Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _customerPhoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _discountController,
          decoration: const InputDecoration(
            labelText: 'Discount Amount',
            border: OutlineInputBorder(),
            prefixText: 'K',
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          onChanged: _updateDiscount,
        ),
        // Add tax info fields here if needed
        // const SizedBox(height: 8),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isProcessing || _cartItems.isEmpty ? null : _addSale,
            child:
                _isProcessing
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Add Sale'),
          ),
        ),
      ],
    );
  }
}
