import 'package:flutter/foundation.dart';
import 'package:kantemba_finances/helpers/db_helper.dart';

class BusinessProvider with ChangeNotifier {
  String? businessName;
  bool isMultiShop = false;
  bool isVatRegistered = false;
  bool isTurnoverTaxApplicable = false;

  Future<bool> isBusinessSetup() async {
    final data = await DBHelper.getData('business');
    if (data.isNotEmpty) {
      final businessData = data.first;
      businessName = businessData['name'];
      isMultiShop = businessData['isMultiShop'] == 1;
      isVatRegistered = businessData['isVatRegistered'] == 1;
      isTurnoverTaxApplicable = businessData['isTurnoverTaxApplicable'] == 1;
      return true;
    }
    return false;
  }

  Future<void> setupBusiness({
    required String name,
    required bool multiShop,
    required bool vatRegistered,
    required bool turnoverTaxApplicable,
  }) async {
    businessName = name;
    isMultiShop = multiShop;
    isVatRegistered = vatRegistered;
    isTurnoverTaxApplicable = turnoverTaxApplicable;
    
    await DBHelper.insert('business', {
      'id': 'main_business',
      'name': name,
      'isMultiShop': multiShop ? 1 : 0,
      'isVatRegistered': vatRegistered ? 1 : 0,
      'isTurnoverTaxApplicable': turnoverTaxApplicable ? 1 : 0,
    });
    notifyListeners();
  }
} 