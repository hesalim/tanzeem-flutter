import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../auth/auth_session.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/expense.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  static const Color tanzeemGreen = Color(0xFF0B5F4A);
  static const Color tanzeemBackground = Color(0xFFF7F9F8);
  static const Color tanzeemText = Color(0xFF18221F);
  static const Color tanzeemMuted = Color(0xFF6F7D77);

  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  DateTime selectedDate = DateTime.now();

  bool isSaving = false;

  Future<void> selectDate() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
  }

  Future<void> saveExpense() async {
    final amount = double.tryParse(amountController.text.trim());

    if (titleController.text.trim().isEmpty || amount == null || amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid title and amount')),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final formattedDate =
          '${selectedDate.year}-'
          '${selectedDate.month.toString().padLeft(2, '0')}-'
          '${selectedDate.day.toString().padLeft(2, '0')}';

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/expenses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthSession.token}',
        },
        body: jsonEncode({
          'title': titleController.text.trim(),
          'amount': amount,
          'category': categoryController.text.trim().isEmpty
              ? null
              : categoryController.text.trim(),
          'expenseDate': formattedDate,
          'notes': notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);

        final expense = Expense(
          id: data['expenseId'],
          title: titleController.text.trim(),
          amount: amount,
          category: categoryController.text.trim().isEmpty
              ? null
              : categoryController.text.trim(),
          expenseDate: selectedDate,
          notes: notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
        );

        if (!mounted) return;

        Navigator.pop(context, expense);
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to save expense')));
      }
    } catch (error) {
      print(error);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not connect to the server')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  InputDecoration inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,

      prefixIcon: Icon(icon, color: tanzeemMuted),

      filled: true,
      fillColor: Colors.white,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE8ECEA)),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE8ECEA)),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: tanzeemGreen, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tanzeemBackground,

      appBar: AppBar(
        backgroundColor: tanzeemBackground,
        elevation: 0,
        surfaceTintColor: tanzeemBackground,

        title: const Text(
          'Add Expense',
          style: TextStyle(color: tanzeemText, fontWeight: FontWeight.w700),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),

        children: [
          const Text(
            'Expense details',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: tanzeemText,
            ),
          ),

          const SizedBox(height: 10),

          TextField(
            controller: titleController,
            decoration: inputDecoration(
              label: 'Title',
              icon: Icons.receipt_long_outlined,
              hint: 'Example: Hair products',
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: inputDecoration(
              label: 'Amount (\$)',
              icon: Icons.payments_outlined,
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: categoryController,
            decoration: inputDecoration(
              label: 'Category',
              icon: Icons.category_outlined,
              hint: 'Optional',
            ),
          ),

          const SizedBox(height: 14),

          InkWell(
            onTap: selectDate,
            borderRadius: BorderRadius.circular(16),

            child: Container(
              padding: const EdgeInsets.all(15),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8ECEA)),
              ),

              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: tanzeemMuted,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        const Text(
                          'Expense date',
                          style: TextStyle(fontSize: 11, color: tanzeemMuted),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: tanzeemText,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(Icons.chevron_right_rounded, color: tanzeemMuted),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: notesController,
            maxLines: 4,
            decoration: inputDecoration(
              label: 'Notes',
              icon: Icons.notes_rounded,
              hint: 'Optional',
            ),
          ),

          const SizedBox(height: 28),

          SizedBox(
            height: 54,

            child: ElevatedButton(
              onPressed: isSaving ? null : saveExpense,

              style: ElevatedButton.styleFrom(
                backgroundColor: tanzeemGreen,
                foregroundColor: Colors.white,
                elevation: 0,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),

              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,

                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Expense',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
