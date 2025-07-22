import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/receivable.dart';
import '../helpers/db_helper.dart';

class ReceivablesProvider with ChangeNotifier {
  List<Receivable> _receivables = [];
  List<Receivable> get receivables => _receivables;

  Future<void> fetchReceivables() async {
    final data = await DBHelper.getReceivables();
    _receivables = data.map((e) => Receivable.fromJson({
      ...e,
      'paymentHistory': jsonDecode(e['paymentHistory'] ?? '[]'),
    })).toList();
    notifyListeners();
  }

  Future<void> addReceivable(Receivable receivable) async {
    await DBHelper.insertReceivable({
      ...receivable.toJson(),
      'paymentHistory': jsonEncode(receivable.paymentHistory.map((e) => e.toJson()).toList()),
    });
    await fetchReceivables();
  }

  Future<void> updateReceivable(String id, Receivable receivable) async {
    await DBHelper.updateReceivable(id, {
      ...receivable.toJson(),
      'paymentHistory': jsonEncode(receivable.paymentHistory.map((e) => e.toJson()).toList()),
    });
    await fetchReceivables();
  }

  Future<void> deleteReceivable(String id) async {
    await DBHelper.deleteReceivable(id);
    await fetchReceivables();
  }

  Future<void> addPaymentToReceivable(String id, ReceivablePayment payment) async {
    final receivable = _receivables.firstWhere((r) => r.id == id);
    final updated = Receivable(
      id: receivable.id,
      name: receivable.name,
      contact: receivable.contact,
      address: receivable.address,
      principal: receivable.principal,
      interestType: receivable.interestType,
      interestValue: receivable.interestValue,
      dueDate: receivable.dueDate,
      paymentPlan: receivable.paymentPlan,
      paymentHistory: [...receivable.paymentHistory, payment],
      status: receivable.status,
      createdAt: receivable.createdAt,
      updatedAt: DateTime.now(),
    );
    await updateReceivable(id, updated);
  }
} 