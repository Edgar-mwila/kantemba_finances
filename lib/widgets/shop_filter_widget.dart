import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shop_provider.dart';

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
