import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../utils/currency_formatter.dart';
import '../widgets/app_text_field.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const List<String> _categories = <String>[
    'Food/Canteen',
    'Commute/Transportation',
    'Tuition/School Fees',
    'Books & Stationery',
    'Boarding House/Rent',
    'Entertainment/Leisure',
  ];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController(text: '3000');

  String _selectedCategory = _categories.first;
  DateTime _selectedDate = DateTime.now();
  double _monthlyBudget = 3000;
  double _dailyBudget = 100;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _remarksController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  double _totalExpenses(List<Expense> expenses) {
    return expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
  }

  Map<String, double> _categoryTotals(List<Expense> expenses) {
    final Map<String, double> totals = <String, double>{};
    for (final expense in expenses) {
      totals.update(expense.category, (value) => value + expense.amount, ifAbsent: () => expense.amount);
    }
    return totals;
  }

  Future<void> _openExpenseForm({Expense? expense}) async {
    if (expense != null) {
      _titleController.text = expense.title;
      _amountController.text = expense.amount.toStringAsFixed(2);
      _remarksController.text = expense.remarks ?? '';
      _selectedCategory = expense.category;
      _selectedDate = expense.date;
    } else {
      _titleController.clear();
      _amountController.clear();
      _remarksController.clear();
      _selectedCategory = _categories.first;
      _selectedDate = DateTime.now();
    }

    final formKey = GlobalKey<FormState>();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        expense == null ? 'Add Expense' : 'Edit Expense',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _titleController,
                        label: 'Title',
                        prefixIcon: Icons.receipt_long,
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Title is required.' : null,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _amountController,
                        label: 'Amount',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.payments_outlined,
                        validator: (value) {
                          final amount = double.tryParse(value ?? '');
                          if (amount == null || amount <= 0) {
                            return 'Enter a valid amount.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: _categories
                            .map(
                              (category) => DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setModalState(() {
                            _selectedCategory = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Date',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_month_outlined),
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (pickedDate != null) {
                                setModalState(() {
                                  _selectedDate = pickedDate;
                                });
                              }
                            },
                          ),
                        ),
                        controller: TextEditingController(
                          text: MaterialLocalizations.of(context).formatShortDate(_selectedDate),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _remarksController,
                        label: 'Remarks',
                        prefixIcon: Icons.notes,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          final expenseProvider = context.read<ExpenseProvider>();
                          final authProvider = context.read<AuthProvider>();
                          final message = expense == null
                              ? await expenseProvider.addExpense(
                                  userId: authProvider.currentUser!.uid,
                                  title: _titleController.text.trim(),
                                  amount: double.parse(_amountController.text),
                                  category: _selectedCategory,
                                  date: _selectedDate,
                                  remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
                                )
                              : await expenseProvider.updateExpense(
                                  Expense(
                                    id: expense.id,
                                    userId: expense.userId,
                                    title: _titleController.text.trim(),
                                    amount: double.parse(_amountController.text),
                                    category: _selectedCategory,
                                    date: _selectedDate,
                                    remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
                                  ),
                                );

                          if (!context.mounted) {
                            return;
                          }

                          if (message != null) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                            return;
                          }

                          Navigator.of(context).pop(true);
                        },
                        child: Text(expense == null ? 'Save Expense' : 'Update Expense'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result == true) {
      setState(() {});
    }
  }

  Future<void> _openBudgetDialog() async {
    _budgetController.text = _monthlyBudget.toStringAsFixed(0);
    final accepted = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final formKey = GlobalKey<FormState>();
        return AlertDialog(
          title: const Text('Set Monthly Budget'),
          content: Form(
            key: formKey,
            child: AppTextField(
              controller: _budgetController,
              label: 'Monthly Budget',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.account_balance_wallet_outlined,
              validator: (value) {
                final budget = double.tryParse(value ?? '');
                if (budget == null || budget <= 0) {
                  return 'Enter a valid budget.';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }
                Navigator.of(context).pop(true);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (accepted == true) {
      setState(() {
        _monthlyBudget = double.parse(_budgetController.text);
        _dailyBudget = _monthlyBudget / 30;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final expenseProvider = context.read<ExpenseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            onPressed: _openBudgetDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: authProvider.signOut,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openExpenseForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
      body: StreamBuilder<List<Expense>>(
        stream: expenseProvider.watchExpenses(authProvider.currentUser!.uid),
        builder: (BuildContext context, AsyncSnapshot<List<Expense>> snapshot) {
          final expenses = snapshot.data ?? <Expense>[];
          final totalExpenses = _totalExpenses(expenses);
          final remainingBudget = math.max(0.0, _monthlyBudget - totalExpenses); // Changed 0 to 0.0
          final dailyRemaining = math.max(0.0, _dailyBudget - (totalExpenses / 30)); // Changed 0 to 0.0
          final categoryTotals = _categoryTotals(expenses);

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryCard(
                  monthlyBudget: _monthlyBudget,
                  totalExpenses: totalExpenses,
                  monthlyRemaining: remainingBudget,
                  dailyBudget: _dailyBudget,
                  dailyRemaining: dailyRemaining,
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Category Breakdown',
                  child: SizedBox(
                    height: 220,
                    child: expenses.isEmpty
                        ? const Center(child: Text('No expenses yet.'))
                        : PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 42,
                              sections: categoryTotals.entries.map((entry) {
                                final index = _categories.indexOf(entry.key).clamp(0, _categories.length - 1);
                                return PieChartSectionData(
                                  value: entry.value,
                                  title: '${(entry.value / totalExpenses * 100).toStringAsFixed(0)}%',
                                  color: Colors.primaries[index * 2 % Colors.primaries.length],
                                  radius: 60,
                                  titleStyle: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Recent Transactions',
                  child: expenses.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: Text('Start by adding your first expense.')),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: expenses.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (BuildContext context, int index) {
                            final expense = expenses[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                child: Text(expense.category.characters.first),
                              ),
                              title: Text(expense.title),
                              subtitle: Text('${expense.category} • ${MaterialLocalizations.of(context).formatShortDate(expense.date)}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    phpCurrencyFormatter.format(expense.amount),
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (String value) async {
                                      if (value == 'edit') {
                                        await _openExpenseForm(expense: expense);
                                      }
                                      if (value == 'delete') {
                                        await expenseProvider.deleteExpense(
                                          userId: authProvider.currentUser!.uid,
                                          expenseId: expense.id,
                                        );
                                      }
                                    },
                                    itemBuilder: (BuildContext context) => const [
                                      PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
                                      PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.monthlyBudget,
    required this.totalExpenses,
    required this.monthlyRemaining,
    required this.dailyBudget,
    required this.dailyRemaining,
  });

  final double monthlyBudget;
  final double totalExpenses;
  final double monthlyRemaining;
  final double dailyBudget;
  final double dailyRemaining;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Budget Overview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricBox(label: 'Monthly Budget', value: phpCurrencyFormatter.format(monthlyBudget)),
              _MetricBox(label: 'Total Expenses', value: phpCurrencyFormatter.format(totalExpenses)),
              _MetricBox(label: 'Remaining Month', value: phpCurrencyFormatter.format(monthlyRemaining)),
              _MetricBox(label: 'Daily Budget', value: phpCurrencyFormatter.format(dailyBudget)),
              _MetricBox(label: 'Remaining Day', value: phpCurrencyFormatter.format(dailyRemaining)),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: monthlyBudget == 0 ? 0 : (totalExpenses / monthlyBudget).clamp(0, 1),
            minHeight: 10,
            borderRadius: BorderRadius.circular(99),
          ),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}