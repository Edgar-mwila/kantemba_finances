import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:kantemba_finances/helpers/api_service.dart';
import 'package:kantemba_finances/helpers/db_helper.dart';

class BusinessProvider with ChangeNotifier {
  String? id;
  String? businessName;
  // String? street;
  // String? township;
  // String? city;
  // String? province;
  String? country;
  String? businessContact;
  String? adminName;
  String? adminContact;
  bool isPremium = false;
  String? subscriptionType;
  DateTime? subscriptionStartDate = DateTime.now();
  DateTime? subscriptionExpiryDate = DateTime.now().add(
    const Duration(days: 30),
  );
  bool trialUsed = false;
  String? lastPaymentTxRef;

  Future<bool> isBusinessSetup() async {
    if (id != null) {
      return true;
    }
    return false;
  }

  Future<String> createBusiness({
    required String name,
    required String businessContact,
    required String adminName,
    required String adminContact,
    bool isPremium = false,
  }) async {
    businessName = name;
    this.country = 'Zambia'; // Fixed to Zambia
    this.businessContact = businessContact;
    this.adminName = adminName;
    this.adminContact = adminContact;
    this.isPremium = isPremium;

    String id =
        '${name}_${adminName.substring(0, 2)}_${DateTime.now().millisecondsSinceEpoch}';
    this.id = id;
    if (!isPremium || !(await ApiService.isOnline())) {
      await DBHelper.insert('businesses', {
        'id': id,
        'name': name,
        'country': 'Zambia',
        'businessContact': businessContact,
        'adminName': adminName,
        'adminContact': adminContact,
        'isPremium': isPremium ? 1 : 0,
        'synced': 0,
      });
      notifyListeners();
      return id;
    }
    await ApiService.post('business', {
      'id': id,
      'name': name,
      'country': 'Zambia',
      'businessContact': businessContact,
      'adminName': adminName,
      'adminContact': adminContact,
      'isPremium': isPremium ? 1 : 0,
    });
    notifyListeners();
    return id;
  }

  Future<void> setBusiness(String businessId) async {
    if (!isPremium || !(await ApiService.isOnline())) {
      final localBusiness = await DBHelper.getData('businesses');
      if (localBusiness.isEmpty) return;
      final businessData = localBusiness.firstWhere(
        (b) => b['id'] == businessId,
        orElse: () => localBusiness.first,
      );
      id = businessData['id'];
      businessName = businessData['name'];
      country = businessData['country'];
      businessContact = businessData['businessContact'];
      adminName = businessData['adminName'];
      adminContact = businessData['adminContact'];
      isPremium =
          businessData['isPremium'] == true ||
          businessData['isPremium'] == 1 ||
          businessData['isPremium'] == '1' ||
          businessData['isPremium'].toString().toLowerCase() == 'true';
      notifyListeners();
      return;
    }
    final response = await ApiService.get("business/$businessId");
    if (response.statusCode == 200) {
      final businessData = json.decode(response.body);
      id = businessData['id'];
      businessName = businessData['name'];
      country = businessData['country'];
      businessContact = businessData['businessContact'];
      adminName = businessData['adminName'];
      adminContact = businessData['adminContact'];
      final premiumValue = businessData['isPremium'];
      if (premiumValue is bool) {
        isPremium = premiumValue;
      } else if (premiumValue is int) {
        isPremium = premiumValue == 1;
      } else if (premiumValue is String) {
        isPremium = premiumValue == '1' || premiumValue.toLowerCase() == 'true';
      } else {
        isPremium = false;
      }
      notifyListeners();
    }
  }

  Future<void> fetchAndSetBusinessHybrid(String businessId) async {
    if (!isPremium) {
      final localBusiness = await DBHelper.getData('business');
      if (localBusiness.isEmpty) {
        // If no local business data, return early
        return;
      }
      final businessData = localBusiness.first;
      id = businessData['id'];
      businessName = businessData['name'];
      // street = businessData['street'];
      // township = businessData['township'];
      // city = businessData['city'];
      // province = businessData['province'];
      country = businessData['country'];
      businessContact = businessData['businessContact'];
      adminName = businessData['adminName'];
      adminContact = businessData['adminContact'];
      // Handle different possible types for isPremium
      final premiumValue = businessData['isPremium'];
      if (premiumValue is bool) {
        isPremium = premiumValue;
      } else if (premiumValue is int) {
        isPremium = premiumValue == 1;
      } else if (premiumValue is String) {
        isPremium = premiumValue == '1' || premiumValue.toLowerCase() == 'true';
      } else {
        isPremium = false;
      }
      notifyListeners();
      return;
    }
    if (await ApiService.isOnline()) {
      await setBusiness(businessId);
      // Optionally, update local DB with latest online data
    } else {
      final localBusiness = await DBHelper.getData('business');
      if (localBusiness.isEmpty) {
        // If no local business data, return early
        return;
      }
      final businessData = localBusiness.first;
      id = businessData['id'];
      businessName = businessData['name'];
      // street = businessData['street'];
      // township = businessData['township'];
      // city = businessData['city'];
      // province = businessData['province'];
      country = businessData['country'];
      businessContact = businessData['businessContact'];
      adminName = businessData['adminName'];
      adminContact = businessData['adminContact'];
      // Handle different possible types for isPremium
      final premiumValue = businessData['isPremium'];
      if (premiumValue is bool) {
        isPremium = premiumValue;
      } else if (premiumValue is int) {
        isPremium = premiumValue == 1;
      } else if (premiumValue is String) {
        isPremium = premiumValue == '1' || premiumValue.toLowerCase() == 'true';
      } else {
        isPremium = false;
      }
      notifyListeners();
    }
  }

  Future<void> updateBusinessHybrid(BusinessProvider business) async {
    if (business.id == null) {
      throw Exception('Business ID cannot be null');
    }
    if (!isPremium || !(await ApiService.isOnline())) {
      await DBHelper.update('businesses', {
        'id': business.id ?? '',
        'name': business.businessName ?? '',
        'country': business.country ?? '',
        'businessContact': business.businessContact ?? '',
        'adminName': business.adminName ?? '',
        'adminContact': business.adminContact ?? '',
        'isPremium': business.isPremium,
        'synced': 0,
      }, business.id!);
      notifyListeners();
      return;
    }
    await updateBusiness(business);
  }

  Future<void> updateBusiness(BusinessProvider business) async {
    final response = await ApiService.put('business/${business.id}', {
      'name': business.businessName,
      // 'street': business.street,
      // 'township': business.township,
      // 'city': business.city,
      // 'province': business.province,
      'country': business.country,
      'businessContact': business.businessContact,
      'adminName': business.adminName,
      'adminContact': business.adminContact,
      'isPremium': business.isPremium,
    });
    if (response.statusCode == 200) {
      await setBusiness(business.id!);
    }
  }

  Future<void> syncBusinessToBackend({bool batch = false}) async {
    if (batch) return; // Handled by SyncManager
    if (!isPremium || !(await ApiService.isOnline())) return;
    final unsynced = await DBHelper.getUnsyncedData('business');
    for (final business in unsynced) {
      // ...send to backend via ApiService...
      await DBHelper.markAsSynced('business', business['id']);
    }
  }
}
