import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shop_provider.dart';
import 'package:kantemba_finances/helpers/platform_helper.dart';

class ShopFilterWidget extends StatelessWidget {
  final String? selectedShopId;
  final Function(String?) onShopChanged;
  final bool showAllOption;

  const ShopFilterWidget({
    Key? key,
    required this.selectedShopId,
    required this.onShopChanged,
    this.showAllOption = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopProvider>(
      builder: (context, shopProvider, child) {
        final shops = shopProvider.shops;

        if (shops.isEmpty) {
          return const SizedBox.shrink();
        }

        if (isWindows(context)) {
          // Desktop layout: wider dropdown, more padding, centered if in dialog
          return Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              constraints: const BoxConstraints(maxWidth: 400),
              child: Row(
                children: [
                  const Icon(Icons.store, size: 22),
                  const SizedBox(width: 12),
                  const Text(
                    'Shop:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedShopId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: [
                        if (showAllOption)
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Shops'),
                          ),
                        ...shops.map(
                          (shop) => DropdownMenuItem<String>(
                            value: shop.id,
                            child: Text(shop.name),
                          ),
                        ),
                      ],
                      onChanged: onShopChanged,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Mobile layout (unchanged)
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.store, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Shop:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedShopId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    if (showAllOption)
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Shops'),
                      ),
                    ...shops.map(
                      (shop) => DropdownMenuItem<String>(
                        value: shop.id,
                        child: Text(shop.name),
                      ),
                    ),
                  ],
                  onChanged: onShopChanged,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
