import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/payable.dart';
import '../providers/payables_provider.dart';

class NewPayableModal extends StatefulWidget {
  final Payable? payable;
  const NewPayableModal({super.key, this.payable});

  @override
  _NewPayableModalState createState() => _NewPayableModalState();
}

class _NewPayableModalState extends State<NewPayableModal> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _contact;
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
        widget.payable?.dueDate ?? DateTime.now().add(const Duration(days: 30));
    _interestType = widget.payable?.interestType ?? 'fixed';
    _interestValue = widget.payable?.interestValue ?? 0.0;
    _paymentPlan = widget.payable?.paymentPlan ?? 'lump_sum';
  }

  void _submit() {
    setState(() {
      _isProcessing = true;
    });
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newPayable = Payable(
        id: widget.payable?.id ?? DateTime.now().toString(),
        name: _name,
        contact: _contact,
        principal: _principal,
        dueDate: _dueDate,
        interestType: _interestType,
        interestValue: _interestValue,
        paymentPlan: _paymentPlan,
        paymentHistory: widget.payable?.paymentHistory ?? [],
        status: widget.payable?.status ?? 'active',
        createdAt: widget.payable?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.payable == null) {
        Provider.of<PayablesProvider>(
          context,
          listen: false,
        ).addPayable(newPayable);
      } else {
        Provider.of<PayablesProvider>(
          context,
          listen: false,
        ).updatePayable(newPayable.id, newPayable);
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
                initialValue: widget.payable?.name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator:
                    (value) => value!.isEmpty ? 'Please enter a name.' : null,
                onSaved: (value) => _name = value!,
              ),
              TextFormField(
                initialValue: widget.payable?.contact,
                decoration: const InputDecoration(labelText: 'Contact'),
                validator:
                    (value) =>
                        value!.isEmpty ? 'Please enter a contact.' : null,
                onSaved: (value) => _contact = value!,
              ),
              TextFormField(
                initialValue: widget.payable?.principal.toString(),
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
                initialValue: widget.payable?.interestValue.toString(),
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
                            widget.payable == null
                                ? 'Add Payable'
                                : 'Update Payable',
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
