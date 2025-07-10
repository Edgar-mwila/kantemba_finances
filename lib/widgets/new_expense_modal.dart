import 'package:flutter/material.dart';
import 'package:kantemba_finances/providers/business_provider.dart';
import 'package:kantemba_finances/providers/shop_provider.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/models/expense.dart';
import 'package:kantemba_finances/providers/expenses_provider.dart';
import 'package:kantemba_finances/providers/inventory_provider.dart';
import 'package:kantemba_finances/providers/users_provider.dart';
import 'package:kantemba_finances/helpers/platform_helper.dart';

class NewExpenseModal extends StatefulWidget {
  const NewExpenseModal({super.key});

  @override
  State<NewExpenseModal> createState() => _NewExpenseModalState();
}

class _NewExpenseModalState extends State<NewExpenseModal> {
  final _formKey = GlobalKey<FormState>();
  String _description = '';
  double _amount = 0.0;
  DateTime _date = DateTime.now();
  String _category = 'Uncategorized';
  bool _isLoading = false;
  bool _isGoodsDamaged = false;
  String? _selectedItemId;
  int _damagedUnits = 0;
  double _unitPrice = 0.0;

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final items = inventoryProvider.items;
    // final itemNames = items.map((e) => e.name).toList();

    if (isWindows) {
      // Desktop layout: Centered, max width, more padding, two-column form
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Expense',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Description',
                              ),
                              validator:
                                  (value) =>
                                      value == null || value.isEmpty
                                          ? 'Enter description'
                                          : null,
                              onSaved: (value) => _description = value!.trim(),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Amount',
                              ),
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: (value) {
                                if (_isGoodsDamaged)
                                  return null; // calculated automatically
                                if (value == null || value.isEmpty)
                                  return 'Enter amount';
                                final parsed = double.tryParse(value);
                                if (parsed == null || parsed <= 0)
                                  return 'Enter a valid amount';
                                return null;
                              },
                              onSaved: (value) {
                                if (!_isGoodsDamaged)
                                  _amount = double.parse(value!);
                              },
                              enabled: !_isGoodsDamaged,
                              initialValue: !_isGoodsDamaged ? '' : null,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Category',
                              ),
                              value: _category,
                              items:
                                  <String>[
                                        'Uncategorized',
                                        'Utilities',
                                        'Rent',
                                        'Salaries',
                                        'Goods Damaged',
                                        'Other',
                                      ]
                                      .map(
                                        (cat) => DropdownMenuItem<String>(
                                          value: cat,
                                          child: Text(cat),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (val) {
                                setState(() {
                                  _category = val ?? 'Uncategorized';
                                  if (_category == 'Goods Damaged')
                                    _isGoodsDamaged = true;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        child: Column(
                          children: [
                            ListTile(
                              title: const Text('Goods Damaged'),
                              leading: Checkbox(
                                value: _isGoodsDamaged,
                                onChanged: (val) {
                                  setState(() {
                                    _isGoodsDamaged = val ?? false;
                                    if (!_isGoodsDamaged) {
                                      _selectedItemId = null;
                                      _damagedUnits = 0;
                                      _unitPrice = 0.0;
                                    }
                                  });
                                },
                              ),
                            ),
                            if (_isGoodsDamaged) ...[
                              DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Select Item',
                                ),
                                items:
                                    items.map((item) {
                                      return DropdownMenuItem<String>(
                                        value: item.id,
                                        child: Text(item.name),
                                      );
                                    }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedItemId = val;
                                    final item = items.firstWhere(
                                      (e) => e.id == val,
                                    );
                                    _unitPrice = item.price;
                                  });
                                },
                                validator:
                                    (val) => val == null ? 'Select item' : null,
                              ),
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Number of Damaged Units',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (!_isGoodsDamaged) return null;
                                  if (value == null || value.isEmpty)
                                    return 'Enter number of units';
                                  final parsed = int.tryParse(value);
                                  if (parsed == null || parsed <= 0)
                                    return 'Enter a valid number';
                                  if (_selectedItemId != null) {
                                    final item = items.firstWhere(
                                      (e) => e.id == _selectedItemId,
                                    );
                                    if (parsed > item.quantity)
                                      return 'Not enough stock';
                                  }
                                  return null;
                                },
                                onSaved:
                                    (value) =>
                                        _damagedUnits = int.parse(value!),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Unit Price: K${_unitPrice.toStringAsFixed(2)}',
                                ),
                              ),
                            ],
                            ListTile(
                              title: Text(
                                'Date: ${_date.toLocal().toString().split(' ')[0]}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _date,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _date = picked;
                                    });
                                  }
                                },
                              ),
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
                          child: const Text('Add Expense'),
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
                  'Add Expense',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Enter description'
                              : null,
                  onSaved: (value) => _description = value!.trim(),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (_isGoodsDamaged)
                      return null; // calculated automatically
                    if (value == null || value.isEmpty) return 'Enter amount';
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed <= 0)
                      return 'Enter a valid amount';
                    return null;
                  },
                  onSaved: (value) {
                    if (!_isGoodsDamaged) _amount = double.parse(value!);
                  },
                  enabled: !_isGoodsDamaged,
                  initialValue: !_isGoodsDamaged ? '' : null,
                ),
                ListTile(
                  title: const Text('Goods Damaged'),
                  leading: Checkbox(
                    value: _isGoodsDamaged,
                    onChanged: (val) {
                      setState(() {
                        _isGoodsDamaged = val ?? false;
                        if (!_isGoodsDamaged) {
                          _selectedItemId = null;
                          _damagedUnits = 0;
                          _unitPrice = 0.0;
                        }
                      });
                    },
                  ),
                ),
                if (_isGoodsDamaged) ...[
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Select Item'),
                    items:
                        items.map((item) {
                          return DropdownMenuItem<String>(
                            value: item.id,
                            child: Text(item.name),
                          );
                        }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedItemId = val;
                        final item = items.firstWhere((e) => e.id == val);
                        _unitPrice = item.price;
                      });
                    },
                    validator: (val) => val == null ? 'Select item' : null,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Number of Damaged Units',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (!_isGoodsDamaged) return null;
                      if (value == null || value.isEmpty)
                        return 'Enter number of units';
                      final parsed = int.tryParse(value);
                      if (parsed == null || parsed <= 0)
                        return 'Enter a valid number';
                      if (_selectedItemId != null) {
                        final item = items.firstWhere(
                          (e) => e.id == _selectedItemId,
                        );
                        if (parsed > item.quantity) return 'Not enough stock';
                      }
                      return null;
                    },
                    onSaved: (value) => _damagedUnits = int.parse(value!),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Unit Price: K${_unitPrice.toStringAsFixed(2)}',
                    ),
                  ),
                ],
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Category'),
                  value: _category,
                  items:
                      <String>[
                            'Uncategorized',
                            'Utilities',
                            'Rent',
                            'Salaries',
                            'Goods Damaged',
                            'Other',
                          ]
                          .map(
                            (cat) => DropdownMenuItem<String>(
                              value: cat,
                              child: Text(cat),
                            ),
                          )
                          .toList(),
                  onChanged: (val) {
                    setState(() {
                      _category = val ?? 'Uncategorized';
                      if (_category == 'Goods Damaged') _isGoodsDamaged = true;
                    });
                  },
                ),
                ListTile(
                  title: Text(
                    'Date: ${_date.toLocal().toString().split(' ')[0]}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _date = picked;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Add Expense'),
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
    print(
      "currentUser: ${currentUser?.name}, shopProvider: ${shopProvider.currentShop?.name}",
    );
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No user is logged in!')));
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final expensesProvider = Provider.of<ExpensesProvider>(
      context,
      listen: false,
    );
    final inventoryProvider = Provider.of<InventoryProvider>(
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

    if (_isGoodsDamaged && _selectedItemId != null) {
      // Calculate amount and update inventory
      final item = inventoryProvider.items.firstWhere(
        (e) => e.id == _selectedItemId,
      );
      _amount = item.price * _damagedUnits;
      await inventoryProvider.decreaseStockForDamagedGoods(
        _selectedItemId!,
        _damagedUnits,
      );
    }

    final expense = Expense(
      id: '', // Will be set by provider
      description: _description,
      amount: _amount,
      date: _date,
      category: _isGoodsDamaged ? 'Goods Damaged' : _category,
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
