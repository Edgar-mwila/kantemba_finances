import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/loans_provider.dart';
import './new_loan_modal.dart';
import '../screens/loan_detail_screen.dart';

class LoanList extends StatelessWidget {
  const LoanList({super.key});

  @override
  Widget build(BuildContext context) {
    final loansProvider = Provider.of<LoansProvider>(context);
    final loans = loansProvider.loans;

    return Scaffold(
      body:
          loans.isEmpty
              ? const Center(child: Text('No loans found.'))
              : ListView.builder(
                itemCount: loans.length,
                itemBuilder: (ctx, i) {
                  final loan = loans[i];
                  return ListTile(
                    title: Text(loan.lenderName),
                    subtitle: Text(
                      'Amount: \$${loan.principal.toStringAsFixed(2)}',
                    ),
                    trailing: Text(
                      'Due: ${loan.dueDate.toLocal().toString().split(' ')[0]}',
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => LoanDetailScreen(loan: loan),
                        ),
                      );
                    },
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => const NewLoanModal(),
          );
        },
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
