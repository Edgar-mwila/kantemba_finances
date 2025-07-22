import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/payable.dart';
import '../helpers/db_helper.dart';

class PayablesProvider with ChangeNotifier {
  List<Payable> _payables = [];
  List<Payable> get payables => _payables;

  Future<void> fetchPayables() async {
    final data = await DBHelper.getPayables();
    _payables = data.map((e) => Payable.fromJson({
      ...e,
      'paymentHistory': jsonDecode(e['paymentHistory'] ?? '[]'),
    })).toList();
    notifyListeners();
  }

  Future<void> addPayable(Payable payable) async {
    await DBHelper.insertPayable({
      ...payable.toJson(),
      'paymentHistory': jsonEncode(payable.paymentHistory.map((e) => e.toJson()).toList()),
    });
    await fetchPayables();
  }

  Future<void> updatePayable(String id, Payable payable) async {
    await DBHelper.updatePayable(id, {
      ...payable.toJson(),
      'paymentHistory': jsonEncode(payable.paymentHistory.map((e) => e.toJson()).toList()),
    });
    await fetchPayables();
  }

  Future<void> deletePayable(String id) async {
    await DBHelper.deletePayable(id);
    await fetchPayables();
  }

  Future<void> addPaymentToPayable(String id, PayablePayment payment) async {
    final payable = _payables.firstWhere((p) => p.id == id);
    final updated = Payable(
      id: payable.id,
      name: payable.name,
      contact: payable.contact,
      address: payable.address,
      principal: payable.principal,
      interestType: payable.interestType,
      interestValue: payable.interestValue,
      dueDate: payable.dueDate,
      paymentPlan: payable.paymentPlan,
      paymentHistory: [...payable.paymentHistory, payment],
      status: payable.status,
      createdAt: payable.createdAt,
      updatedAt: DateTime.now(),
    );
    await updatePayable(id, updated);
  }
} 