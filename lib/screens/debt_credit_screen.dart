import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/receivables_provider.dart';
import '../providers/payables_provider.dart';
import '../providers/loans_provider.dart';

import '../widgets/receivable_list.dart';
import '../widgets/payable_list.dart';
import '../widgets/loan_list.dart';

class DebtAndCreditScreen extends StatefulWidget {
  const DebtAndCreditScreen({super.key});

  @override
  _DebtAndCreditScreenState createState() => _DebtAndCreditScreenState();
}

class _DebtAndCreditScreenState extends State<DebtAndCreditScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Fetch initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReceivablesProvider>(
        context,
        listen: false,
      ).fetchReceivables();
      Provider.of<PayablesProvider>(context, listen: false).fetchPayables();
      Provider.of<LoansProvider>(context, listen: false).fetchLoans();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt & Credit Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Receivables'),
            Tab(text: 'Payables'),
            Tab(text: 'Loans'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [ReceivableList(), PayableList(), LoanList()],
      ),
    );
  }
}
