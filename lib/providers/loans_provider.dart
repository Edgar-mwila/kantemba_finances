import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/loan.dart';
import '../helpers/db_helper.dart';

class LoansProvider with ChangeNotifier {
  List<Loan> _loans = [];
  List<Loan> get loans => _loans;

  Future<void> fetchLoans() async {
    final data = await DBHelper.getLoans();
    _loans = data.map((e) => Loan.fromJson({
      ...e,
      'paymentHistory': jsonDecode(e['paymentHistory'] ?? '[]'),
    })).toList();
    notifyListeners();
  }

  Future<void> addLoan(Loan loan) async {
    await DBHelper.insertLoan({
      ...loan.toJson(),
      'paymentHistory': jsonEncode(loan.paymentHistory.map((e) => e.toJson()).toList()),
    });
    await fetchLoans();
  }

  Future<void> updateLoan(String id, Loan loan) async {
    await DBHelper.updateLoan(id, {
      ...loan.toJson(),
      'paymentHistory': jsonEncode(loan.paymentHistory.map((e) => e.toJson()).toList()),
    });
    await fetchLoans();
  }

  Future<void> deleteLoan(String id) async {
    await DBHelper.deleteLoan(id);
    await fetchLoans();
  }

  Future<void> addPaymentToLoan(String id, LoanPayment payment) async {
    final loan = _loans.firstWhere((l) => l.id == id);
    final updated = Loan(
      id: loan.id,
      lenderName: loan.lenderName,
      lenderContact: loan.lenderContact,
      lenderAddress: loan.lenderAddress,
      principal: loan.principal,
      interestType: loan.interestType,
      interestValue: loan.interestValue,
      dueDate: loan.dueDate,
      paymentPlan: loan.paymentPlan,
      paymentHistory: [...loan.paymentHistory, payment],
      status: loan.status,
      createdAt: loan.createdAt,
      updatedAt: DateTime.now(),
    );
    await updateLoan(id, updated);
  }
} 