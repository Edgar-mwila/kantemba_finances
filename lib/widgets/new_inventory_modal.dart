import 'package:flutter/material.dart';
import 'package:kantemba_finances/providers/business_provider.dart';
import 'package:kantemba_finances/providers/shop_provider.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/models/inventory_item.dart';
import 'package:kantemba_finances/models/expense.dart';
import 'package:kantemba_finances/providers/inventory_provider.dart';
import 'package:kantemba_finances/providers/expenses_provider.dart';
import 'package:kantemba_finances/providers/users_provider.dart';
import 'package:kantemba_finances/helpers/platform_helper.dart';

class NewInventoryModal extends StatefulWidget {
  const NewInventoryModal({super.key});

  @override
  State<NewInventoryModal> createState() => _NewInventoryModalState();
}

class _NewInventoryModalState extends State<NewInventoryModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _itemNameController = TextEditingController();
  String _itemName = '';
  double _bulkPrice = 0.0;
  int _units = 0;
  double _unitPrice = 0.0;
  int _lowStockThreshold = 5;
  String _description = '';
  bool _isLoading = false;
  bool _isExistingItem = false;
  String? _selectedItemId;

  @override
  void dispose() {
    _itemNameController.dispose();
    super.dispose();
  }

  String? _validateItemName(String? value, List<String> itemNames) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter item name';
    }
    if (value.trim().length < 3) {
      return 'Item name must be at least 3 characters';
    }
    final lower = value.trim().toLowerCase();
    if (itemNames.where((name) => name.toLowerCase() == lower).isNotEmpty &&
        !_isExistingItem) {
      return 'Item name already exists';
    }
    return null;
  }

  String? _validateUnits(String? value) {
    if (value == null || value.isEmpty) return 'Enter number of units';
    final parsed = int.tryParse(value);
    if (parsed == null || parsed <= 0) return 'Enter a valid number';
    return null;
  }

  String? _validateUnitPrice(String? value) {
    if (value == null || value.isEmpty) return 'Enter unit price';
    final parsed = double.tryParse(value);
    if (parsed == null || parsed <= 0) return 'Enter a valid price';
    return null;
  }

  String? _validateBulkPrice(String? value) {
    if (value == null || value.isEmpty) return 'Enter bulk price';
    final parsed = double.tryParse(value);
    if (parsed == null || parsed <= 0) return 'Enter a valid price';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final existingItems = inventoryProvider.items;
    final itemNames = existingItems.map((e) => e.name).toList();

    if (isWindows(context)) {
      final screenHeight = MediaQuery.of(context).size.height;
      // Desktop layout: Centered, max width, more padding, two-column form
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 700,
            maxHeight: screenHeight * 0.8,
          ),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add Inventory Purchase',
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
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Autocomplete<String>(
                              optionsBuilder: (
                                TextEditingValue textEditingValue,
                              ) {
                                if (textEditingValue.text == '') {
                                  return const Iterable<String>.empty();
                                }
                                return itemNames.where((String option) {
                                  return option.toLowerCase().contains(
                                    textEditingValue.text.toLowerCase(),
                                  );
                                });
                              },
                              onSelected: (String selection) {
                                setState(() {
                                  _itemName = selection;
                                  _itemNameController.text = selection;
                                  _isExistingItem = true;
                                  final item = existingItems.firstWhere(
                                    (e) => e.name == selection,
                                  );
                                  _selectedItemId = item.id;
                                  _lowStockThreshold = item.lowStockThreshold;
                                });
                              },
                              fieldViewBuilder: (
                                context,
                                controller,
                                focusNode,
                                onEditingComplete,
                              ) {
                                // Use the persistent controller
                                return TextFormField(
                                  controller: _itemNameController,
                                  focusNode: focusNode,
                                  decoration: const InputDecoration(
                                    labelText: 'Item Name',
                                  ),
                                  validator:
                                      (value) =>
                                          _validateItemName(value, itemNames),
                                  onChanged: (value) {
                                    setState(() {
                                      _itemName = value;
                                      _isExistingItem = itemNames.any(
                                        (name) =>
                                            name.toLowerCase() ==
                                            value.toLowerCase(),
                                      );
                                      if (_isExistingItem) {
                                        final item = existingItems.firstWhere(
                                          (e) =>
                                              e.name.toLowerCase() ==
                                              value.toLowerCase(),
                                        );
                                        _selectedItemId = item.id;
                                        _lowStockThreshold =
                                            item.lowStockThreshold;
                                      } else {
                                        _selectedItemId = null;
                                      }
                                    });
                                  },
                                  onSaved: (value) => _itemName = value!.trim(),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Bulk Price (total purchase)',
                              ),
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: _validateBulkPrice,
                              onSaved:
                                  (value) => _bulkPrice = double.parse(value!),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Number of Units',
                              ),
                              keyboardType: TextInputType.number,
                              validator: _validateUnits,
                              onSaved: (value) => _units = int.parse(value!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        child: Column(
                          children: [
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Unit Sale Price',
                              ),
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: _validateUnitPrice,
                              onSaved:
                                  (value) => _unitPrice = double.parse(value!),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Low Stock Threshold (optional)',
                                helperText:
                                    _isExistingItem
                                        ? 'Cannot edit threshold for existing items'
                                        : null,
                              ),
                              keyboardType: TextInputType.number,
                              initialValue: _lowStockThreshold.toString(),
                              onSaved: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final parsed = int.tryParse(value);
                                  if (parsed != null && parsed > 0)
                                    _lowStockThreshold = parsed;
                                }
                              },
                              enabled:
                                  !_isExistingItem, // Only editable for new items
                              readOnly: _isExistingItem,
                              style:
                                  _isExistingItem
                                      ? TextStyle(color: Colors.grey)
                                      : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Description (optional)',
                              ),
                              onSaved:
                                  (value) => _description = value?.trim() ?? '',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submit,
                          child: const Text('Add Item'),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Mobile layout (unchanged)
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add Inventory Purchase',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return const Iterable<String>.empty();
                    }
                    return itemNames.where((String option) {
                      return option.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      );
                    });
                  },
                  onSelected: (String selection) {
                    setState(() {
                      _itemName = selection;
                      _itemNameController.text = selection;
                      _isExistingItem = true;
                      final item = existingItems.firstWhere(
                        (e) => e.name == selection,
                      );
                      _selectedItemId = item.id;
                      _lowStockThreshold = item.lowStockThreshold;
                    });
                  },
                  fieldViewBuilder: (
                    context,
                    controller,
                    focusNode,
                    onEditingComplete,
                  ) {
                    // Use the persistent controller
                    return TextFormField(
                      controller: _itemNameController,
                      focusNode: focusNode,
                      decoration: const InputDecoration(labelText: 'Item Name'),
                      validator: (value) => _validateItemName(value, itemNames),
                      onChanged: (value) {
                        setState(() {
                          _itemName = value;
                          _isExistingItem = itemNames.any(
                            (name) => name.toLowerCase() == value.toLowerCase(),
                          );
                          if (_isExistingItem) {
                            final item = existingItems.firstWhere(
                              (e) =>
                                  e.name.toLowerCase() == value.toLowerCase(),
                            );
                            _selectedItemId = item.id;
                            _lowStockThreshold = item.lowStockThreshold;
                          } else {
                            _selectedItemId = null;
                          }
                        });
                      },
                      onSaved: (value) => _itemName = value!.trim(),
                    );
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Bulk Price (total purchase)',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: _validateBulkPrice,
                  onSaved: (value) => _bulkPrice = double.parse(value!),
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Number of Units',
                  ),
                  keyboardType: TextInputType.number,
                  validator: _validateUnits,
                  onSaved: (value) => _units = int.parse(value!),
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Unit Sale Price',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: _validateUnitPrice,
                  onSaved: (value) => _unitPrice = double.parse(value!),
                ),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Low Stock Threshold (optional)',
                    helperText:
                        _isExistingItem
                            ? 'Cannot edit threshold for existing items'
                            : null,
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: _lowStockThreshold.toString(),
                  onSaved: (value) {
                    if (value != null && value.isNotEmpty) {
                      final parsed = int.tryParse(value);
                      if (parsed != null && parsed > 0)
                        _lowStockThreshold = parsed;
                    }
                  },
                  enabled: !_isExistingItem, // Only editable for new items
                  readOnly: _isExistingItem,
                  style: _isExistingItem ? TextStyle(color: Colors.grey) : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                  onSaved: (value) => _description = value?.trim() ?? '',
                ),
                const SizedBox(height: 16),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Add Item'),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
    });

    try {
      final usersProvider = Provider.of<UsersProvider>(context, listen: false);
      final shopProvider = Provider.of<ShopProvider>(context, listen: false);

      // Ensure user session is available
      if (usersProvider.currentUser == null) {
        // Try to wait for initialization
        if (!usersProvider.isInitialized) {
          debugPrint('User provider not initialized, waiting...');
          int attempts = 0;
          while (!usersProvider.isInitialized && attempts < 10) {
            await Future.delayed(const Duration(milliseconds: 100));
            attempts++;
          }
        }

        if (usersProvider.currentUser == null) {
          throw Exception('No user is logged in! Please log in again.');
        }
      }

      final currentUser = usersProvider.currentUser!;
      debugPrint('Current user: ${currentUser.name} (${currentUser.id})');

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

      if (_isExistingItem && _selectedItemId != null) {
        // Update stock and price for existing item
        await inventoryProvider.increaseStockAndUpdatePrice(
          _selectedItemId!,
          _units,
          _unitPrice,
        );
      } else {
        // Add new inventory item
        final newItem = InventoryItem(
          id:
              '${currentShop.name.replaceAll(' ', '_')}_inventory_${DateTime.now().millisecondsSinceEpoch}', // Will be set by provider
          name: _itemName,
          price: _unitPrice,
          quantity: _units,
          lowStockThreshold: _lowStockThreshold,
          shopId: currentShop.id,
          createdBy: currentUser.id,
        );
        await inventoryProvider.addInventoryItem(
          newItem,
          currentUser.id,
          currentShop.id,
        );
      }

      // Add bulk purchase as expense
      final expense = Expense(
        id:
            '${currentShop.name.replaceAll(' ', '_')}_expense_${DateTime.now().millisecondsSinceEpoch}', // Will be set by provider
        description:
            'Bulk purchase: $_itemName${_description.isNotEmpty ? ' - $_description' : ''}',
        amount: _bulkPrice,
        date: DateTime.now(),
        category: 'Purchases',
        shopId: currentShop.id,
        createdBy: currentUser.id,
      );
      await expensesProvider.addExpenseHybrid(
        expense,
        currentUser.id,
        currentShop.id,
        Provider.of<BusinessProvider>(context, listen: false),
      );

      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inventory updated!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update inventory: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
