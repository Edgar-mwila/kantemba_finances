import 'package:flutter/material.dart';
import 'package:kantemba_finances/providers/business_provider.dart';
import 'package:provider/provider.dart';
import '../providers/shop_provider.dart';
import '../models/shop.dart';
import '../screens/premium_screen.dart';
import 'package:kantemba_finances/helpers/platform_helper.dart';

class ShopManagementScreen extends StatefulWidget {
  const ShopManagementScreen({super.key});

  @override
  _ShopManagementScreenState createState() => _ShopManagementScreenState();
}

class _ShopManagementScreenState extends State<ShopManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _name;
  // String? _location;

  void _showShopDialog({Shop? shop}) {
    final businessProvider = Provider.of<BusinessProvider>(
      context,
      listen: false,
    );
    _name = shop?.name;
    // _location = shop?.location;
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(shop == null ? 'Add Shop' : 'Edit Shop'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: _name,
                    decoration: InputDecoration(labelText: 'Shop Name'),
                    validator:
                        (val) =>
                            val == null || val.isEmpty ? 'Enter name' : null,
                    onSaved: (val) => _name = val,
                  ),
                  // TextFormField(
                  //   initialValue: _location,
                  //   decoration: InputDecoration(labelText: 'Location'),
                  //   validator:
                  //       (val) =>
                  //           val == null || val.isEmpty
                  //               ? 'Enter location'
                  //               : null,
                  //   onSaved: (val) => _location = val,
                  // ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    final shopProvider = Provider.of<ShopProvider>(
                      context,
                      listen: false,
                    );
                    if (shop == null) {
                      await shopProvider.addShop(
                        Shop(
                          id: '${businessProvider.id}_$_name',
                          name: _name!,
                          // location: _location!,
                          businessId: businessProvider.id!,
                        ), // id and businessId will be set by backend
                      );
                    } else {
                      await shopProvider.editShop(
                        Shop(
                          id: shop.id,
                          name: _name!,
                          // location: _location!,
                          businessId: shop.businessId,
                        ),
                      );
                    }
                    Navigator.of(ctx).pop();
                  }
                },
                child: Text(shop == null ? 'Add' : 'Save'),
              ),
            ],
          ),
    );
  }

  void _showPremiumRequiredDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PremiumScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopProvider = Provider.of<ShopProvider>(context);
    if (isWindows) {
      // Desktop layout: Centered, max width, table-like shop list, dialogs for add/edit
      return Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Manage Shops',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          final isPremium = Provider.of<BusinessProvider>(context, listen: false).isPremium;
                          if (isPremium) {
                            _showShopDialog();
                          } else {
                            _showPremiumRequiredDialog();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                // Table header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  color: Colors.grey.shade100,
                  child: Row(
                    children: const [
                      Expanded(flex: 4, child: Text('Shop Name', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                const Divider(height: 0),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => shopProvider.fetchShops(Provider.of<BusinessProvider>(context, listen: false).id!),
                    child: shopProvider.shops.isEmpty
                        ? const Center(child: Text('No shops found.'))
                        : ListView.builder(
                            itemCount: shopProvider.shops.length,
                            itemBuilder: (ctx, i) {
                              final shop = shopProvider.shops[i];
                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Colors.grey.shade200),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(flex: 4, child: Text(shop.name)),
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () => _showShopDialog(shop: shop),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () async {
                                              await shopProvider.deleteShop(
                                                shop.id,
                                                Provider.of<BusinessProvider>(context, listen: false).id!,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    // Mobile layout (unchanged)
    return Scaffold(
      body: Column(
        children: [
          // Title section with add button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Manage Shops',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    final isPremium =
                        Provider.of<BusinessProvider>(
                          context,
                          listen: false,
                        ).isPremium;
                    if (isPremium) {
                      _showShopDialog();
                    } else {
                      _showPremiumRequiredDialog();
                    }
                  },
                ),
              ],
            ),
          ),
          // Shop list
          Expanded(
            child: RefreshIndicator(
              onRefresh:
                  () => shopProvider.fetchShops(
                    Provider.of<BusinessProvider>(context, listen: false).id!,
                  ),
              child: ListView.builder(
                itemCount: shopProvider.shops.length,
                itemBuilder: (ctx, i) {
                  final shop = shopProvider.shops[i];
                  return ListTile(
                    title: Text(shop.name),
                    // subtitle: Text(shop.location),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _showShopDialog(shop: shop),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () async {
                            await shopProvider.deleteShop(
                              shop.id,
                              Provider.of<BusinessProvider>(
                                context,
                                listen: false,
                              ).id!,
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
