import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/models/sale.dart';
import 'package:kantemba_finances/models/return.dart';
import 'package:kantemba_finances/providers/returns_provider.dart';
import 'package:kantemba_finances/providers/users_provider.dart';
import 'package:kantemba_finances/providers/business_provider.dart';

class ReturnModal extends StatefulWidget {
  final Sale sale;

  const ReturnModal({Key? key, required this.sale}) : super(key: key);

  @override
  State<ReturnModal> createState() => _ReturnModalState();
}

class _ReturnModalState extends State<ReturnModal> {
  final List<ReturnItem> _selectedItems = [];
  final TextEditingController _reasonController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _toggleItem(SaleItem saleItem) {
    setState(() {
      final existingIndex = _selectedItems.indexWhere(
        (item) => item.product.id == saleItem.product.id,
      );

      if (existingIndex != -1) {
        _selectedItems.removeAt(existingIndex);
      } else {
        _selectedItems.add(
          ReturnItem(
            product: saleItem.product,
            quantity: 1,
            originalPrice: saleItem.product.price,
            reason: '',
          ),
        );
      }
    });
  }

  void _updateQuantity(ReturnItem returnItem, int newQuantity) {
    if (newQuantity <= 0) return;

    final saleItem = widget.sale.items.firstWhere(
      (item) => item.product.id == returnItem.product.id,
    );

    if (newQuantity > saleItem.quantity) return;

    setState(() {
      final index = _selectedItems.indexWhere(
        (item) => item.product.id == returnItem.product.id,
      );
      if (index != -1) {
        _selectedItems[index] = ReturnItem(
          product: returnItem.product,
          quantity: newQuantity,
          originalPrice: returnItem.originalPrice,
          reason: returnItem.reason,
        );
      }
    });
  }

  void _updateItemReason(ReturnItem returnItem, String reason) {
    setState(() {
      final index = _selectedItems.indexWhere(
        (item) => item.product.id == returnItem.product.id,
      );
      if (index != -1) {
        _selectedItems[index] = ReturnItem(
          product: returnItem.product,
          quantity: returnItem.quantity,
          originalPrice: returnItem.originalPrice,
          reason: reason,
        );
      }
    });
  }

  double get _totalReturnAmount {
    return _selectedItems.fold(0.0, (sum, item) => sum + item.totalAmount);
  }

  Future<void> _processReturn() async {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select items to return')),
      );
      return;
    }

    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a reason for the return')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final returnsProvider = Provider.of<ReturnsProvider>(
        context,
        listen: false,
      );
      final userProvider = Provider.of<UsersProvider>(context, listen: false);
      final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
      final currentUser = userProvider.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final ret = Return(
        id: 'RET_${DateTime.now().millisecondsSinceEpoch}',
        originalSaleId: widget.sale.id,
        items: _selectedItems,
        totalReturnAmount: _totalReturnAmount,
        grandReturnAmount: 0, // Will be calculated in provider if needed
        vat: 0,
        turnoverTax: 0,
        levy: 0,
        date: DateTime.now(),
        shopId: widget.sale.shopId,
        createdBy: currentUser.id,
        reason: _reasonController.text.trim(),
        status: 'approved', // Always approved
      );

      await returnsProvider.addReturnHybrid(
        ret,
        businessProvider,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Return created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating return: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Return Items',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Sale ID: ${widget.sale.id}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          // Items selection
          Text(
            'Select Items to Return:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.sale.items.length,
              itemBuilder: (context, index) {
                final saleItem = widget.sale.items[index];
                final isSelected = _selectedItems.any(
                  (item) => item.product.id == saleItem.product.id,
                );
                final returnItem = _selectedItems.firstWhere(
                  (item) => item.product.id == saleItem.product.id,
                  orElse:
                      () => ReturnItem(
                        product: saleItem.product,
                        quantity: 0,
                        originalPrice: saleItem.product.price,
                        reason: '',
                      ),
                );

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        Checkbox(
                          value: isSelected,
                          onChanged: (value) => _toggleItem(saleItem),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                saleItem.product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Original Qty: ${saleItem.quantity}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'K${saleItem.product.price.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    children:
                        isSelected
                            ? [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Text('Return Quantity: '),
                                        Expanded(
                                          child: Row(
                                            children: [
                                              IconButton(
                                                onPressed:
                                                    () => _updateQuantity(
                                                      returnItem,
                                                      returnItem.quantity - 1,
                                                    ),
                                                icon: const Icon(Icons.remove),
                                              ),
                                              Text(
                                                '${returnItem.quantity}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              IconButton(
                                                onPressed:
                                                    () => _updateQuantity(
                                                      returnItem,
                                                      returnItem.quantity + 1,
                                                    ),
                                                icon: const Icon(Icons.add),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      decoration: const InputDecoration(
                                        labelText: 'Reason for this item',
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged:
                                          (value) => _updateItemReason(
                                            returnItem,
                                            value,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ]
                            : [],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // General reason
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'General Return Reason',
              border: OutlineInputBorder(),
              hintText: 'e.g., Customer changed mind, defective items',
            ),
            maxLines: 2,
          ),

          const SizedBox(height: 16),

          // Summary
          if (_selectedItems.isNotEmpty) ...[
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Return Summary',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Items to return: ${_selectedItems.length}'),
                    Text(
                      'Total return amount: K${_totalReturnAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _isProcessing ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      _isProcessing || _selectedItems.isEmpty
                          ? null
                          : _processReturn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child:
                      _isProcessing
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Process Return'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
