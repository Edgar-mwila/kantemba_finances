import 'package:flutter/material.dart';
import '../models/shop.dart';
import '../helpers/api_service.dart';
import 'dart:convert';
import 'package:kantemba_finances/helpers/db_helper.dart';
import 'package:kantemba_finances/providers/business_provider.dart';

class ShopProvider with ChangeNotifier {
  List<Shop> _shops = [];
  Shop? _currentShop;

  List<Shop> get shops => _shops;
  Shop? get currentShop => _currentShop;

  Future<void> fetchShops(String businessId, {List<String>? shopIds}) async {
    // Check if online and if business is premium
    bool isOnline = await ApiService.isOnline();
    final businessProvider = BusinessProvider();
    bool isPremium = businessProvider.isPremium;

    if (!isOnline || !isPremium) {
      // Offline mode or non-premium business: load from local database
      final localShops = await DBHelper.getData('shops');
      _shops = localShops.map((json) => Shop.fromJson(json)).toList();
      _currentShop = _shops.isNotEmpty ? _shops.first : null;
      notifyListeners();
      return;
    }

    // Online mode and premium business: fetch from API
    if (shopIds != null && shopIds.isNotEmpty) {
      // If only one shopId, fetch that shop
      if (shopIds.length == 1) {
        final response = await ApiService.get('shops/${shopIds.first}');
        if (response.statusCode == 200 && response.body.isNotEmpty) {
          final shop = Shop.fromJson(jsonDecode(response.body));
          _shops = [shop];
        } else {
          _shops = [];
        }
        notifyListeners();
        return;
      }
      // If multiple shopIds, fetch each shop individually
      List<Shop> fetchedShops = [];
      for (String id in shopIds) {
        final response = await ApiService.get('shops/$id');
        if (response.statusCode == 200 && response.body.isNotEmpty) {
          fetchedShops.add(Shop.fromJson(jsonDecode(response.body)));
        }
      }
      _shops = fetchedShops;
      notifyListeners();
      return;
    }

    // If no shopIds provided, fetch all shops for the businessId
    final response = await ApiService.get('shops?businessId=$businessId');
    if (response.statusCode != 200) {
      // Handle error
      return;
    }
    if (response.body.isEmpty) {
      _shops = [];
      notifyListeners();
      return;
    }
    final List<dynamic> decoded = jsonDecode(response.body);
    _shops = decoded.map((json) => Shop.fromJson(json)).toList();
    notifyListeners();
  }

  void setCurrentShop(Shop? shop) {
    _currentShop = shop;
    notifyListeners();
  }

  void setShops(List<Shop> shops) {
    _shops = shops;
    notifyListeners();
  }

  Future<void> addShop(Shop shop) async {
    bool isOnline = await ApiService.isOnline();
    final businessProvider = BusinessProvider();
    bool isPremium = businessProvider.isPremium;

    if (!isOnline || !isPremium) {
      await DBHelper.insert('shops', {
        'id': shop.id,
        'name': shop.name,
        'businessId': shop.businessId,
        'synced': 0,
      });
      _shops.add(shop);
      notifyListeners();
      return;
    }
    try {
      final response = await ApiService.post('shops', {
        'id': shop.id,
        'name': shop.name,
        'businessId': shop.businessId,
      });
      if (response.statusCode == 201) {
        await fetchShops(shop.businessId);
      }
    } catch (e) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Failed to add shop. Please try again later.')),
      // );
    }
  }

  Future<void> editShop(Shop shop) async {
    final response = await ApiService.put('shops/${shop.id}', shop.toJson());
    if (response.statusCode == 200) {
      await fetchShops(shop.businessId);
    }
  }

  Future<void> deleteShop(String shopId, String businessId) async {
    final response = await ApiService.delete('shops/$shopId');
    if (response.statusCode == 204) {
      await fetchShops(businessId);
    }
  }

  Future<void> syncShopsToBackend(
    BusinessProvider businessProvider, {
    bool batch = false,
  }) async {
    if (batch) return; // Handled by SyncManager
    if (!businessProvider.isPremium || !(await ApiService.isOnline())) return;
    final unsynced = await DBHelper.getUnsyncedData('shops');
    for (final shop in unsynced) {
      // ...send to backend via ApiService...
      await DBHelper.markAsSynced('shops', shop['id']);
    }
  }
}
