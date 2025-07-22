import 'dart:convert';

class Loan {
  final String id;
  final String lenderName;
  final String lenderContact;
  final String? lenderAddress;
  final double principal;
  final String interestType;
  final double interestValue;
  final DateTime dueDate;
  final String paymentPlan;
  final List<LoanPayment> paymentHistory;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Loan({
    required this.id,
    required this.lenderName,
    required this.lenderContact,
    this.lenderAddress,
    required this.principal,
    required this.interestType,
    required this.interestValue,
    required this.dueDate,
    required this.paymentPlan,
    required this.paymentHistory,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Loan.fromJson(Map<String, dynamic> json) => Loan(
    id: json['id'],
    lenderName: json['lenderName'],
    lenderContact: json['lenderContact'],
    lenderAddress: json['lenderAddress'],
    principal: (json['principal'] as num).toDouble(),
    interestType: json['interestType'],
    interestValue: (json['interestValue'] as num).toDouble(),
    dueDate: DateTime.parse(json['dueDate']),
    paymentPlan: json['paymentPlan'],
    paymentHistory: (json['paymentHistory'] as List<dynamic>?)?.map((e) => LoanPayment.fromJson(e)).toList() ?? [],
    status: json['status'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'lenderName': lenderName,
    'lenderContact': lenderContact,
    'lenderAddress': lenderAddress,
    'principal': principal,
    'interestType': interestType,
    'interestValue': interestValue,
    'dueDate': dueDate.toIso8601String(),
    'paymentPlan': paymentPlan,
    'paymentHistory': paymentHistory.map((e) => e.toJson()).toList(),
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class LoanPayment {
  final double amount;
  final DateTime date;
  final String method;
  LoanPayment({required this.amount, required this.date, required this.method});

  factory LoanPayment.fromJson(Map<String, dynamic> json) => LoanPayment(
    amount: (json['amount'] as num).toDouble(),
    date: DateTime.parse(json['date']),
    method: json['method'],
  );

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'date': date.toIso8601String(),
    'method': method,
  };
} 