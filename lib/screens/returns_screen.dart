import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/models/return.dart';
import 'package:kantemba_finances/models/shop.dart';
import 'package:kantemba_finances/providers/returns_provider.dart';
import 'package:kantemba_finances/providers/shop_provider.dart';
import 'package:kantemba_finances/helpers/platform_helper.dart';

class ReturnsScreen extends StatelessWidget {
  const ReturnsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final returnsData = Provider.of<ReturnsProvider>(context);

    return Consumer<ShopProvider>(
      builder: (context, shopProvider, child) {
        // Use filtered returns based on current shop
        final returns = returnsData.getReturnsForShop(shopProvider.currentShop);

        if (isWindows) {
          // Desktop layout: Centered, max width, table-like returns list, dialogs for details
          return Scaffold(
            appBar: AppBar(title: const Text('Returns')),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
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
                                'Return ID',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Date',
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
                                'Status',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Total',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 0),
                      Expanded(
                        child:
                            returns.isEmpty
                                ? const Center(child: Text('No returns found'))
                                : ListView.builder(
                                  itemCount: returns.length,
                                  itemBuilder: (ctx, i) {
                                    final returnItem = returns[i];
                                    final shop = shopProvider.shops.firstWhere(
                                      (s) => s.id == returnItem.shopId,
                                      orElse: () => shopProvider.shops.first,
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
                                    return InkWell(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) {
                                            return Dialog(
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  24.0,
                                                ),
                                                child: SingleChildScrollView(
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            'Return Details',
                                                            style:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .textTheme
                                                                    .titleLarge,
                                                          ),
                                                          IconButton(
                                                            onPressed:
                                                                () =>
                                                                    Navigator.of(
                                                                      context,
                                                                    ).pop(),
                                                            icon: const Icon(
                                                              Icons.close,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                        height: 16,
                                                      ),
                                                      Text(
                                                        'Return ID: ${returnItem.id}',
                                                      ),
                                                      Text(
                                                        'Original Sale: ${returnItem.originalSaleId}',
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                      Text(
                                                        'Shop: ${shop.name}',
                                                      ),
                                                      Text(
                                                        'Date: ${DateFormat('yyyy-MM-dd - kk:mm').format(returnItem.date)}',
                                                      ),
                                                      Text(
                                                        'Reason: ${returnItem.reason}',
                                                      ),
                                                      const SizedBox(
                                                        height: 16,
                                                      ),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              8,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: statusColor
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              statusIcon,
                                                              color:
                                                                  statusColor,
                                                            ),
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            Text(
                                                              'Status: ${returnItem.status.toUpperCase()}',
                                                              style: TextStyle(
                                                                color:
                                                                    statusColor,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 16,
                                                      ),
                                                      Text(
                                                        'Returned Items:',
                                                        style:
                                                            Theme.of(context)
                                                                .textTheme
                                                                .titleMedium,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Container(
                                                        constraints:
                                                            const BoxConstraints(
                                                              maxHeight: 200,
                                                            ),
                                                        child: ListView.builder(
                                                          shrinkWrap: true,
                                                          itemCount:
                                                              returnItem
                                                                  .items
                                                                  .length,
                                                          itemBuilder: (
                                                            context,
                                                            index,
                                                          ) {
                                                            final item =
                                                                returnItem
                                                                    .items[index];
                                                            return Card(
                                                              child: ListTile(
                                                                title: Text(
                                                                  item
                                                                      .product
                                                                      .name,
                                                                ),
                                                                subtitle: Text(
                                                                  'Reason: ${item.reason}',
                                                                ),
                                                                trailing: Column(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Text(
                                                                      '${item.quantity} x K${item.originalPrice.toStringAsFixed(2)}',
                                                                    ),
                                                                    Text(
                                                                      '= K${item.totalAmount.toStringAsFixed(2)}',
                                                                      style: const TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 16,
                                                      ),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              16,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              Colors
                                                                  .grey
                                                                  .shade100,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: Column(
                                                          children: [
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                const Text(
                                                                  'Subtotal:',
                                                                ),
                                                                Text(
                                                                  'K${returnItem.totalReturnAmount.toStringAsFixed(2)}',
                                                                ),
                                                              ],
                                                            ),
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                const Text(
                                                                  'VAT:',
                                                                ),
                                                                Text(
                                                                  'K${returnItem.vat.toStringAsFixed(2)}',
                                                                ),
                                                              ],
                                                            ),
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                const Text(
                                                                  'Turnover Tax:',
                                                                ),
                                                                Text(
                                                                  'K${returnItem.turnoverTax.toStringAsFixed(2)}',
                                                                ),
                                                              ],
                                                            ),
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                const Text(
                                                                  'Levy:',
                                                                ),
                                                                Text(
                                                                  'K${returnItem.levy.toStringAsFixed(2)}',
                                                                ),
                                                              ],
                                                            ),
                                                            const Divider(),
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                const Text(
                                                                  'Total Return:',
                                                                  style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  'K${returnItem.grandReturnAmount.toStringAsFixed(2)}',
                                                                  style: const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                              ],
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
                                        );
                                      },
                                      child: Container(
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
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Text(returnItem.id),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                returnItem.date
                                                    .toIso8601String(),
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
                                                  Icon(
                                                    statusIcon,
                                                    color: statusColor,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    returnItem.status
                                                        .toUpperCase(),
                                                    style: TextStyle(
                                                      color: statusColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                'K${returnItem.grandReturnAmount.toStringAsFixed(2)}',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
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
        return Scaffold(
          appBar: AppBar(title: const Text('Returns')),
          body: Column(
            children: [
              // Show current filter status
              Expanded(
                child:
                    returns.isEmpty
                        ? const Center(child: Text('No returns found'))
                        : ListView.builder(
                          itemCount: returns.length,
                          itemBuilder: (ctx, i) {
                            final returnItem = returns[i];
                            final shop = shopProvider.shops.firstWhere(
                              (s) => s.id == returnItem.shopId,
                              orElse: () => shopProvider.shops.first,
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
                                    Text(
                                      DateFormat(
                                        'yyyy-MM-dd - kk:mm',
                                      ).format(returnItem.date),
                                    ),
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
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                                        Icon(
                                          statusIcon,
                                          color: statusColor,
                                          size: 16,
                                        ),
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
              Text(
                'Original Sale: ${returnItem.originalSaleId}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text('Shop: ${shop.name}'),
              Text(
                'Date: ${DateFormat('yyyy-MM-dd - kk:mm').format(returnItem.date)}',
              ),
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
                    Icon(
                      _getStatusIcon(returnItem.status),
                      color: _getStatusColor(returnItem.status),
                    ),
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
                            Text(
                              '${item.quantity} x K${item.originalPrice.toStringAsFixed(2)}',
                            ),
                            Text(
                              '= K${item.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
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
                        Text(
                          'K${returnItem.totalReturnAmount.toStringAsFixed(2)}',
                        ),
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
}
