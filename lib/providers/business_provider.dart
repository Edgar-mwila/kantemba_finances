import 'package:flutter/foundation.dart';
import 'package:kantemba_finances/helpers/api_service.dart';
import 'package:kantemba_finances/helpers/db_helper.dart';

class BusinessProvider with ChangeNotifier {
  String? id;
  String? businessName;
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
    return id != null;
  }

  Future<String> createBusiness({
    required String name,
    required String businessContact,
    required String adminName,
    required String adminContact,
    bool isPremium = true,
  }) async {
    businessName = name;
    country = 'Zambia'; // Fixed to Zambia
    this.businessContact = businessContact;
    this.adminName = adminName;
    this.adminContact = adminContact;
    this.isPremium = isPremium;

    String id =
        '${name}_${adminName.substring(0, 2)}_${DateTime.now().millisecondsSinceEpoch}';
    this.id = id;

    final businessData = {
      'id': id,
      'name': name,
      'country': 'Zambia',
      'businessContact': businessContact,
      'adminName': adminName,
      'adminContact': adminContact,
      'isPremium': isPremium ? 1 : 0,
    };

    // Always save to local DB first
    await DBHelper.insert('businesses', {...businessData, 'synced': 0});

    notifyListeners();
    return id;
  }

  Future<void> setBusiness(String businessId) async {
    // Fallback to local DB
    await _loadFromLocal(businessId);
    notifyListeners();
  }

  Future<void> _loadFromLocal(String businessId) async {
    final localBusiness = await DBHelper.getData('businesses');
    if (localBusiness.isEmpty) return;

    final businessData = localBusiness.firstWhere(
      (b) => b['id'] == businessId,
      orElse: () => localBusiness.first,
    );

    _setBusinessData(businessData);
  }

  void _setBusinessData(Map<String, dynamic> businessData) {
    id = businessData['id'];
    businessName = businessData['name'];
    country = businessData['country'];
    businessContact = businessData['businessContact'];
    adminName = businessData['adminName'];
    adminContact = businessData['adminContact'];

    // Override isPremium based on database value
    isPremium = _parsePremiumValue(businessData['isPremium']);

    notifyListeners();
  }

  bool _parsePremiumValue(dynamic premiumValue) {
    if (premiumValue is bool) return premiumValue;
    if (premiumValue is int) return premiumValue == 1;
    if (premiumValue is String) {
      return premiumValue == '1' || premiumValue.toLowerCase() == 'true';
    }
    return false;
  }

  Future<void> fetchAndSetBusinessHybrid(String businessId) async {
    // Load from local DB
    final localBusiness = await DBHelper.getData('businesses');
    if (localBusiness.isEmpty) return;

    final businessData = localBusiness.first;
    _setBusinessData(businessData);
  }

  Future<void> updateBusinessHybrid(BusinessProvider business) async {
    if (business.id == null) {
      throw Exception('Business ID cannot be null');
    }

    final businessData = {
      'id': business.id!,
      'name': business.businessName ?? '',
      'country': business.country ?? '',
      'businessContact': business.businessContact ?? '',
      'adminName': business.adminName ?? '',
      'adminContact': business.adminContact ?? '',
      'isPremium': business.isPremium ? 1 : 0,
    };

    // Always update local DB
    await DBHelper.update('businesses', {
      ...businessData,
      'synced': 0,
    }, business.id!);

    notifyListeners();
  }

  Future<void> syncBusinessToBackend({bool batch = false}) async {
    if (batch) return; // Handled by SyncManager

    final unsynced = await DBHelper.getUnsyncedData('businesses');
    for (final business in unsynced) {
      debugPrint('Syncing business: $business');
      if (business['id'] == id) {
        try {
          await ApiService.post('business/', {
            'id': business['id'],
            'name': business['name'],
            'country': business['country'],
            'businessContact': business['businessContact'],
            'adminName': business['adminName'],
            'adminContact': business['adminContact'],
            'isPremium': true,
          });
          await DBHelper.markAsSynced('businesses', business['id']);
        } catch (e) {
          debugPrint('Failed to sync business ${business['id']}: $e');
        }
      }
    }
  }
}
