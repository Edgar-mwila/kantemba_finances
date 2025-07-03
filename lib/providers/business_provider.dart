import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:kantemba_finances/helpers/api_service.dart';

class BusinessProvider with ChangeNotifier {
  String? id;
  String? businessName;
  String? street;
  String? township;
  String? city;
  String? province;
  String? country;
  String? businessContact;
  String? ownerName;
  String? ownerContact;
  bool isPremium = false;

  Future<bool> isBusinessSetup() async {
    if (id != null) {
      return true;
    }
    return false;
  }

  Future<String> createBusiness({
    required String name,
    required String street,
    required String township,
    required String city,
    required String province,
    required String country,
    required String businessContact,
    required String ownerName,
    required String ownerContact,
    bool isPremium = false,
  }) async {
    businessName = name;
    this.street = street;
    this.township = township;
    this.city = city;
    this.province = province;
    this.country = country;
    this.businessContact = businessContact;
    this.ownerName = ownerName;
    this.ownerContact = ownerContact;
    this.isPremium = isPremium;

    String id =
        '${name}_${ownerName.substring(0, 2)}_${DateTime.now().millisecondsSinceEpoch}';

    await ApiService.post('business', {
      'id': id,
      'name': name,
      'street': street,
      'township': township,
      'city': city,
      'province': province,
      'country': country,
      'businessContact': businessContact,
      'ownerName': ownerName,
      'ownerContact': ownerContact,
      'isPremium': isPremium ? 1 : 0,
    });
    notifyListeners();
    return id;
  }

  Future<void> setBusiness(String businessId) async {
    final response = await ApiService.get("business/$businessId");
    if (response.statusCode == 200) {
      final businessData = json.decode(response.body);
      id = businessData['id'];
      businessName = businessData['name'];
      street = businessData['street'];
      township = businessData['township'];
      city = businessData['city'];
      province = businessData['province'];
      country = businessData['country'];
      businessContact = businessData['businessContact'];
      ownerName = businessData['ownerName'];
      ownerContact = businessData['ownerContact'];
      isPremium = (businessData['isPremium'] ?? 0) == 1;
    }
  }
}
