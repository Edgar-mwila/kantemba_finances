import 'package:flutter/material.dart';
import 'package:kantemba_finances/providers/business_provider.dart';
import 'package:kantemba_finances/providers/shop_provider.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/models/inventory_item.dart';
import 'package:kantemba_finances/models/sale.dart';
import 'package:kantemba_finances/providers/inventory_provider.dart';
import 'package:kantemba_finances/providers/sales_provider.dart';
import 'package:kantemba_finances/providers/users_provider.dart';
import 'package:kantemba_finances/helpers/platform_helper.dart';

class NewSaleModal extends StatefulWidget {
  const NewSaleModal({super.key});

  @override
  State<NewSaleModal> createState() => _NewSaleModalState();
}

class _NewSaleModalState extends State<NewSaleModal> {
  final List<SaleItem> _cartItems = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  double _grandTotal = 0.0;
  double _discountAmount = 0.0;
  String _searchQuery = '';
  bool _isProcessing = false;

  @override
  void dispose() {
    _searchController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _addProductToCart(InventoryItem product) {
    print('Attempting to add product: ${product.name} (id: ${product.id})');
    if (product.quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product is out of stock'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      final existingItemIndex = _cartItems.indexWhere(
        (item) => item.product.id == product.id,
      );
      print(
        'Current cart items: ${_cartItems.map((e) => e.product.name).toList()}',
      );
      if (existingItemIndex != -1) {
        final currentCartQuantity = _cartItems[existingItemIndex].quantity;
        if (currentCartQuantity >= product.quantity) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Insufficient stock available'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        _cartItems[existingItemIndex].quantity++;
        print('Incremented quantity for: ${product.name}');
      } else {
        _cartItems.add(SaleItem(product: product, quantity: 1));
        print('Added new product to cart: ${product.name}');
      }
      _calculateTotal();
      print(
        'Cart after add: ${_cartItems.map((e) => "${e.product.name} (qty: ${e.quantity})").toList()}',
      );
    });
  }

  void _removeProductFromCart(String productId) {
    setState(() {
      _cartItems.removeWhere((item) => item.product.id == productId);
      _calculateTotal();
    });
  }

  void _updateQuantity(String productId, int newQuantity) {
    final item = _cartItems.firstWhere(
      (item) => item.product.id == productId,
      orElse: () => throw StateError('Item not found'),
    );

    if (newQuantity > item.product.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot exceed available stock (${item.product.quantity})',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      final index = _cartItems.indexWhere(
        (item) => item.product.id == productId,
      );
      if (index != -1) {
        if (newQuantity > 0) {
          _cartItems[index].quantity = newQuantity;
        } else {
          _cartItems.removeAt(index);
        }
        _calculateTotal();
      }
    });
  }

  void _clearCart() {
    final previousCart = List<SaleItem>.from(
      _cartItems.map(
        (item) => SaleItem(product: item.product, quantity: item.quantity),
      ),
    );
    setState(() {
      _cartItems.clear();
      _calculateTotal();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Cart cleared'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _cartItems.clear();
              _cartItems.addAll(previousCart);
              _calculateTotal();
            });
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _calculateTotal() {
    _grandTotal = 0.0;
    for (var item in _cartItems) {
      _grandTotal += item.product.price * item.quantity;
    }
    // Apply discount
    _grandTotal -= _discountAmount;
    if (_grandTotal < 0) _grandTotal = 0.0;
  }

  void _updateDiscount(String value) {
    setState(() {
      _discountAmount = double.tryParse(value) ?? 0.0;
      _calculateTotal();
    });
  }

  Future<void> _addSale() async {
    if (_cartItems.isEmpty) return;

    final currentUser =
        Provider.of<UsersProvider>(context, listen: false).currentUser;
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No user is logged in!')));
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final currentShop = shopProvider.currentShop;
    print(
      "currentUser: ${currentUser.name}, shopProvider: ${shopProvider.currentShop?.name}",
    );
    if (currentShop == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No shop is selected!')));
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    try {
      final newSale = Sale(
        id:
            '${currentShop.name.replaceAll(' ', '_')}_sale_${DateTime.now().millisecondsSinceEpoch}', // ID will be generated by provider
        items: List<SaleItem>.from(_cartItems),
        totalAmount:
            _grandTotal + _discountAmount, // Original total before discount
        grandTotal: _grandTotal, // Final total after discount
        vat: 0.0,
        turnoverTax: 0.0,
        levy: 0.0,
        date: DateTime.now(),
        shopId: currentShop.id,
        createdBy: '', // Will be set by provider
        customerName: _customerNameController.text.trim(),
        customerPhone: _customerPhoneController.text.trim(),
        discount: _discountAmount,
      );

      await Provider.of<SalesProvider>(context, listen: false).addSaleHybrid(
        newSale,
        currentUser.id,
        currentShop.id,
        Provider.of<BusinessProvider>(context, listen: false),
      );

      for (var item in _cartItems) {
        await Provider.of<InventoryProvider>(
          context,
          listen: false,
        ).saleStock(item.product.id, item.quantity);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sale added! Total: K${_grandTotal.toStringAsFixed(2)}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add sale: ${e.toString()}'),
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

  List<InventoryItem> _getFilteredProducts() {
    final availableProducts =
        Provider.of<InventoryProvider>(
          context,
        ).items.where((product) => product.quantity > 0).toList();

    if (_searchQuery.isEmpty) {
      return availableProducts;
    }

    return availableProducts.where((product) {
      return product.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _getFilteredProducts();

    if (isWindows) {
      // Desktop layout: side-by-side product list and cart, wider, more padding
      return Material(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Sale',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product List
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                labelText: 'Search product',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            Container(
                              height: 260,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child:
                                  filteredProducts.isEmpty
                                      ? const Center(
                                        child: Text('No products found'),
                                      )
                                      : ListView.builder(
                                        itemCount: filteredProducts.length,
                                        itemBuilder: (ctx, i) {
                                          final product = filteredProducts[i];
                                          return ListTile(
                                            title: Text(product.name),
                                            subtitle: Text(
                                              'Price: ${product.price.toStringAsFixed(2)} | Stock: ${product.quantity}',
                                            ),
                                            trailing: IconButton(
                                              icon: const Icon(Icons.add),
                                              onPressed:
                                                  product.quantity == 0
                                                      ? null
                                                      : () => _addProductToCart(
                                                        product,
                                                      ),
                                              color:
                                                  product.quantity == 0
                                                      ? Colors.grey
                                                      : Theme.of(
                                                        context,
                                                      ).iconTheme.color,
                                              tooltip:
                                                  product.quantity == 0
                                                      ? 'Out of stock'
                                                      : 'Add to cart',
                                            ),
                                          );
                                        },
                                      ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      // Cart
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cart',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 260,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child:
                                  _cartItems.isEmpty
                                      ? const Center(
                                        child: Text('No items in cart'),
                                      )
                                      : ListView.builder(
                                        itemCount: _cartItems.length,
                                        itemBuilder: (ctx, i) {
                                          final cartItem = _cartItems[i];
                                          return ListTile(
                                            title: Text(cartItem.product.name),
                                            subtitle: Text(
                                              'Unit: ${cartItem.product.price.toStringAsFixed(2)} | Qty: ${cartItem.quantity} | Total: ${(cartItem.product.price * cartItem.quantity).toStringAsFixed(2)}',
                                            ),
                                            leading: IconButton(
                                              icon: const Icon(
                                                Icons.remove_circle_outline,
                                              ),
                                              onPressed:
                                                  () => _removeProductFromCart(
                                                    cartItem.product.id,
                                                  ),
                                              tooltip: 'Remove from cart',
                                              iconSize: 28,
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.remove),
                                                  onPressed: () {
                                                    if (cartItem.quantity > 1) {
                                                      _updateQuantity(
                                                        cartItem.product.id,
                                                        cartItem.quantity - 1,
                                                      );
                                                    }
                                                  },
                                                  tooltip: 'Decrease quantity',
                                                  iconSize: 28,
                                                ),
                                                Text('${cartItem.quantity}'),
                                                IconButton(
                                                  icon: const Icon(Icons.add),
                                                  onPressed: () {
                                                    _updateQuantity(
                                                      cartItem.product.id,
                                                      cartItem.quantity + 1,
                                                    );
                                                  },
                                                  tooltip: 'Increase quantity',
                                                  iconSize: 28,
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                            ),
                            const SizedBox(height: 16),
                            // Customer Information Section
                            Text(
                              'Customer Information',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _customerNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Customer Name',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _customerPhoneController,
                                    decoration: const InputDecoration(
                                      labelText: 'Phone Number',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _discountController,
                              decoration: const InputDecoration(
                                labelText: 'Discount Amount',
                                border: OutlineInputBorder(),
                                prefixText: 'K',
                              ),
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              onChanged: _updateDiscount,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Subtotal:',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  (_grandTotal + _discountAmount).toStringAsFixed(
                                    2,
                                  ),
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                            if (_discountAmount > 0) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Discount:',
                                    style: Theme.of(context).textTheme.bodyMedium
                                        ?.copyWith(color: Colors.red),
                                  ),
                                  Text(
                                    '-${_discountAmount.toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.bodyMedium
                                        ?.copyWith(color: Colors.red),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total:',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _grandTotal.toStringAsFixed(2),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.clear),
                                  label: const Text('Clear Cart'),
                                  onPressed: _clearCart,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Add Sale button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _isProcessing || _cartItems.isEmpty ? null : _addSale,
                      child:
                          _isProcessing
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                              : const Text('Add Sale'),
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
    return Material(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'New Sale',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search product',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Product list
                SizedBox(
                  height: 180,
                  child:
                      filteredProducts.isEmpty
                          ? const Center(child: Text('No products found'))
                          : ListView.builder(
                            itemCount: filteredProducts.length,
                            itemBuilder: (ctx, i) {
                              final product = filteredProducts[i];
                              return ListTile(
                                title: Text(product.name),
                                subtitle: Text(
                                  'Price: ${product.price.toStringAsFixed(2)} | Stock: ${product.quantity}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed:
                                      product.quantity == 0
                                          ? null
                                          : () => _addProductToCart(product),
                                  color:
                                      product.quantity == 0
                                          ? Colors.grey
                                          : Theme.of(context).iconTheme.color,
                                  tooltip:
                                      product.quantity == 0
                                          ? 'Out of stock'
                                          : 'Add to cart',
                                ),
                              );
                            },
                          ),
                ),
                const Divider(),
                // Cart items
                if (_cartItems.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Cart', style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      itemCount: _cartItems.length,
                      itemBuilder: (ctx, i) {
                        final cartItem = _cartItems[i];
                        return ListTile(
                          title: Text(cartItem.product.name),
                          subtitle: Text(
                            'Unit: ${cartItem.product.price.toStringAsFixed(2)} | Qty: ${cartItem.quantity} | Total: ${(cartItem.product.price * cartItem.quantity).toStringAsFixed(2)}',
                          ),
                          leading: IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed:
                                () => _removeProductFromCart(cartItem.product.id),
                            tooltip: 'Remove from cart',
                            iconSize: 28,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  if (cartItem.quantity > 1) {
                                    _updateQuantity(
                                      cartItem.product.id,
                                      cartItem.quantity - 1,
                                    );
                                  }
                                },
                                tooltip: 'Decrease quantity',
                                iconSize: 28,
                              ),
                              Text('${cartItem.quantity}'),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  _updateQuantity(
                                    cartItem.product.id,
                                    cartItem.quantity + 1,
                                  );
                                },
                                tooltip: 'Increase quantity',
                                iconSize: 28,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Customer Information Section
                  Text(
                    'Customer Information',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: _customerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _customerPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 8),
                  TextField(
                    controller: _discountController,
                    decoration: const InputDecoration(
                      labelText: 'Discount Amount',
                      border: OutlineInputBorder(),
                      prefixText: 'K',
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: _updateDiscount,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        (_grandTotal + _discountAmount).toStringAsFixed(2),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  if (_discountAmount > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Discount:',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.red),
                        ),
                        Text(
                          '-${_discountAmount.toStringAsFixed(2)}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.red),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _grandTotal.toStringAsFixed(2),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear Cart'),
                        onPressed: _clearCart,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                // Add Sale button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _isProcessing || _cartItems.isEmpty ? null : _addSale,
                    child:
                        _isProcessing
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text('Add Sale'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
