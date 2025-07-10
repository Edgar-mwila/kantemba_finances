import 'package:flutter/material.dart';
import 'package:kantemba_finances/models/shop.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/providers/sales_provider.dart';
import 'package:kantemba_finances/widgets/new_sale_modal.dart';
import 'package:kantemba_finances/widgets/return_modal.dart';
import '../providers/shop_provider.dart';
import '../providers/users_provider.dart';
import '../providers/returns_provider.dart';
import 'package:kantemba_finances/helpers/platform_helper.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final salesData = Provider.of<SalesProvider>(context);
    final userProvider = Provider.of<UsersProvider>(context);
    final user = userProvider.currentUser;

    return Consumer<ShopProvider>(
      builder: (context, shopProvider, child) {
        // Use filtered sales based on current shop
        final sales = salesData.getSalesForShop(shopProvider.currentShop);

        if (isWindows) {
          // Desktop layout: Centered, max width, table-like sales list, dialogs for details
          return Scaffold(
            appBar: AppBar(title: const Text('Sales')),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
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
                      const SizedBox(height: 16),
                      // Table header
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        color: Colors.grey.shade100,
                        child: Row(
                          children: const [
                            Expanded(flex: 3, child: Text('Sale ID', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('Shop', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                      const Divider(height: 0),
                      Expanded(
                        child: sales.isEmpty
                            ? const Center(child: Text('No sales found.'))
                            : ListView.builder(
                                itemCount: sales.length,
                                itemBuilder: (ctx, i) {
                                  final sale = sales[i];
                                  final shop = shopProvider.shops.firstWhere(
                                    (s) => s.id == sale.shopId,
                                    orElse: () => Shop(
                                      id: sale.shopId,
                                      name: 'Unknown Shop',
                                      businessId: '',
                                    ),
                                  );
                                  return InkWell(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) {
                                          return Dialog(
                                            child: Padding(
                                              padding: const EdgeInsets.all(24.0),
                                              child: SingleChildScrollView(
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text('Sale Details', style: Theme.of(context).textTheme.titleLarge),
                                                    const SizedBox(height: 8),
                                                    Text('Shop: ${shop.name}', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                                                    const SizedBox(height: 16),
                                                    ...sale.items.map<Widget>(
                                                      (item) => Padding(
                                                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            Expanded(child: Text(item.product.name)),
                                                            Text('${item.quantity} x K${item.product.price.toStringAsFixed(2)}'),
                                                            Text('= K${(item.quantity * item.product.price).toStringAsFixed(2)}'),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    const Divider(),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                                                        Text('K${sale.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Consumer<ReturnsProvider>(
                                                      builder: (context, returnsProvider, child) {
                                                        final hasReturns = returnsProvider.hasReturns(sale.id);
                                                        final totalReturnAmount = returnsProvider.getTotalReturnAmountForSale(sale.id);
                                                        return Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            if (hasReturns) ...[
                                                              Container(
                                                                padding: const EdgeInsets.all(8),
                                                                decoration: BoxDecoration(
                                                                  color: Colors.orange.shade50,
                                                                  borderRadius: BorderRadius.circular(8),
                                                                ),
                                                                child: Row(
                                                                  children: [
                                                                    Icon(Icons.assignment_return, color: Colors.orange.shade700, size: 16),
                                                                    const SizedBox(width: 8),
                                                                    Text('Returns: K${totalReturnAmount.toStringAsFixed(2)}', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
                                                                  ],
                                                                ),
                                                              ),
                                                              const SizedBox(height: 8),
                                                            ],
                                                            SizedBox(
                                                              width: double.infinity,
                                                              child: ElevatedButton.icon(
                                                                onPressed: () {
                                                                  Navigator.of(context).pop();
                                                                  showDialog(
                                                                    context: context,
                                                                    builder: (_) => Dialog(
                                                                      child: ReturnModal(sale: sale),
                                                                    ),
                                                                  );
                                                                },
                                                                icon: const Icon(Icons.assignment_return),
                                                                label: const Text('Return Items'),
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor: Colors.orange,
                                                                  foregroundColor: Colors.white,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        );
                                                      },
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
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(color: Colors.grey.shade200),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(flex: 3, child: Text(sale.id)),
                                          Expanded(flex: 2, child: Text(sale.date.toIso8601String())),
                                          Expanded(flex: 2, child: Text(shop.name, style: TextStyle(color: Colors.grey.shade600, fontSize: 12))),
                                          Expanded(flex: 2, child: Text('K${sale.grandTotal.toStringAsFixed(2)}')),
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
            floatingActionButton: (user != null && (user.role == 'admin' || user.role == 'manager' || user.role == 'employee'))
                ? FloatingActionButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          child: SizedBox(width: 500, child: NewSaleModal()),
                        ),
                      );
                    },
                    child: const Icon(Icons.add),
                    backgroundColor: Colors.green.shade700,
                  )
                : null,
          );
        }

        // Mobile layout (unchanged)
        return Scaffold(
          appBar: AppBar(title: const Text('Sales')),
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
                        child: const Text(
                          'Clear',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: sales.length,
                  itemBuilder: (ctx, i) {
                    final sale = sales[i];
                    final shop = shopProvider.shops.firstWhere(
                      (s) => s.id == sale.shopId,
                      orElse:
                          () => Shop(
                            id: sale.shopId,
                            name: 'Unknown Shop',
                            businessId: '',
                          ),
                    );

                    return ListTile(
                      title: Text('Sale ID: ${sale.id}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sale.date.toIso8601String()),
                          Text(
                            'Shop: ${shop.name}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: Text('K${sale.grandTotal.toStringAsFixed(2)}'),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) {
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sale Details',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Shop: ${shop.name}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ...sale.items.map<Widget>(
                                    (item) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4.0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(item.product.name),
                                          ),
                                          Text(
                                            '${item.quantity} x K${item.product.price.toStringAsFixed(2)}',
                                          ),
                                          Text(
                                            '= K${(item.quantity * item.product.price).toStringAsFixed(2)}',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Total:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'K${sale.grandTotal.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Return functionality
                                  Consumer<ReturnsProvider>(
                                    builder: (context, returnsProvider, child) {
                                      final hasReturns = returnsProvider
                                          .hasReturns(sale.id);
                                      final totalReturnAmount = returnsProvider
                                          .getTotalReturnAmountForSale(sale.id);

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (hasReturns) ...[
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.assignment_return,
                                                    color:
                                                        Colors.orange.shade700,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Returns: K${totalReturnAmount.toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      color:
                                                          Colors
                                                              .orange
                                                              .shade700,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                          ],
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                showModalBottomSheet(
                                                  context: context,
                                                  isScrollControlled: true,
                                                  builder:
                                                      (_) => ReturnModal(
                                                        sale: sale,
                                                      ),
                                                );
                                              },
                                              icon: const Icon(
                                                Icons.assignment_return,
                                              ),
                                              label: const Text('Return Items'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.orange,
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton:
              (user != null &&
                      (user.role == 'admin' ||
                          user.role == 'manager' ||
                          user.role == 'employee'))
                  ? FloatingActionButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const NewSaleModal(),
                      );
                    },
                    child: const Icon(Icons.add),
                    backgroundColor: Colors.green.shade700,
                  )
                  : null,
        );
      },
    );
  }
}
