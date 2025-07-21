import 'package:flutter/material.dart';
import 'package:kantemba_finances/models/sale.dart';
import 'package:kantemba_finances/screens/returns_screen.dart';
import 'package:provider/provider.dart';
import 'package:kantemba_finances/providers/sales_provider.dart';
import 'package:kantemba_finances/widgets/new_sale_modal.dart';
import '../providers/shop_provider.dart';
import '../providers/users_provider.dart';
import '../providers/returns_provider.dart';
import 'package:kantemba_finances/helpers/platform_helper.dart';
import 'package:intl/intl.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'date'; // 'date', 'total', 'discount'
  bool _sortAscending = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Sale> _filterAndSortSales(List<Sale> sales) {
    // Filter sales based on search query
    List<Sale> filteredSales =
        sales.where((sale) {
          if (_searchQuery.isEmpty) return true;

          final query = _searchQuery.toLowerCase();

          // Search by sale ID
          if (sale.id.toLowerCase().contains(query)) return true;

          // Search by customer name
          if (sale.customerName != null &&
              sale.customerName!.toLowerCase().contains(query))
            return true;

          // Search by customer phone
          if (sale.customerPhone != null &&
              sale.customerPhone!.toLowerCase().contains(query))
            return true;

          // Search by product names in sale items
          for (var item in sale.items) {
            if (item.product.name.toLowerCase().contains(query)) return true;
          }

          return false;
        }).toList();

    // Sort sales
    filteredSales.sort((a, b) {
      int comparison = 0;

      switch (_sortBy) {
        case 'date':
          comparison = a.date.compareTo(b.date);
          break;
        case 'total':
          comparison = a.grandTotal.compareTo(b.grandTotal);
          break;
        case 'discount':
          comparison = a.discount.compareTo(b.discount);
          break;
      }

      return _sortAscending ? comparison : -comparison;
    });

    return filteredSales;
  }

  Widget _buildSearchAndSortBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by customer, phone, product, or sale ID...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  _searchQuery.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),

          // Sort controls
          Row(
            children: [
              const Text(
                'Sort by: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _sortBy,
                items: const [
                  DropdownMenuItem(value: 'date', child: Text('Date')),
                  DropdownMenuItem(value: 'total', child: Text('Total')),
                  DropdownMenuItem(value: 'discount', child: Text('Discount')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _sortBy = value;
                    });
                  }
                },
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () {
                  setState(() {
                    _sortAscending = !_sortAscending;
                  });
                },
                icon: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                ),
                tooltip: _sortAscending ? 'Sort Descending' : 'Sort Ascending',
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salesData = Provider.of<SalesProvider>(context);
    final userProvider = Provider.of<UsersProvider>(context);
    final user = userProvider.currentUser;

    return Consumer<ShopProvider>(
      builder: (context, shopProvider, child) {
        // Use filtered sales based on current shop
        final allSales = salesData.getSalesForShop(shopProvider.currentShop);
        final filteredAndSortedSales = _filterAndSortSales(allSales);

        if (isWindows(context)) {
          // Desktop layout: Centered, max width, table-like sales list, dialogs for details
          return Scaffold(
            appBar: AppBar(
              title: const Text('Sales'),
              actions: [
                if (filteredAndSortedSales.isNotEmpty)
                  Text(
                    '${filteredAndSortedSales.length} sales',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                const SizedBox(width: 16),
              ],
            ),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      // Search and sort bar
                      _buildSearchAndSortBar(),
                      const SizedBox(height: 16),

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
                                'Sale ID',
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
                            filteredAndSortedSales.isEmpty
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 64,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchQuery.isEmpty
                                            ? 'No sales found.'
                                            : 'No sales match your search.',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      if (_searchQuery.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Try adjusting your search terms.',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                )
                                : ListView.builder(
                                  itemCount: filteredAndSortedSales.length,
                                  itemBuilder: (ctx, i) {
                                    final sale = filteredAndSortedSales[i];
                                    final shop = shopProvider.shops.firstWhere(
                                      (s) => s.id == sale.shopId,
                                      orElse:
                                          () =>
                                              shopProvider
                                                  .shops
                                                  .first, // Fallback to first shop if not found
                                    );
                                    return InkWell(
                                      onTap: () {
                                        _showSaleDetailsDialog(
                                          context,
                                          sale,
                                          shopProvider,
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
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(sale.id),
                                                  if (sale.customerName !=
                                                          null &&
                                                      sale
                                                          .customerName!
                                                          .isNotEmpty)
                                                    Text(
                                                      'Customer: ${sale.customerName}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade700,
                                                      ),
                                                    ),
                                                  if (sale.customerPhone !=
                                                          null &&
                                                      sale
                                                          .customerPhone!
                                                          .isNotEmpty)
                                                    Text(
                                                      'Phone: ${sale.customerPhone}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade700,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                DateFormat(
                                                  'yyyy-MM-dd - kk:mm',
                                                ).format(sale.date),
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
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    'K${sale.grandTotal.toStringAsFixed(2)}',
                                                  ),
                                                  if (sale.discount > 0)
                                                    Text(
                                                      'Discount: -K${sale.discount.toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.orange,
                                                      ),
                                                    ),
                                                ],
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
            floatingActionButton: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (user != null)
                  FloatingActionButton(
                    heroTag: 'sales_add_button',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const NewSaleModal(),
                      );
                    },
                    child: const Icon(Icons.add),
                    backgroundColor: Colors.green.shade700,
                  ),
                const SizedBox(width: 16),
                FloatingActionButton.extended(
                  heroTag: 'sales_returns_button',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReturnsScreen(),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.assignment_return,
                    size: 32,
                    color: Colors.orange.shade700,
                  ),
                  label: Text('Returns'),
                ),
              ],
            ),
          );
        }

        // Mobile layout
        return Scaffold(
          appBar: AppBar(
            title: const Text('Sales'),
            actions: [
              if (filteredAndSortedSales.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Text(
                      '${filteredAndSortedSales.length}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              // Search and sort bar for mobile
              _buildSearchAndSortBar(),

              Expanded(
                child:
                    filteredAndSortedSales.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No sales found.'
                                    : 'No sales match your search.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (_searchQuery.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Try adjusting your search terms.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                        : ListView.builder(
                          itemCount: filteredAndSortedSales.length,
                          itemBuilder: (ctx, i) {
                            final sale = filteredAndSortedSales[i];
                            final shop = shopProvider.shops.firstWhere(
                              (s) => s.id == sale.shopId,
                              orElse:
                                  () =>
                                      shopProvider
                                          .shops
                                          .first, // Fallback to first shop if not found
                            );

                            return ListTile(
                              title: Text(
                                'Sale ID: ${sale.id}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat(
                                      'yyyy-MM-dd - kk:mm',
                                    ).format(sale.date),
                                  ),
                                  Text(
                                    'Shop: ${shop.name}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (sale.customerName != null &&
                                      sale.customerName!.isNotEmpty)
                                    Text(
                                      'Customer: ${sale.customerName}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  if (sale.customerPhone != null &&
                                      sale.customerPhone!.isNotEmpty)
                                    Text(
                                      'Phone: ${sale.customerPhone}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'K${sale.grandTotal.toStringAsFixed(2)}',
                                  ),
                                  if (sale.discount > 0)
                                    Text(
                                      'Discount: -K${sale.discount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange,
                                      ),
                                    ),
                                ],
                              ),
                              onTap: () {
                                _showSaleDetailsDialog(
                                  context,
                                  sale,
                                  shopProvider,
                                );
                              },
                            );
                          },
                        ),
              ),
              // Bottom spacing for floating buttons
              const SizedBox(height: 80),
            ],
          ),
          floatingActionButton: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (user != null)
                FloatingActionButton(
                  heroTag: 'sales_add_button',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const NewSaleModal(),
                    );
                  },
                  child: const Icon(Icons.add),
                  backgroundColor: Colors.green.shade700,
                ),
              const SizedBox(width: 16),
              FloatingActionButton.extended(
                heroTag: 'sales_returns_button',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReturnsScreen(),
                    ),
                  );
                },
                icon: Icon(
                  Icons.assignment_return,
                  size: 32,
                  color: Colors.orange.shade700,
                ),
                label: Text('Returns'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSaleDetailsDialog(
    BuildContext context,
    Sale sale,
    ShopProvider shopProvider,
  ) {
    final shop = shopProvider.shops.firstWhere(
      (s) => s.id == sale.shopId,
      orElse: () => shopProvider.shops.first,
    );

    showDialog(
      context: context,
      builder:
          (ctx) => Dialog(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: BoxConstraints(
                maxWidth: 800,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Sale Details',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Sale Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.receipt,
                                  color: Colors.blue.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Sale ID: ${sale.id}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.store,
                                  color: Colors.green.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Shop: ${shop.name}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (sale.customerName != null &&
                                sale.customerName!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    color: Colors.orange.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Customer: ${sale.customerName}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (sale.customerPhone != null &&
                                sale.customerPhone!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone,
                                    color: Colors.orange.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Phone: ${sale.customerPhone}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: Colors.purple.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Date: ${DateFormat('MMM dd, yyyy HH:mm').format(sale.date)}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Items List
                      Text(
                        'Items Sold:',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: sale.items.length,
                          itemBuilder: (context, index) {
                            final item = sale.items[index];
                            final hasReturns = item.returnedQuantity > 0;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.product.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          'K${item.product.price.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Quantity: ${item.quantity}',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          'Subtotal: K${(item.quantity * item.product.price).toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (hasReturns) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.assignment_return,
                                              color: Colors.orange.shade700,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Returned: ${item.returnedQuantity} units - ${item.returnedReason}',
                                                style: TextStyle(
                                                  color: Colors.orange.shade700,
                                                  fontSize: 12,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
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
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Subtotal:',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  'K${sale.totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            if (sale.discount > 0) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Discount:',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    '-K${sale.discount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (sale.vat > 0) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'VAT:',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    'K${sale.vat.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (sale.turnoverTax > 0) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Turnover Tax:',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    'K${sale.turnoverTax.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (sale.levy > 0) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Levy:',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    'K${sale.levy.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total:',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'K${sale.grandTotal.toStringAsFixed(2)}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Returns Info
                      Consumer<ReturnsProvider>(
                        builder: (context, returnsProvider, child) {
                          final hasReturns = returnsProvider.hasReturns(
                            sale.id,
                          );
                          final totalReturnAmount = returnsProvider
                              .getTotalReturnAmountForSale(sale.id);

                          if (hasReturns) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.assignment_return,
                                    color: Colors.orange.shade700,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Returns: K${totalReturnAmount.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: Colors.orange.shade700,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          'This sale has returned items',
                                          style: TextStyle(
                                            color: Colors.orange.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 16),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                showDialog(
                                  context: context,
                                  builder:
                                      (_) => Dialog(
                                        child: Container(
                                          width: MediaQuery.of(context).size.width * 0.9,
                                          constraints: BoxConstraints(
                                            maxWidth: 800,
                                            maxHeight: MediaQuery.of(context).size.height * 0.8,
                                          ),
                                          child: SingleChildScrollView(
                                            child: Padding(
                                              padding: const EdgeInsets.all(16.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // Header
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          'Print Receipt',
                                                          style: Theme.of(context).textTheme.titleLarge
                                                              ?.copyWith(fontWeight: FontWeight.bold),
                                                        ),
                                                      ),
                                                      IconButton(
                                                        onPressed: () => Navigator.of(ctx).pop(),
                                                        icon: const Icon(Icons.close),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 16),

                                                  // Sale Info
                                                  Container(
                                                    padding: const EdgeInsets.all(16),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey.shade50,
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons.receipt,
                                                              color: Colors.blue.shade700,
                                                              size: 20,
                                                            ),
                                                            const SizedBox(width: 8),
                                                            Expanded(
                                                              child: Text(
                                                                'Sale ID: ${sale.id}',
                                                                style: TextStyle(
                                                                  color: Colors.grey.shade600,
                                                                  fontSize: 14,
                                                                ),
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 8),
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons.store,
                                                              color: Colors.green.shade700,
                                                              size: 20,
                                                            ),
                                                            const SizedBox(width: 8),
                                                            Expanded(
                                                              child: Text(
                                                                'Shop: ${shop.name}',
                                                                style: TextStyle(
                                                                  color: Colors.grey.shade600,
                                                                  fontSize: 14,
                                                                ),
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        if (sale.customerName != null &&
                                                            sale.customerName!.isNotEmpty) ...[
                                                          const SizedBox(height: 8),
                                                          Row(
                                                            children: [
                                                              Icon(
                                                                Icons.person,
                                                                color: Colors.orange.shade700,
                                                                size: 20,
                                                              ),
                                                              const SizedBox(width: 8),
                                                              Expanded(
                                                                child: Text(
                                                                  'Customer: ${sale.customerName}',
                                                                  style: TextStyle(
                                                                    color: Colors.grey.shade600,
                                                                    fontSize: 14,
                                                                  ),
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                        if (sale.customerPhone != null &&
                                                            sale.customerPhone!.isNotEmpty) ...[
                                                          const SizedBox(height: 8),
                                                          Row(
                                                            children: [
                                                              Icon(
                                                                Icons.phone,
                                                                color: Colors.orange.shade700,
                                                                size: 20,
                                                              ),
                                                              const SizedBox(width: 8),
                                                              Expanded(
                                                                child: Text(
                                                                  'Phone: ${sale.customerPhone}',
                                                                  style: TextStyle(
                                                                    color: Colors.grey.shade600,
                                                                    fontSize: 14,
                                                                  ),
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                        const SizedBox(height: 8),
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons.calendar_today,
                                                              color: Colors.purple.shade700,
                                                              size: 20,
                                                            ),
                                                            const SizedBox(width: 8),
                                                            Expanded(
                                                              child: Text(
                                                                'Date: ${DateFormat('MMM dd, yyyy HH:mm').format(sale.date)}',
                                                                style: TextStyle(
                                                                  color: Colors.grey.shade600,
                                                                  fontSize: 14,
                                                                ),
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),

                                                  // Items List
                                                  Text(
                                                    'Items Sold:',
                                                    style: Theme.of(context).textTheme.titleMedium
                                                        ?.copyWith(fontWeight: FontWeight.bold),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    constraints: const BoxConstraints(maxHeight: 300),
                                                    child: ListView.builder(
                                                      shrinkWrap: true,
                                                      physics: const AlwaysScrollableScrollPhysics(),
                                                      itemCount: sale.items.length,
                                                      itemBuilder: (context, index) {
                                                        final item = sale.items[index];
                                                        final hasReturns = item.returnedQuantity > 0;

                                                        return Card(
                                                          margin: const EdgeInsets.symmetric(vertical: 4),
                                                          child: Padding(
                                                            padding: const EdgeInsets.all(12),
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment.spaceBetween,
                                                                  children: [
                                                                    Expanded(
                                                                      child: Text(
                                                                        item.product.name,
                                                                        style: const TextStyle(
                                                                          fontWeight: FontWeight.bold,
                                                                          fontSize: 16,
                                                                        ),
                                                                        overflow: TextOverflow.ellipsis,
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      'K${item.product.price.toStringAsFixed(2)}',
                                                                      style: TextStyle(
                                                                        color: Colors.grey.shade600,
                                                                        fontWeight: FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                const SizedBox(height: 8),
                                                                Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment.spaceBetween,
                                                                  children: [
                                                                    Text(
                                                                      'Quantity: ${item.quantity}',
                                                                      style: TextStyle(
                                                                        color: Colors.grey.shade600,
                                                                        fontSize: 14,
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      'Subtotal: K${(item.quantity * item.product.price).toStringAsFixed(2)}',
                                                                      style: const TextStyle(
                                                                        fontWeight: FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                if (hasReturns) ...[
                                                                  const SizedBox(height: 8),
                                                                  Container(
                                                                    padding: const EdgeInsets.all(8),
                                                                    decoration: BoxDecoration(
                                                                      color: Colors.orange.shade50,
                                                                      borderRadius: BorderRadius.circular(
                                                                        4,
                                                                      ),
                                                                    ),
                                                                    child: Row(
                                                                      children: [
                                                                        Icon(
                                                                          Icons.assignment_return,
                                                                          color: Colors.orange.shade700,
                                                                          size: 16,
                                                                        ),
                                                                        const SizedBox(width: 8),
                                                                        Expanded(
                                                                          child: Text(
                                                                            'Returned: ${item.returnedQuantity} units - ${item.returnedReason}',
                                                                            style: TextStyle(
                                                                              color: Colors.orange.shade700,
                                                                              fontSize: 12,
                                                                            ),
                                                                            overflow: TextOverflow.ellipsis,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
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
                                                      color: Colors.blue.shade50,
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            const Text(
                                                              'Subtotal:',
                                                              style: TextStyle(fontSize: 16),
                                                            ),
                                                            Text(
                                                              'K${sale.totalAmount.toStringAsFixed(2)}',
                                                              style: const TextStyle(
                                                                fontSize: 16,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        if (sale.discount > 0) ...[
                                                          const SizedBox(height: 8),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              const Text(
                                                                'Discount:',
                                                                style: TextStyle(fontSize: 16),
                                                              ),
                                                              Text(
                                                                '-K${sale.discount.toStringAsFixed(2)}',
                                                                style: TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight: FontWeight.bold,
                                                                  color: Colors.orange.shade700,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                        if (sale.vat > 0) ...[
                                                          const SizedBox(height: 8),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              const Text(
                                                                'VAT:',
                                                                style: TextStyle(fontSize: 16),
                                                              ),
                                                              Text(
                                                                'K${sale.vat.toStringAsFixed(2)}',
                                                                style: const TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                        if (sale.turnoverTax > 0) ...[
                                                          const SizedBox(height: 8),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              const Text(
                                                                'Turnover Tax:',
                                                                style: TextStyle(fontSize: 16),
                                                              ),
                                                              Text(
                                                                'K${sale.turnoverTax.toStringAsFixed(2)}',
                                                                style: const TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                        if (sale.levy > 0) ...[
                                                          const SizedBox(height: 8),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              const Text(
                                                                'Levy:',
                                                                style: TextStyle(fontSize: 16),
                                                              ),
                                                              Text(
                                                                'K${sale.levy.toStringAsFixed(2)}',
                                                                style: const TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                        const Divider(),
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            Text(
                                                              'Total:',
                                                              style: Theme.of(context).textTheme.titleMedium
                                                                  ?.copyWith(fontWeight: FontWeight.bold),
                                                            ),
                                                            Text(
                                                              'K${sale.grandTotal.toStringAsFixed(2)}',
                                                              style: Theme.of(
                                                                context,
                                                              ).textTheme.titleMedium?.copyWith(
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.green.shade700,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),

                                                  // Returns Info
                                                  Consumer<ReturnsProvider>(
                                                    builder: (context, returnsProvider, child) {
                                                      final hasReturns = returnsProvider.hasReturns(
                                                        sale.id,
                                                      );
                                                      final totalReturnAmount = returnsProvider
                                                          .getTotalReturnAmountForSale(sale.id);

                                                      if (hasReturns) {
                                                        return Container(
                                                          padding: const EdgeInsets.all(16),
                                                          decoration: BoxDecoration(
                                                            color: Colors.orange.shade50,
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                Icons.assignment_return,
                                                                color: Colors.orange.shade700,
                                                                size: 24,
                                                              ),
                                                              const SizedBox(width: 12),
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment.start,
                                                                  children: [
                                                                    Text(
                                                                      'Returns: K${totalReturnAmount.toStringAsFixed(2)}',
                                                                      style: TextStyle(
                                                                        color: Colors.orange.shade700,
                                                                        fontWeight: FontWeight.bold,
                                                                        fontSize: 16,
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      'This sale has returned items',
                                                                      style: TextStyle(
                                                                        color: Colors.orange.shade600,
                                                                        fontSize: 12,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      }
                                                      return const SizedBox.shrink();
                                                    },
                                                  ),
                                                  const SizedBox(height: 16),

                                                  // Actions
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: ElevatedButton.icon(
                                                          onPressed: () {
                                                            Navigator.of(ctx).pop();
                                                            // Call the POS receipt print function here
                                                            // This function should be available in the NewSaleModal or POS screen
                                                            // For now, we'll just pop the dialog
                                                            // In a real app, you'd call a function like:
                                                            // Navigator.of(context).pop();
                                                            // showDialog(
                                                            //   context: context,
                                                            //   builder: (_) => NewSaleModal(
                                                            //     onPrintReceipt: () {
                                                            //       // Handle receipt printing
                                                            //       print('Receipt printed for sale: ${sale.id}');
                                                            //     },
                                                            //   ),
                                                            // );
                                                          },
                                                          icon: const Icon(Icons.print),
                                                          label: const Text('Print Receipt'),
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: Colors.blue.shade700,
                                                            foregroundColor: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: ElevatedButton(
                                                          onPressed: () => Navigator.of(ctx).pop(),
                                                          child: const Text('Close'),
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: Colors.grey.shade300,
                                                            foregroundColor: Colors.black87,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                );
                              },
                              icon: const Icon(Icons.assignment_return),
                              label: const Text('Return Items'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade600,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Close'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade300,
                                foregroundColor: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }
}
