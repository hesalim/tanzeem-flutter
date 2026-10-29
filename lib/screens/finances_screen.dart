import 'package:flutter/material.dart';

import '../utils/currency_formatter.dart';
import '../auth/auth_session.dart';
import 'edit_expense_screen.dart';
import '../config/api_config.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/expense.dart';
import 'add_expense_screen.dart';

class FinancesScreen extends StatefulWidget {
  const FinancesScreen({super.key});

  @override
  State<FinancesScreen> createState() => _FinancesScreenState();
}

class _FinancesScreenState extends State<FinancesScreen> {
  static const Color tanzeemGreen = Color(0xFF0B5F4A);
  static const Color tanzeemDarkGreen = Color(0xFF073B31);
  static const Color tanzeemMint = Color(0xFFE4F5EF);
  static const Color tanzeemBackground = Color(0xFFF7F9F8);
  static const Color tanzeemText = Color(0xFF18221F);
  static const Color tanzeemMuted = Color(0xFF6F7D77);

  double revenue = 0;
  double expenses = 0;
  double profit = 0;

  String selectedPeriod = 'month';

  int completedAppointments = 0;

  bool isLoading = true;

  final List<Expense> expenseList = [];

  @override
  void initState() {
    super.initState();
    loadFinances();
  }

  Future<void> loadFinances() async {
    try {
      final responses = await Future.wait([
        http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/finances?period=$selectedPeriod'),
          headers: {'Authorization': 'Bearer ${AuthSession.token}'},
        ),
        http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/expenses?period=$selectedPeriod'),
          headers: {'Authorization': 'Bearer ${AuthSession.token}'},
        ),
      ]);

      final financeResponse = responses[0];
      final expensesResponse = responses[1];

      if (financeResponse.statusCode == 200 &&
          expensesResponse.statusCode == 200) {
        final financeData = jsonDecode(financeResponse.body);

        final List<dynamic> expenseData = jsonDecode(expensesResponse.body);

        final loadedExpenses = expenseData.map((item) {
          return Expense(
            id: item['id'],
            title: item['title'],
            amount: double.parse(item['amount'].toString()),
            category: item['category'],
            expenseDate: DateTime.parse(item['expense_date'].toString()),
            notes: item['notes'],
          );
        }).toList();

        if (!mounted) return;

        setState(() {
          revenue = double.parse(financeData['revenue'].toString());

          expenses = double.parse(financeData['expenses'].toString());

          profit = double.parse(financeData['profit'].toString());

          completedAppointments = financeData['completedAppointments'];

          expenseList.clear();
          expenseList.addAll(loadedExpenses);

          isLoading = false;
        });
      } else {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      print('Finance loading error: $error');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> addExpense() async {
    final Expense? expense = await Navigator.push<Expense>(
      context,
      MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
    );

    if (expense != null) {
      await loadFinances();
    }
  }

  String formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget buildSmallStatCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8ECEA)),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Container(
              width: 36,
              height: 36,

              decoration: BoxDecoration(
                color: tanzeemMint,
                borderRadius: BorderRadius.circular(11),
              ),

              child: Icon(icon, color: tanzeemGreen, size: 19),
            ),

            const SizedBox(height: 13),

            Text(
              title,
              style: const TextStyle(fontSize: 11, color: tanzeemMuted),
            ),

            const SizedBox(height: 3),

            Text(
              value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: tanzeemText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildExpenseCard(Expense expense) {
    return InkWell(
      onTap: () async {
        final updatedExpense = await Navigator.push<Expense>(
          context,
          MaterialPageRoute(
            builder: (context) => EditExpenseScreen(expense: expense),
          ),
        );

        if (updatedExpense != null) {
          await loadFinances();
        }
      },

      borderRadius: BorderRadius.circular(16),

      child: Container(
        padding: const EdgeInsets.all(14),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8ECEA)),
        ),

        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,

              decoration: BoxDecoration(
                color: const Color(0xFFFFF2DB),
                borderRadius: BorderRadius.circular(13),
              ),

              child: const Icon(
                Icons.receipt_long_outlined,
                color: Color(0xFFB26A15),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    expense.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: tanzeemText,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    expense.category != null
                        ? '${expense.category} • ${formatDate(expense.expenseDate)}'
                        : formatDate(expense.expenseDate),

                    style: const TextStyle(fontSize: 11, color: tanzeemMuted),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            Text(
              '-${CurrencyFormatter.usd(expense.amount)}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFFC53B3B),
                fontSize: 14,
              ),
            ),

            const SizedBox(width: 4),

            const Icon(
              Icons.chevron_right_rounded,
              color: tanzeemMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPeriodButton({required String label, required String value}) {
    final bool selected = selectedPeriod == value;

    return GestureDetector(
      onTap: () async {
        if (selectedPeriod == value) {
          return;
        }

        setState(() {
          selectedPeriod = value;
          isLoading = true;
        });

        await loadFinances();
      },

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),

        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),

        decoration: BoxDecoration(
          color: selected ? tanzeemGreen : Colors.white,

          borderRadius: BorderRadius.circular(20),

          border: Border.all(
            color: selected ? tanzeemGreen : const Color(0xFFE8ECEA),
          ),
        ),

        child: Text(
          label,

          style: TextStyle(
            color: selected ? Colors.white : tanzeemMuted,

            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tanzeemBackground,

      body: SafeArea(
        child: RefreshIndicator(
          color: tanzeemGreen,
          onRefresh: loadFinances,

          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: tanzeemGreen),
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),

                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),

                  children: [
                    const Text(
                      'Finances',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                        color: tanzeemText,
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'Track your business performance',
                      style: TextStyle(fontSize: 13, color: tanzeemMuted),
                    ),

                    const SizedBox(height: 18),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          buildPeriodButton(label: 'Today', value: 'today'),

                          const SizedBox(width: 8),

                          buildPeriodButton(label: 'This Week', value: 'week'),

                          const SizedBox(width: 8),

                          buildPeriodButton(
                            label: 'This Month',
                            value: 'month',
                          ),

                          const SizedBox(width: 8),

                          buildPeriodButton(label: 'All Time', value: 'all'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: tanzeemDarkGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Revenue',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            CurrencyFormatter.usd(revenue),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 7),

                          Text(
                            '$completedAppointments completed appointment${completedAppointments == 1 ? '' : 's'}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.70),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        buildSmallStatCard(
                          title: 'Expenses',
                          value: CurrencyFormatter.usd(expenses),
                          icon: Icons.receipt_long_outlined,
                        ),

                        const SizedBox(width: 10),

                        buildSmallStatCard(
                          title: 'Net Profit',
                          value: CurrencyFormatter.usd(profit),
                          icon: Icons.trending_up_rounded,
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Recent Expenses',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: tanzeemText,
                            ),
                          ),
                        ),

                        TextButton.icon(
                          onPressed: addExpense,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add'),
                          style: TextButton.styleFrom(
                            foregroundColor: tanzeemGreen,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    if (expenseList.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE8ECEA)),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 34,
                              color: tanzeemMuted,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'No expenses yet',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: tanzeemText,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Add your business expenses to calculate profit.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: tanzeemMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...expenseList.map(
                        (expense) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: buildExpenseCard(expense),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
