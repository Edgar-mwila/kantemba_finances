import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/providers/inventory_provider.dart';
import 'package:kantemba_finances/widgets/new_inventory_modal.dart';
import '../providers/shop_provider.dart';
import '../providers/users_provider.dart';
import '../models/shop.dart';
// import 'package:kantemba_finances/models/inventory_item.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inventoryData = Provider.of<InventoryProvider>(context);
    final userProvider = Provider.of<UsersProvider>(context);
    final user = userProvider.currentUser;

    return Consumer<ShopProvider>(
      builder: (context, shopProvider, child) {
        // Use filtered items based on current shop
        final items = inventoryData.getItemsForShop(shopProvider.currentShop);

        return Scaffold(
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
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final item = items[i];
                final shop = shopProvider.shops.firstWhere(
                  (s) => s.id == item.shopId,
                  orElse:
                      () => Shop(
                        id: item.shopId,
                        name: 'Unknown Shop',
                        businessId: '',
                      ),
                );

                return ListTile(
                  title: Text(item.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quantity: ${item.quantity}'),
                      Text(
                        'Shop: ${shop.name}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: Text('K${item.price.toStringAsFixed(2)}'),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton:
          (user != null &&
                  (user.permissions.contains('add_inventory') ||
                      user.permissions.contains('all') ||
                      user.role == 'admin' ||
                      user.role == 'owner'))
              ? FloatingActionButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (ctx) => const NewInventoryModal(),
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
