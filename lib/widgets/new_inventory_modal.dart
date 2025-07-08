import 'package:flutter/material.dart';
import 'package:kantemba_finances/providers/business_provider.dart';
import 'package:kantemba_finances/providers/shop_provider.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/models/inventory_item.dart';
import 'package:kantemba_finances/models/expense.dart';
import 'package:kantemba_finances/providers/inventory_provider.dart';
import 'package:kantemba_finances/providers/expenses_provider.dart';
import 'package:kantemba_finances/providers/users_provider.dart';

class NewInventoryModal extends StatefulWidget {
  const NewInventoryModal({super.key});

  @override
  State<NewInventoryModal> createState() => _NewInventoryModalState();
}

class _NewInventoryModalState extends State<NewInventoryModal> {
  final _formKey = GlobalKey<FormState>();
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
  Widget build(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final existingItems = inventoryProvider.items;
    final itemNames = existingItems.map((e) => e.name).toList();

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
                    controller.text = _itemName;
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(labelText: 'Item Name'),
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Enter item name'
                                  : null,
                      onChanged: (value) {
                        setState(() {
                          _itemName = value;
                          _isExistingItem = itemNames.contains(value);
                          if (_isExistingItem) {
                            final item = existingItems.firstWhere(
                              (e) => e.name == value,
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
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Enter bulk price';
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed <= 0)
                      return 'Enter a valid price';
                    return null;
                  },
                  onSaved: (value) => _bulkPrice = double.parse(value!),
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Number of Units',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Enter number of units';
                    final parsed = int.tryParse(value);
                    if (parsed == null || parsed <= 0)
                      return 'Enter a valid number';
                    return null;
                  },
                  onSaved: (value) => _units = int.parse(value!),
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Unit Sale Price',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Enter unit price';
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed <= 0)
                      return 'Enter a valid price';
                    return null;
                  },
                  onSaved: (value) => _unitPrice = double.parse(value!),
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Low Stock Threshold (optional)',
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

    final usersProvider = Provider.of<UsersProvider>(context, listen: false);
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    final currentUser = usersProvider.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No user is logged in!')));
      setState(() {
        _isLoading = false;
      });
      return;
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No shop is selected!')));
      setState(() {
        _isLoading = false;
      });
      return;
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
        id: '', // Will be set by provider
        name: _itemName,
        price: _unitPrice,
        quantity: _units,
        lowStockThreshold: _lowStockThreshold,
        shopId: currentShop.id,
        createdBy: currentUser.id,
      );
      await inventoryProvider.addInventoryItemHybrid(
        newItem,
        currentUser.id,
        currentShop.id,
        Provider.of<BusinessProvider>(context, listen: false),
      );
    }

    // Add bulk purchase as expense
    final expense = Expense(
      id: '', // Will be set by provider
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
    Navigator.of(context).pop();
  }
}
