import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/models/return.dart';
import 'package:kantemba_finances/models/shop.dart';
import 'package:kantemba_finances/providers/returns_provider.dart';
import 'package:kantemba_finances/providers/shop_provider.dart';
import 'package:kantemba_finances/providers/users_provider.dart';

class ReturnsScreen extends StatelessWidget {
  const ReturnsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final returnsData = Provider.of<ReturnsProvider>(context);
    final userProvider = Provider.of<UsersProvider>(context);
    final user = userProvider.currentUser;

    return Consumer<ShopProvider>(
      builder: (context, shopProvider, child) {
        // Use filtered returns based on current shop
        final returns = returnsData.getReturnsForShop(shopProvider.currentShop);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Returns'),
            actions: [
              // Add shop filter if user is admin or manager
              if (user?.role == 'admin' || user?.role == 'manager')
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Filter by Shop'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: const Text('All Shops'),
                              leading: Radio<String?>(
                                value: null,
                                groupValue: shopProvider.currentShop?.id,
                                onChanged: (value) {
                                  shopProvider.setCurrentShop(null);
                                  Navigator.of(context).pop();
                                },
                              ),
                            ),
                            ...shopProvider.shops.map((shop) => ListTile(
                              title: Text(shop.name),
                              leading: Radio<String?>(
                                value: shop.id,
                                groupValue: shopProvider.currentShop?.id,
                                onChanged: (value) {
                                  shopProvider.setCurrentShop(shop);
                                  Navigator.of(context).pop();
                                },
                              ),
                            )),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
          body: Column(
            children: [
              // Show current filter status
              if (shopProvider.currentShop != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.blue.shade50,
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Filtered by: ${shopProvider.currentShop!.name}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => shopProvider.setCurrentShop(null),
                        child: const Text('Clear', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: returns.isEmpty
                    ? const Center(
                        child: Text('No returns found'),
                      )
                    : ListView.builder(
                        itemCount: returns.length,
                        itemBuilder: (ctx, i) {
                          final returnItem = returns[i];
                          final shop = shopProvider.shops.firstWhere(
                            (s) => s.id == returnItem.shopId,
                            orElse: () => Shop(
                              id: returnItem.shopId,
                              name: 'Unknown Shop',
                              businessId: '',
                            ),
                          );

                          Color statusColor;
                          IconData statusIcon;
                          switch (returnItem.status) {
                            case 'pending':
                              statusColor = Colors.orange;
                              statusIcon = Icons.pending;
                              break;
                            case 'approved':
                              statusColor = Colors.green;
                              statusIcon = Icons.check_circle;
                              break;
                            case 'rejected':
                              statusColor = Colors.red;
                              statusIcon = Icons.cancel;
                              break;
                            case 'completed':
                              statusColor = Colors.blue;
                              statusIcon = Icons.done_all;
                              break;
                            default:
                              statusColor = Colors.grey;
                              statusIcon = Icons.help;
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              title: Text('Return ID: ${returnItem.id}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(returnItem.date.toIso8601String()),
                                  Text(
                                    'Shop: ${shop.name}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    'Original Sale: ${returnItem.originalSaleId}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    'Reason: ${returnItem.reason}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(statusIcon, 
                                        color: statusColor, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        returnItem.status.toUpperCase(),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'K${returnItem.grandReturnAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${returnItem.items.length} items',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                _showReturnDetails(context, returnItem, shop);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReturnDetails(BuildContext context, Return returnItem, Shop shop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
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
                    'Return Details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Return ID: ${returnItem.id}'),
              Text('Original Sale: ${returnItem.originalSaleId}'),
              Text('Shop: ${shop.name}'),
              Text('Date: ${returnItem.date.toIso8601String()}'),
              Text('Reason: ${returnItem.reason}'),
              const SizedBox(height: 16),
              
              // Status
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(returnItem.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(_getStatusIcon(returnItem.status), 
                      color: _getStatusColor(returnItem.status)),
                    const SizedBox(width: 8),
                    Text(
                      'Status: ${returnItem.status.toUpperCase()}',
                      style: TextStyle(
                        color: _getStatusColor(returnItem.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Items
              Text(
                'Returned Items:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: returnItem.items.length,
                  itemBuilder: (context, index) {
                    final item = returnItem.items[index];
                    return Card(
                      child: ListTile(
                        title: Text(item.product.name),
                        subtitle: Text('Reason: ${item.reason}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${item.quantity} x K${item.originalPrice.toStringAsFixed(2)}'),
                            Text(
                              '= K${item.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
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
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:'),
                        Text('K${returnItem.totalReturnAmount.toStringAsFixed(2)}'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('VAT:'),
                        Text('K${returnItem.vat.toStringAsFixed(2)}'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Turnover Tax:'),
                        Text('K${returnItem.turnoverTax.toStringAsFixed(2)}'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Levy:'),
                        Text('K${returnItem.levy.toStringAsFixed(2)}'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Return:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'K${returnItem.grandReturnAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Action buttons for pending returns
              if (returnItem.status == 'pending' && 
                  (Provider.of<UsersProvider>(context, listen: false).currentUser?.role == 'admin' ||
                   Provider.of<UsersProvider>(context, listen: false).currentUser?.role == 'manager'))
                ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _approveReturn(context, returnItem),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Approve'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _rejectReturn(context, returnItem),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                    ],
                  ),
                ],
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.help;
    }
  }

  Future<void> _approveReturn(BuildContext context, Return returnItem) async {
    try {
      final returnsProvider = Provider.of<ReturnsProvider>(context, listen: false);
      final userProvider = Provider.of<UsersProvider>(context, listen: false);
      final currentUser = userProvider.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await returnsProvider.approveReturn(returnItem.id, currentUser.id);
      
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Return approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving return: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectReturn(BuildContext context, Return returnItem) async {
    final reasonController = TextEditingController();
    
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Return'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Rejection Reason',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(reasonController.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (reason != null && reason.trim().isNotEmpty) {
      try {
        final returnsProvider = Provider.of<ReturnsProvider>(context, listen: false);
        final userProvider = Provider.of<UsersProvider>(context, listen: false);
        final currentUser = userProvider.currentUser;

        if (currentUser == null) {
          throw Exception('User not authenticated');
        }

        await returnsProvider.rejectReturn(returnItem.id, currentUser.id, reason.trim());
        
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Return rejected successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error rejecting return: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
} 