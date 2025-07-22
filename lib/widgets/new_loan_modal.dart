import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/loan.dart';
import '../providers/loans_provider.dart';

class NewLoanModal extends StatefulWidget {
  final Loan? loan;
  const NewLoanModal({super.key, this.loan});

  @override
  _NewLoanModalState createState() => _NewLoanModalState();
}

class _NewLoanModalState extends State<NewLoanModal> {
  final _formKey = GlobalKey<FormState>();
  late String _lenderName;
  late String _lenderContact;
  late double _principal;
  late DateTime _dueDate;
  String _interestType = 'fixed';
  double _interestValue = 0.0;
  String _paymentPlan = 'lump_sum';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _dueDate =
        widget.loan?.dueDate ?? DateTime.now().add(const Duration(days: 30));
    _interestType = widget.loan?.interestType ?? 'fixed';
    _interestValue = widget.loan?.interestValue ?? 0.0;
    _paymentPlan = widget.loan?.paymentPlan ?? 'lump_sum';
  }

  void _submit() {
    setState(() {
      _isProcessing = true;
    });
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newLoan = Loan(
        id: widget.loan?.id ?? DateTime.now().toString(),
        lenderName: _lenderName,
        lenderContact: _lenderContact,
        principal: _principal,
        dueDate: _dueDate,
        interestType: _interestType,
        interestValue: _interestValue,
        paymentPlan: _paymentPlan,
        paymentHistory: widget.loan?.paymentHistory ?? [],
        status: widget.loan?.status ?? 'active',
        createdAt: widget.loan?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.loan == null) {
        Provider.of<LoansProvider>(context, listen: false).addLoan(newLoan);
      } else {
        Provider.of<LoansProvider>(
          context,
          listen: false,
        ).updateLoan(newLoan.id, newLoan);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: widget.loan?.lenderName,
                decoration: const InputDecoration(labelText: 'Lender Name'),
                validator:
                    (value) => value!.isEmpty ? 'Please enter a name.' : null,
                onSaved: (value) => _lenderName = value!,
              ),
              TextFormField(
                initialValue: widget.loan?.lenderContact,
                decoration: const InputDecoration(labelText: 'Lender Contact'),
                validator:
                    (value) =>
                        value!.isEmpty ? 'Please enter a contact.' : null,
                onSaved: (value) => _lenderContact = value!,
              ),
              TextFormField(
                initialValue: widget.loan?.principal.toString(),
                decoration: const InputDecoration(
                  labelText: 'Principal Amount',
                ),
                keyboardType: TextInputType.number,
                validator:
                    (value) =>
                        value!.isEmpty ? 'Please enter an amount.' : null,
                onSaved: (value) => _principal = double.parse(value!),
              ),
              DropdownButtonFormField<String>(
                value: _interestType,
                decoration: const InputDecoration(labelText: 'Interest Type'),
                items:
                    ['fixed', 'percentage'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _interestType = newValue!;
                  });
                },
              ),
              TextFormField(
                initialValue: widget.loan?.interestValue.toString(),
                decoration: const InputDecoration(labelText: 'Interest Value'),
                keyboardType: TextInputType.number,
                onSaved:
                    (value) => _interestValue = double.tryParse(value!) ?? 0.0,
              ),
              ListTile(
                title: Text("Due Date: ${DateFormat.yMd().format(_dueDate)}"),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null && picked != _dueDate) {
                    setState(() {
                      _dueDate = picked;
                    });
                  }
                },
              ),
              DropdownButtonFormField<String>(
                value: _paymentPlan,
                decoration: const InputDecoration(labelText: 'Payment Plan'),
                items:
                    ['lump_sum', 'installment'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _paymentPlan = newValue!;
                  });
                },
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _submit,
                  child:
                      _isProcessing
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Text(
                            widget.loan == null ? 'Add Loan' : 'Update Loan',
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
