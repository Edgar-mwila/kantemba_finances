import 'package:flutter/material.dart';
import 'package:kantemba_finances/providers/business_provider.dart';
import 'package:kantemba_finances/providers/shop_provider.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/models/expense.dart';
import 'package:kantemba_finances/providers/expenses_provider.dart';
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

  @override
  Widget build(BuildContext context) {
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
                        'Add Expense',
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
                                if (value == null || value.isEmpty)
                                  return 'Enter amount';
                                final parsed = double.tryParse(value);
                                if (parsed == null || parsed <= 0)
                                  return 'Enter a valid amount';
                                return null;
                              },
                              onSaved: (value) {
                                _amount = double.parse(value!);
                              },
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
                              title: GestureDetector(
                                onTap: () async {
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
                                child: Row(
                                  children: [
                                    Text(
                                      'Date: ${_date.toLocal().toString().split(' ')[0]}',
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.calendar_today, size: 20),
                                  ],
                                ),
                              ),
                              trailing: null,
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
                    if (value == null || value.isEmpty) return 'Enter amount';
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed <= 0)
                      return 'Enter a valid amount';
                    return null;
                  },
                  onSaved: (value) {
                    _amount = double.parse(value!);
                  },
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Category'),
                  value: _category,
                  items:
                      <String>[
                            'Uncategorized',
                            'Utilities',
                            'Rent',
                            'Salaries',
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
                    });
                  },
                ),
                ListTile(
                  title: GestureDetector(
                    onTap: () async {
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
                    child: Row(
                      children: [
                        Text(
                          'Date: ${_date.toLocal().toString().split(' ')[0]}',
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.calendar_today, size: 20),
                      ],
                    ),
                  ),
                  trailing: null,
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

    try {
      final usersProvider = Provider.of<UsersProvider>(context, listen: false);
      final shopProvider = Provider.of<ShopProvider>(context, listen: false);
      final currentUser = usersProvider.currentUser;
      if (currentUser == null) {
        throw Exception('No user is logged in!');
      }

      final expensesProvider = Provider.of<ExpensesProvider>(
        context,
        listen: false,
      );

      final currentShop = shopProvider.currentShop;
      if (currentShop == null) {
        throw Exception('No shop is selected!');
      }

      final expense = Expense(
        id:
            '${currentShop.name.replaceAll(' ', '_')}_expense_${DateTime.now().millisecondsSinceEpoch}', // Will be set by provider
        description: _description,
        amount: _amount,
        date: _date,
        category: _category,
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
            content: Text('Expense added!'),
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
            content: Text('Failed to add expense: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
