import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/payables_provider.dart';
import '../models/payable.dart';
import './new_payable_modal.dart';
import '../screens/payable_detail_screen.dart';

class PayableList extends StatelessWidget {
  const PayableList({super.key});

  @override
  Widget build(BuildContext context) {
    final payablesProvider = Provider.of<PayablesProvider>(context);
    final payables = payablesProvider.payables;

    return Scaffold(
      body: payables.isEmpty
          ? const Center(child: Text('No payables found.'))
          : ListView.builder(
              itemCount: payables.length,
              itemBuilder: (ctx, i) {
                final payable = payables[i];
                return ListTile(
                  title: Text(payable.name),
                  subtitle: Text('Amount: \$${payable.principal.toStringAsFixed(2)}'),
                  trailing: Text('Due: ${payable.dueDate.toLocal().toString().split(' ')[0]}'),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => PayableDetailScreen(payable: payable),
                    ));
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => const NewPayableModal(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} 