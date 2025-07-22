import 'package:flutter/material.dart';
import 'package:kantemba_finances/models/expense.dart';
import 'package:kantemba_finances/models/shop.dart';
import 'package:kantemba_finances/providers/business_provider.dart';
import 'package:kantemba_finances/providers/expenses_provider.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/providers/inventory_provider.dart';
import 'package:kantemba_finances/widgets/new_inventory_modal.dart';
import '../providers/shop_provider.dart';
import '../providers/users_provider.dart';
import 'package:kantemba_finances/helpers/platform_helper.dart';
import 'package:intl/intl.dart';
import 'package:kantemba_finances/models/inventory_item.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:usb_serial/usb_serial.dart';
import '../helpers/analytics_service.dart';

// Import POS device manager from POS screen
import 'pos_screen.dart';

class CheckboxController {
  bool _value = false;
  bool get value => _value;
  set value(bool newValue) {
    _value = newValue;
  }
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'name'; // 'name', 'quantity', 'price', 'shop', 'barcode'
  bool _sortAscending = true;
  bool _showLowStockOnly = false;
  bool _showBarcodeOnly = false;

  // POS Device Manager for barcode scanning
  final PosDeviceManager _deviceManager = PosDeviceManager();
  String _lastScannedBarcode = '';
  bool _isDeviceInitialized = false;

  UsbPort? _usbPort;
  UsbDevice? _connectedUsbDevice;
  bool _isUsbConnecting = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logEvent('screen_open', data: {'screen': 'Inventory'});
    _initializeDevices();
    _setupBarcodeListener();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _barcodeController.dispose();
    _deviceManager.dispose();
    super.dispose();
  }

  /// Initialize POS devices
  Future<void> _initializeDevices() async {
    await _deviceManager.initializeDevices();
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
      _showProductFoundDialog(product);
    } else {
      _showProductNotFoundDialog(barcode);
    }
  }

  /// Show dialog when product is found
  void _showProductFoundDialog(InventoryItem product) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Product Found'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${product.name}'),
                Text('Price: K${product.price.toStringAsFixed(2)}'),
                Text('Stock: ${product.quantity}'),
                Text('Barcode: ${product.barcode ?? 'N/A'}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showRestockDialog(context, product);
                },
                child: const Text('Restock'),
              ),
            ],
          ),
    );
  }

  /// Show dialog when product is not found
  void _showProductNotFoundDialog(String barcode) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Product Not Found'),
            content: Text('No product found with barcode: $barcode'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showAddProductDialog(barcode);
                },
                child: const Text('Add New Product'),
              ),
            ],
          ),
    );
  }

  /// Show dialog to add new product
  void _showAddProductDialog(String barcode) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add New Product'),
            content: const Text(
              'Would you like to add a new product with this barcode?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showAddInventoryModal(barcode);
                },
                child: const Text('Add Product'),
              ),
            ],
          ),
    );
  }

  /// Scan for new devices
  Future<void> _scanForDevices() async {
    try {
      await _deviceManager.initializeDevices();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Scanning for devices...')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error scanning for devices: $e')));
    }
  }

  /// Show add inventory modal with pre-filled barcode
  void _showAddInventoryModal(String barcode) {
    if (isWindows(context)) {
      showDialog(
        context: context,
        builder:
            (ctx) => Dialog(
              child: SizedBox(
                width: 600,
                child: NewInventoryModal(
                  prefilledBarcode: barcode,
                  barcodeDeviceConnected:
                      _deviceManager.barcodeScannerConnected,
                  onConnectBarcodeDevice: _scanForDevices,
                ),
              ),
            ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder:
            (ctx) => NewInventoryModal(
              prefilledBarcode: barcode,
              barcodeDeviceConnected: _deviceManager.barcodeScannerConnected,
              onConnectBarcodeDevice: _scanForDevices,
            ),
      );
    }
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
                  final List<Barcode> barcodes = capture.barcodes;
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
                                'VID:  {devices[i].vid}, PID: ${devices[i].pid}',
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

  List<InventoryItem> _getFilteredAndSortedItems(List<InventoryItem> items) {
    // Filter by search query
    List<InventoryItem> filtered =
        items.where((item) {
          if (_searchQuery.isEmpty) return true;
          return item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (item.barcode?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  false);
        }).toList();

    // Filter by low stock if enabled
    if (_showLowStockOnly) {
      filtered =
          filtered
              .where((item) => item.quantity <= item.lowStockThreshold)
              .toList();
    }

    // Filter by barcode if enabled
    if (_showBarcodeOnly) {
      filtered =
          filtered
              .where((item) => item.barcode != null && item.barcode!.isNotEmpty)
              .toList();
    }

    // Sort items
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'quantity':
          comparison = a.quantity.compareTo(b.quantity);
          break;
        case 'price':
          comparison = a.price.compareTo(b.price);
          break;
        case 'shop':
          comparison = a.shopId.compareTo(b.shopId);
          break;
        case 'barcode':
          comparison = (a.barcode ?? '').compareTo(b.barcode ?? '');
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  Widget _buildSearchAndSortBar() {
    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          // Device status indicator for barcode scanner
          Row(
            children: [
              Icon(
                Icons.qr_code_scanner,
                color:
                    _deviceManager.barcodeScannerConnected
                        ? Colors.green.shade700
                        : Colors.red.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                _deviceManager.barcodeScannerConnected
                    ? 'Connected'
                    : 'Disconnected',
                style: TextStyle(
                  color:
                      _deviceManager.barcodeScannerConnected
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (!_deviceManager.barcodeScannerConnected) ...[
                IconButton(
                  onPressed:
                      () => _deviceManager.showDeviceSelectionDialog(context, 'scanner'),
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
          // Search bar and sort options in the same row
          Row(
            children: [
              // Expanded search bar
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by item name or barcode...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  onSubmitted: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Sort by dropdown
              DropdownButton<String>(
                value: _sortBy,
                items: const [
                  DropdownMenuItem(value: 'name', child: Text('Name')),
                  DropdownMenuItem(value: 'quantity', child: Text('Qty')),
                  DropdownMenuItem(value: 'price', child: Text('Price')),
                  DropdownMenuItem(value: 'shop', child: Text('Shop')),
                  DropdownMenuItem(value: 'barcode', child: Text('Barcode')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _sortBy = value;
                    });
                  }
                },
                underline: Container(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              IconButton(
                icon: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                ),
                tooltip: _sortAscending ? 'Ascending' : 'Descending',
                onPressed: () {
                  setState(() {
                    _sortAscending = !_sortAscending;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Remove barcode scan input and section, as search is now integrated
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventoryData = Provider.of<InventoryProvider>(context);
    final userProvider = Provider.of<UsersProvider>(context);
    final user = userProvider.currentUser;

    return Consumer<ShopProvider>(
      builder: (context, shopProvider, child) {
        // Use filtered items based on current shop
        final allItems = inventoryData.getItemsForShop(
          shopProvider.currentShop,
        );
        final items = _getFilteredAndSortedItems(allItems);

        if (isWindows(context)) {
          // Desktop layout: Centered, max width, header add button, table-like list
          return Scaffold(
            appBar: AppBar(
              title: const Text('Inventory'),
              actions: [
                IconButton(
                  icon: Icon(_deviceManager.barcodeScannerConnected ? Icons.qr_code_scanner : Icons.qr_code),
                  tooltip: _deviceManager.barcodeScannerConnected ? 'Scanner Connected' : 'Connect Scanner',
                  onPressed: () => _deviceManager.showDeviceSelectionDialog(context, 'scanner'),
                ),
              ],
            ),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search and sort bar
                      _buildSearchAndSortBar(),
                      const SizedBox(height: 16),

                      // Table header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        color: Colors.grey.shade100,
                        child: Row(
                          children: const [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Name',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Barcode',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Quantity',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Shop',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Price',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 0),
                      Expanded(
                        child:
                            items.isEmpty
                                ? const Center(
                                  child: Text('No inventory items found.'),
                                )
                                : ListView.builder(
                                  itemCount: items.length,
                                  itemBuilder: (ctx, i) {
                                    final item = items[i];
                                    final shop = shopProvider.shops.firstWhere(
                                      (s) => s.id == item.shopId,
                                      orElse: () => shopProvider.shops.first,
                                    );
                                    final isLowStock =
                                        item.quantity <= item.lowStockThreshold;

                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey.shade200,
                                          ),
                                        ),
                                        color:
                                            isLowStock
                                                ? Colors.orange.shade50
                                                : null,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: Row(
                                              children: [
                                                Text(item.name),
                                                if (isLowStock) ...[
                                                  const SizedBox(width: 8),
                                                  Icon(
                                                    Icons.warning,
                                                    color:
                                                        Colors.orange.shade700,
                                                    size: 16,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              item.barcode ?? 'N/A',
                                              style: TextStyle(
                                                color:
                                                    item.barcode != null
                                                        ? Colors.green.shade700
                                                        : Colors.grey.shade500,
                                                fontSize: 12,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              item.quantity.toString(),
                                              style: TextStyle(
                                                color:
                                                    isLowStock
                                                        ? Colors.orange.shade700
                                                        : null,
                                                fontWeight:
                                                    isLowStock
                                                        ? FontWeight.bold
                                                        : null,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              shop.name,
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Row(
                                              children: [
                                                Text(
                                                  'K${item.price.toStringAsFixed(2)}',
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.add),
                                                  tooltip: 'Restock',
                                                  onPressed:
                                                      () => _showRestockDialog(
                                                        context,
                                                        item,
                                                      ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.remove_circle_outline,
                                                  ),
                                                  tooltip: 'Mark as Damaged',
                                                  color: Colors.orange,
                                                  onPressed:
                                                      () => _showDamagedDialog(
                                                        context,
                                                        item,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                      ),
                      // Bottom spacing for floating buttons
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
            floatingActionButton: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (user != null &&
                    (user.permissions.contains('add_inventory') ||
                        user.permissions.contains('all') ||
                        user.role == 'admin' ||
                        user.role == 'owner'))
                  FloatingActionButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder:
                            (ctx) => Dialog(
                              child: SizedBox(
                                width: 600,
                                child: NewInventoryModal(),
                              ),
                            ),
                      );
                    },
                    backgroundColor: Colors.green.shade700,
                    child: const Icon(Icons.add),
                  ),
                const SizedBox(width: 16),
                FloatingActionButton(
                  onPressed: () => _showAllDamagedGoodsDialog(context),
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.warning_amber_rounded),
                ),
                const SizedBox(width: 16),
                FloatingActionButton(
                  onPressed: () => _showLowStockItemsDialog(context),
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.inventory_2),
                ),
              ],
            ),
          );
        }

        // Mobile layout
        return Scaffold(
          appBar: AppBar(
            title: const Text('Inventory'),
            actions: [
              IconButton(
                icon: Icon(_deviceManager.barcodeScannerConnected ? Icons.qr_code_scanner : Icons.qr_code),
                tooltip: _deviceManager.barcodeScannerConnected ? 'Scanner Connected' : 'Connect Scanner',
                onPressed: () => _deviceManager.showDeviceSelectionDialog(context, 'scanner'),
              ),
            ],
          ),
          body: Column(
            children: [
              // Search and sort bar for mobile
              _buildSearchAndSortBar(),
              Expanded(
                child:
                    items.isEmpty
                        ? const Center(child: Text('No inventory items found.'))
                        : ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (ctx, i) {
                            final item = items[i];
                            final shop = shopProvider.shops.firstWhere(
                              (s) => s.id == item.shopId,
                              orElse: () => shopProvider.shops.first,
                            );
                            final isLowStock =
                                item.quantity <= item.lowStockThreshold;

                            return ListTile(
                              title: Row(
                                children: [
                                  Text(item.name),
                                  if (isLowStock) ...[
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.warning,
                                      color: Colors.orange.shade700,
                                      size: 16,
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Quantity: ${item.quantity}',
                                    style: TextStyle(
                                      color:
                                          isLowStock
                                              ? Colors.orange.shade700
                                              : null,
                                      fontWeight:
                                          isLowStock ? FontWeight.bold : null,
                                    ),
                                  ),
                                  Text(
                                    'Shop: ${shop.name}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (item.barcode != null) ...[
                                    Text(
                                      'Barcode: ${item.barcode}',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontSize: 12,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('K${item.price.toStringAsFixed(2)}'),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    tooltip: 'Restock',
                                    onPressed:
                                        () => _showRestockDialog(context, item),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                    tooltip: 'Mark as Damaged',
                                    color: Colors.orange,
                                    onPressed:
                                        () => _showDamagedDialog(context, item),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
              ),
              // Bottom spacing for floating buttons
              const SizedBox(height: 80),
            ],
          ),
          floatingActionButton: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (user != null &&
                  (user.permissions.contains('add_inventory') ||
                      user.permissions.contains('all') ||
                      user.role == 'admin' ||
                      user.role == 'owner'))
                FloatingActionButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (ctx) => NewInventoryModal(),
                    );
                  },
                  backgroundColor: Colors.green.shade700,
                  child: const Icon(Icons.add),
                ),
              const SizedBox(width: 8),
              FloatingActionButton(
                onPressed: () => _showAllDamagedGoodsDialog(context),
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                child: const Icon(Icons.warning_amber_rounded),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                onPressed: () => _showLowStockItemsDialog(context),
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                child: const Icon(Icons.inventory_2),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRestockDialog(BuildContext context, InventoryItem item) {
    final _unitsController = TextEditingController();
    final _priceController = TextEditingController(
      text: item.price.toStringAsFixed(2),
    );
    final _bulkPriceController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Restock ${item.name}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _unitsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Units to add',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Update selling price (optional)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bulkPriceController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Bulk purchase price',
                      hintText: 'Enter the cost you paid',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final units = int.tryParse(_unitsController.text);
                  final price = double.tryParse(_priceController.text);
                  final bulkPrice = double.tryParse(_bulkPriceController.text);

                  if (units == null || units <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enter valid units'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (bulkPrice == null || bulkPrice <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enter valid bulk purchase price'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final usersProvider = Provider.of<UsersProvider>(
                    context,
                    listen: false,
                  );
                  final shopProvider = Provider.of<ShopProvider>(
                    context,
                    listen: false,
                  );

                  // Ensure user session is available
                  if (usersProvider.currentUser == null) {
                    // Try to wait for initialization
                    if (!usersProvider.isInitialized) {
                      int attempts = 0;
                      while (!usersProvider.isInitialized && attempts < 10) {
                        await Future.delayed(const Duration(milliseconds: 100));
                        attempts++;
                      }
                    }

                    if (usersProvider.currentUser == null) {
                      throw Exception(
                        'No user is logged in! Please log in again.',
                      );
                    }
                  }

                  final inventoryProvider = Provider.of<InventoryProvider>(
                    context,
                    listen: false,
                  );
                  final expensesProvider = Provider.of<ExpensesProvider>(
                    context,
                    listen: false,
                  );

                  final currentShop = shopProvider.currentShop;
                  if (currentShop == null) {
                    throw Exception('No shop is selected!');
                  }

                  try {
                    await inventoryProvider
                        .increaseStockAndUpdatePriceWithBulkPurchase(
                          item.id,
                          units,
                          price ?? item.price,
                          bulkPrice,
                          true,
                        );
                    final expenseId =
                        'expense_${DateTime.now().millisecondsSinceEpoch}';
                    final currentShopId =
                        shopProvider.currentShop?.id ?? item.shopId;

                    final expense = Expense(
                      id: expenseId,
                      description:
                          'Bulk purchase: ${item.name} (${units} units @ K${bulkPrice.toStringAsFixed(2)})',
                      amount: bulkPrice,
                      date: DateTime.now(),
                      category: 'Inventory Purchase',
                      createdBy: usersProvider.currentUser!.id,
                      shopId: currentShopId,
                    );

                    await expensesProvider.addExpenseHybrid(
                      expense,
                      usersProvider.currentUser!.id,
                      currentShopId,
                      Provider.of<BusinessProvider>(context, listen: false),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Restocked ${item.name}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.of(ctx).pop();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Restock'),
              ),
            ],
          ),
    );
  }

  void _showDamagedDialog(BuildContext context, InventoryItem item) {
    final _unitsController = TextEditingController();
    final _reasonController = TextEditingController();
    final businessProvider = Provider.of<BusinessProvider>(
      context,
      listen: false,
    );

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Mark ${item.name} as Damaged'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _unitsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Units damaged',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Reason (optional)',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final units = int.tryParse(_unitsController.text);
                  final reason = _reasonController.text.trim();
                  if (units == null || units <= 0 || units > item.quantity) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Enter valid units (max ${item.quantity})',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  try {
                    await Provider.of<InventoryProvider>(
                      context,
                      listen: false,
                    ).decreaseStockForDamagedGoods(item.id, units, reason);
                    await Provider.of<ExpensesProvider>(
                      context,
                      listen: false,
                    ).fetchAndSetExpensesHybrid(businessProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Marked ${units} as damaged'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    Navigator.of(ctx).pop();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Mark as Damaged'),
              ),
            ],
          ),
    );
  }

  void _showLowStockItemsDialog(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(
      context,
      listen: false,
    );
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);

    // Collect all low stock items
    List<Map<String, dynamic>> lowStockItems = [];

    for (final item in inventoryProvider.items) {
      if (item.quantity <= item.lowStockThreshold) {
        final shop = shopProvider.shops.firstWhere(
          (s) => s.id == item.shopId,
          orElse: () => shopProvider.shops.first,
        );

        lowStockItems.add({'item': item, 'shop': shop});
      }
    }

    // Sort by quantity (lowest first)
    lowStockItems.sort(
      (a, b) => a['item'].quantity.compareTo(b['item'].quantity),
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
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.inventory_2,
                          color: Colors.orange.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Low Stock Items',
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
                  ),

                  // Content
                  Expanded(
                    child:
                        lowStockItems.isEmpty
                            ? const Center(
                              child: Text('No low stock items found.'),
                            )
                            : ListView.builder(
                              itemCount: lowStockItems.length,
                              itemBuilder: (context, index) {
                                final data = lowStockItems[index];
                                final item = data['item'] as InventoryItem;
                                final shop = data['shop'] as Shop;

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.warning,
                                      color: Colors.orange.shade700,
                                    ),
                                    title: Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Shop: ${shop.name}'),
                                        Text(
                                          'Current Stock: ${item.quantity} units',
                                          style: TextStyle(
                                            color: Colors.orange.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Low Stock Threshold: ${item.lowStockThreshold} units',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          'Price: K${item.price.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.add),
                                      tooltip: 'Restock',
                                      onPressed: () {
                                        Navigator.of(ctx).pop();
                                        _showRestockDialog(context, item);
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),

                  // Summary
                  if (lowStockItems.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Low Stock Items: ${lowStockItems.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Total Value: K${_calculateTotalLowStockValue(lowStockItems).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
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

  void _showAllDamagedGoodsDialog(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(
      context,
      listen: false,
    );
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);

    // Collect all damaged records from all items
    List<Map<String, dynamic>> allDamagedRecords = [];

    for (final item in inventoryProvider.items) {
      for (final record in item.damagedRecords) {
        final shop = shopProvider.shops.firstWhere(
          (s) => s.id == item.shopId,
          orElse: () => shopProvider.shops.first,
        );

        allDamagedRecords.add({'item': item, 'record': record, 'shop': shop});
      }
    }

    // Sort by date (most recent first)
    allDamagedRecords.sort(
      (a, b) => b['record'].date.compareTo(a['record'].date),
    );

    // Reason analysis
    Map<String, int> reasonCounts = {};
    for (final data in allDamagedRecords) {
      final reason =
          data['record'].reason.trim().isEmpty
              ? '(No reason)'
              : data['record'].reason.trim();
      reasonCounts[reason] =
          (reasonCounts[reason] ?? 0) + (data['record'].units as int);
    }
    final sortedReasons =
        reasonCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // Item analysis
    Map<String, int> itemTotals = {};
    for (final data in allDamagedRecords) {
      final itemName = data['item'].name;
      itemTotals[itemName] =
          (itemTotals[itemName] ?? 0) + (data['record'].units as int);
    }

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                child: SingleChildScrollView(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    constraints: BoxConstraints(
                      maxWidth: 900,
                      maxHeight: MediaQuery.of(context).size.height * 0.9,
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.amber.shade700,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Damaged Goods',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${allDamagedRecords.length} records • ${allDamagedRecords.fold(0, (sum, data) => sum + (data['record'].units as int))} units • K${_calculateTotalDamagedValue(allDamagedRecords).toStringAsFixed(2)} value',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                        ),

                        // Analytics Summary
                        if (allDamagedRecords.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Analytics Summary',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildAnalyticsCard(
                                        'Total Records',
                                        '${allDamagedRecords.length}',
                                        Icons.list,
                                        Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildAnalyticsCard(
                                        'Total Units',
                                        '${allDamagedRecords.fold(0, (sum, data) => sum + (data['record'].units as int))}',
                                        Icons.inventory,
                                        Colors.orange,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildAnalyticsCard(
                                        'Total Value',
                                        'K${_calculateTotalDamagedValue(allDamagedRecords).toStringAsFixed(2)}',
                                        Icons.attach_money,
                                        Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                if (sortedReasons.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    'Top Reasons:',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    children:
                                        sortedReasons
                                            .take(3)
                                            .map(
                                              (e) => Chip(
                                                label: Text(
                                                  '${e.key}: ${e.value} units',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                  ),
                                                ),
                                                backgroundColor:
                                                    Colors.orange.shade100,
                                              ),
                                            )
                                            .toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),

                        // Content
                        Expanded(
                          child:
                              allDamagedRecords.isEmpty
                                  ? const Center(
                                    child: Text(
                                      'No damaged goods records found for the selected filters.',
                                    ),
                                  )
                                  : ListView.builder(
                                    itemCount: allDamagedRecords.length,
                                    itemBuilder: (context, index) {
                                      final data = allDamagedRecords[index];
                                      final item =
                                          data['item'] as InventoryItem;
                                      final record =
                                          data['record'] as DamagedRecord;
                                      final shop = data['shop'] as Shop;

                                      return Card(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 4,
                                        ),
                                        child: ListTile(
                                          leading: Icon(
                                            Icons.warning,
                                            color: Colors.orange.shade700,
                                          ),
                                          title: Text(
                                            '${item.name} - ${record.units} units',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (record.reason.isNotEmpty)
                                                Text(
                                                  'Reason: ${record.reason}',
                                                ),
                                              Text('Shop: ${shop.name}'),
                                              Text(
                                                'Date: ${DateFormat('MMM dd, yyyy HH:mm').format(record.date)}',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Text(
                                                'Value: K${(record.units * item.price).toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  color: Colors.red.shade700,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                        ),

                        // Footer with export
                        if (allDamagedRecords.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Showing ${allDamagedRecords.length} records',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed:
                                      () => _exportDamagedGoodsCSV(
                                        allDamagedRecords,
                                      ),
                                  icon: const Icon(Icons.download, size: 16),
                                  label: const Text('Export CSV'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
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
              );
            },
          ),
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportDamagedGoodsCSV(
    List<Map<String, dynamic>> records,
  ) async {
    try {
      final csv = StringBuffer('Item,Shop,Units,Reason,Date,Value\n');
      for (final data in records) {
        final item = data['item'] as InventoryItem;
        final record = data['record'] as DamagedRecord;
        final shop = data['shop'] as Shop;

        csv.writeln(
          '"${item.name}","${shop.name}","${record.units}","${record.reason.replaceAll('"', '""')}","${DateFormat('yyyy-MM-dd HH:mm').format(record.date)}","${(record.units * item.price).toStringAsFixed(2)}"',
        );
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/damaged_goods_report.csv');
      await file.writeAsString(csv.toString());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Damaged goods report exported to ${file.path}'),
            action: SnackBarAction(
              label: 'Share',
              onPressed: () async {
                await Share.shareXFiles([
                  XFile(file.path),
                ], text: 'Damaged Goods Report');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error exporting report: $e')));
      }
    }
  }

  double _calculateTotalDamagedValue(
    List<Map<String, dynamic>> damagedRecords,
  ) {
    return damagedRecords.fold(0.0, (sum, data) {
      final item = data['item'] as InventoryItem;
      final record = data['record'] as DamagedRecord;
      return sum + (record.units * item.price);
    });
  }

  double _calculateTotalLowStockValue(
    List<Map<String, dynamic>> lowStockItems,
  ) {
    return lowStockItems.fold(0.0, (sum, data) {
      final item = data['item'] as InventoryItem;
      return sum + (item.quantity * item.price);
    });
  }

  Future<void> _connectBluetoothScanner() async {
    setState(() {
      _isUsbConnecting = true;
    });
    List<BluetoothDevice> devices = [];
    try {
      devices = await FlutterBluePlus.connectedDevices;
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
      await Future.delayed(const Duration(seconds: 4));
      await FlutterBluePlus.stopScan();
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
        _isUsbConnecting = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Bluetooth scan failed: $e')));
      return;
    }
    setState(() {
      _isUsbConnecting = false;
    });
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
        // Optionally store the connected device
      });
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

  void _onInventoryAdded(InventoryItem item) {
    AnalyticsService.logEvent('inventory_added', data: {'item': item.name, 'quantity': item.quantity});
  }
  void _onInventoryUpdated(InventoryItem item) {
    AnalyticsService.logEvent('inventory_updated', data: {'item': item.name, 'quantity': item.quantity});
  }
  void _onInventoryDeleted(String itemId) {
    AnalyticsService.logEvent('inventory_deleted', data: {'itemId': itemId});
  }
  void _openNewInventoryModal() {
    AnalyticsService.logEvent('open_new_inventory_modal');
  }
}
