import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/providers/inventory_provider.dart';
import 'package:kantemba_finances/widgets/new_inventory_modal.dart';
import '../providers/shop_provider.dart';
import '../providers/users_provider.dart';
import '../models/shop.dart';
import 'package:kantemba_finances/helpers/platform_helper.dart';
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

        if (isWindows) {
          // Desktop layout: Centered, max width, header add button, table-like list
          return Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Inventory',
                            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                          ),
                          if (user != null &&
                              (user.permissions.contains('add_inventory') ||
                                  user.permissions.contains('all') ||
                                  user.role == 'admin' ||
                                  user.role == 'owner'))
                            ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => Dialog(
                                    child: SizedBox(
                                      width: 400,
                                      child: NewInventoryModal(),
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Item'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Table header
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        color: Colors.grey.shade100,
                        child: Row(
                          children: const [
                            Expanded(flex: 3, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('Shop', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 2, child: Text('Price', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                      const Divider(height: 0),
                      Expanded(
                        child: items.isEmpty
                            ? const Center(child: Text('No inventory items found.'))
                            : ListView.builder(
                                itemCount: items.length,
                                itemBuilder: (ctx, i) {
                                  final item = items[i];
                                  final shop = shopProvider.shops.firstWhere(
                                    (s) => s.id == item.shopId,
                                    orElse: () => Shop(
                                      id: item.shopId,
                                      name: 'Unknown Shop',
                                      businessId: '',
                                    ),
                                  );
                                  return Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(color: Colors.grey.shade200),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(flex: 3, child: Text(item.name)),
                                        Expanded(flex: 2, child: Text(item.quantity.toString())),
                                        Expanded(flex: 2, child: Text(shop.name, style: TextStyle(color: Colors.grey.shade600, fontSize: 12))),
                                        Expanded(flex: 2, child: Text('K${item.price.toStringAsFixed(2)}')),
                                      ],
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
          body: Column(
            children: [
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
