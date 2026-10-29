import 'package:flutter/material.dart';

import '../widgets/tanzeem_phone_field.dart';
import '../config/api_config.dart';
import '../auth/auth_session.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/client.dart';

class AddClientScreen extends StatefulWidget {
  const AddClientScreen({super.key});

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  static const Color tanzeemGreen = Color(0xFF0B5F4A);
  static const Color tanzeemMint = Color(0xFFE4F5EF);
  static const Color tanzeemBackground = Color(0xFFF7F9F8);
  static const Color tanzeemText = Color(0xFF18221F);
  static const Color tanzeemMuted = Color(0xFF6F7D77);

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  String? phoneNumber;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  bool isSaving = false;

  Future<void> saveClient() async {
    if (firstNameController.text.trim().isEmpty ||
        phoneNumber == null ||
        phoneNumber!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('First name and phone number are required'),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/customers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthSession.token}',
        },
        body: jsonEncode({
          'first_name': firstNameController.text.trim(),
          'last_name': lastNameController.text.trim().isEmpty
              ? null
              : lastNameController.text.trim(),
          'phone': phoneNumber,
          'email': emailController.text.trim().isEmpty
              ? null
              : emailController.text.trim(),
          'notes': notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        final client = Client(
          id: int.parse(responseData['customerId'].toString()),
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim().isEmpty
              ? null
              : lastNameController.text.trim(),
          phone: phoneNumber!,
          email: emailController.text.trim().isEmpty
              ? null
              : emailController.text.trim(),
          notes: notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
        );

        if (!mounted) return;

        Navigator.pop(context, client);
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save customer')),
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
      labelStyle: const TextStyle(color: tanzeemMuted),
      hintStyle: const TextStyle(color: tanzeemMuted, fontSize: 13),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: tanzeemText),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Add Customer',
          style: TextStyle(color: tanzeemText, fontWeight: FontWeight.w700),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tanzeemMint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.person_add_alt_1_rounded, color: tanzeemGreen),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add a customer once and reuse them for future appointments.',
                    style: TextStyle(
                      color: tanzeemGreen,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Basic information',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: tanzeemText,
            ),
          ),

          const SizedBox(height: 10),

          TextField(
            controller: firstNameController,
            textCapitalization: TextCapitalization.words,
            decoration: inputDecoration(
              label: 'First name',
              icon: Icons.person_outline_rounded,
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: lastNameController,
            textCapitalization: TextCapitalization.words,
            decoration: inputDecoration(
              label: 'Last name',
              icon: Icons.person_outline_rounded,
              hint: 'Optional',
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Contact information',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: tanzeemText,
            ),
          ),

          const SizedBox(height: 10),
          TanzeemPhoneField(
            required: true,
            onChanged: (value) {
              phoneNumber = value;
            },
          ),

          const SizedBox(height: 14),

          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: inputDecoration(
              label: 'Email',
              icon: Icons.email_outlined,
              hint: 'Optional',
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Notes',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: tanzeemText,
            ),
          ),

          const SizedBox(height: 10),

          TextField(
            controller: notesController,
            maxLines: 4,
            decoration: inputDecoration(
              label: 'Notes',
              icon: Icons.notes_rounded,
              hint: 'Preferences, reminders, or anything useful',
            ),
          ),

          const SizedBox(height: 28),

          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: isSaving ? null : saveClient,
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
                      'Save Customer',
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
