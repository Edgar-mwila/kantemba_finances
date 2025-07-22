import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/receivables_provider.dart';
import '../models/receivable.dart';
// Import a new widget for adding/editing receivables
import './new_receivable_modal.dart';
import '../screens/receivable_detail_screen.dart';

class ReceivableList extends StatelessWidget {
  const ReceivableList({super.key});

  @override
  Widget build(BuildContext context) {
    final receivablesProvider = Provider.of<ReceivablesProvider>(context);
    final receivables = receivablesProvider.receivables;

    return Scaffold(
      body: receivables.isEmpty
          ? const Center(child: Text('No receivables found.'))
          : ListView.builder(
              itemCount: receivables.length,
              itemBuilder: (ctx, i) {
                final receivable = receivables[i];
                return ListTile(
                  title: Text(receivable.name),
                  subtitle: Text('Amount: \$${receivable.principal.toStringAsFixed(2)}'),
                  trailing: Text('Due: ${receivable.dueDate.toLocal().toString().split(' ')[0]}'),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ReceivableDetailScreen(receivable: receivable),
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
            builder: (_) => const NewReceivableModal(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} 