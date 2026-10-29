import 'package:flutter/material.dart';

import '../auth/auth_session.dart';

import 'dart:convert';

import '../config/api_config.dart';

import 'package:http/http.dart' as http;

import '../models/expense.dart';

class EditExpenseScreen extends StatefulWidget {
  final Expense expense;

  const EditExpenseScreen({super.key, required this.expense});

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  static const Color tanzeemGreen = Color(0xFF0B5F4A);
  static const Color tanzeemBackground = Color(0xFFF7F9F8);
  static const Color tanzeemText = Color(0xFF18221F);
  static const Color tanzeemMuted = Color(0xFF6F7D77);
  static const Color danger = Color(0xFFC53B3B);

  late TextEditingController titleController;
  late TextEditingController amountController;
  late TextEditingController categoryController;
  late TextEditingController notesController;

  late DateTime selectedDate;

  bool isSaving = false;
  bool isDeleting = false;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.expense.title);

    amountController = TextEditingController(
      text: widget.expense.amount.toString(),
    );

    categoryController = TextEditingController(
      text: widget.expense.category ?? '',
    );

    notesController = TextEditingController(text: widget.expense.notes ?? '');

    selectedDate = widget.expense.expenseDate;
  }

  Future<void> selectDate() async {
    final date = await showDatePicker(
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
    if (widget.expense.id == null) {
      return;
    }

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

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/expenses/${widget.expense.id}'),
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

      if (response.statusCode == 200) {
        final updatedExpense = Expense(
          id: widget.expense.id,
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

        Navigator.pop(context, updatedExpense);
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update expense')),
        );
      }
    } catch (error) {
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

  Future<void> deleteExpense() async {
    if (widget.expense.id == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Expense'),
          content: const Text('Are you sure you want to delete this expense?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Keep Expense'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete', style: TextStyle(color: danger)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      isDeleting = true;
    });

    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/expenses/${widget.expense.id}'),
        headers: {'Authorization': 'Bearer ${AuthSession.token}'},
      );
      if (response.statusCode == 200) {
        if (!mounted) return;

        Navigator.pop(context, widget.expense);
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete expense')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isDeleting = false;
        });
      }
    }
  }

  InputDecoration fieldDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: tanzeemMuted),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE8ECEA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: tanzeemGreen),
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
          'Edit Expense',
          style: TextStyle(color: tanzeemText, fontWeight: FontWeight.w700),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: titleController,
            decoration: fieldDecoration(
              label: 'Title',
              icon: Icons.receipt_long_outlined,
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: fieldDecoration(
              label: 'Amount (\$)',
              icon: Icons.payments_outlined,
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: categoryController,
            decoration: fieldDecoration(
              label: 'Category',
              icon: Icons.category_outlined,
            ),
          ),

          const SizedBox(height: 14),

          InkWell(
            onTap: selectDate,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
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
          ),

          const SizedBox(height: 14),

          TextField(
            controller: notesController,
            maxLines: 4,
            decoration: fieldDecoration(
              label: 'Notes',
              icon: Icons.notes_rounded,
            ),
          ),

          const SizedBox(height: 28),

          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: isSaving || isDeleting ? null : saveExpense,
              style: ElevatedButton.styleFrom(
                backgroundColor: tanzeemGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Changes'),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: isSaving || isDeleting ? null : deleteExpense,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete Expense'),
              style: OutlinedButton.styleFrom(
                foregroundColor: danger,
                side: const BorderSide(color: Color(0xFFE8B7B7)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
