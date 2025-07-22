import 'dart:convert';

class Payable {
  final String id;
  final String name;
  final String contact;
  final String? address;
  final double principal;
  final String interestType;
  final double interestValue;
  final DateTime dueDate;
  final String paymentPlan;
  final List<PayablePayment> paymentHistory;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Payable({
    required this.id,
    required this.name,
    required this.contact,
    this.address,
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

  factory Payable.fromJson(Map<String, dynamic> json) => Payable(
    id: json['id'],
    name: json['name'],
    contact: json['contact'],
    address: json['address'],
    principal: (json['principal'] as num).toDouble(),
    interestType: json['interestType'],
    interestValue: (json['interestValue'] as num).toDouble(),
    dueDate: DateTime.parse(json['dueDate']),
    paymentPlan: json['paymentPlan'],
    paymentHistory: (json['paymentHistory'] as List<dynamic>?)?.map((e) => PayablePayment.fromJson(e)).toList() ?? [],
    status: json['status'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'contact': contact,
    'address': address,
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

class PayablePayment {
  final double amount;
  final DateTime date;
  final String method;
  PayablePayment({required this.amount, required this.date, required this.method});

  factory PayablePayment.fromJson(Map<String, dynamic> json) => PayablePayment(
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