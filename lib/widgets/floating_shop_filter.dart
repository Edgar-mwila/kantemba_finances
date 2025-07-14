import 'package:flutter/material.dart';
import 'package:kantemba_finances/helpers/platform_helper.dart';

class FloatingShopFilter extends StatelessWidget {
  const FloatingShopFilter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Placeholder: Implement floating filter for desktop if needed
    if (isWindows(context)) {
      return Positioned(
        right: 32,
        bottom: 32,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.filter_list, color: Colors.green),
                SizedBox(width: 8),
                Text('Filter Shops'),
              ],
            ),
          ),
        ),
      );
    }
    // Mobile: could be a FloatingActionButton or similar
    return FloatingActionButton(
      onPressed: () {},
      child: const Icon(Icons.filter_list),
      backgroundColor: Colors.green,
    );
  }
}
