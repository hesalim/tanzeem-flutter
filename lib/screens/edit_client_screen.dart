import 'package:flutter/material.dart';

import '../auth/auth_session.dart';
import '../config/api_config.dart';

import 'dart:convert';

import '../widgets/tanzeem_phone_field.dart';

import 'package:http/http.dart' as http;

import '../models/client.dart';

class EditClientScreen extends StatefulWidget {
  final Client client;

  const EditClientScreen({super.key, required this.client});

  @override
  State<EditClientScreen> createState() => _EditClientScreenState();
}

class _EditClientScreenState extends State<EditClientScreen> {
  static const Color tanzeemGreen = Color(0xFF0B5F4A);
  static const Color tanzeemMint = Color(0xFFE4F5EF);
  static const Color tanzeemBackground = Color(0xFFF7F9F8);
  static const Color tanzeemText = Color(0xFF18221F);
  static const Color tanzeemMuted = Color(0xFF6F7D77);
  static const Color danger = Color(0xFFC53B3B);

  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  String? phoneNumber;
  late TextEditingController emailController;
  late TextEditingController notesController;

  bool isSaving = false;
  bool isDeleting = false;

  @override
  void initState() {
    super.initState();

    firstNameController = TextEditingController(text: widget.client.firstName);

    lastNameController = TextEditingController(
      text: widget.client.lastName ?? '',
    );

    phoneNumber = widget.client.phone;

    emailController = TextEditingController(text: widget.client.email ?? '');

    notesController = TextEditingController(text: widget.client.notes ?? '');
  }

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

    if (widget.client.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer does not have a database ID')),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/customers/${widget.client.id}'),
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

      if (response.statusCode == 200) {
        final updatedClient = Client(
          id: widget.client.id,
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

        Navigator.pop(context, updatedClient);
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update customer')),
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

  Future<void> deleteClient() async {
    if (widget.client.id == null) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Customer'),
          content: const Text(
            'This customer will be removed from your active customer list. Existing appointment history will remain.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Keep Customer'),
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
        Uri.parse('${ApiConfig.baseUrl}/api/customers/${widget.client.id}'),
        headers: {'Authorization': 'Bearer ${AuthSession.token}'},
      );
      if (response.statusCode == 200) {
        if (!mounted) return;

        Navigator.pop(context, widget.client);
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete customer')),
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
          isDeleting = false;
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
          'Edit Customer',
          style: TextStyle(color: tanzeemText, fontWeight: FontWeight.w700),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),

        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: tanzeemMint,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  widget.client.firstName.isNotEmpty
                      ? widget.client.firstName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: tanzeemGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                  ),
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.client.fullName,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: tanzeemText,
                      ),
                    ),

                    const SizedBox(height: 3),

                    const Text(
                      'Customer profile',
                      style: TextStyle(color: tanzeemMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 26),

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
            initialValue: widget.client.phone,
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
              onPressed: isSaving || isDeleting ? null : saveClient,
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
                      'Save Changes',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: isSaving || isDeleting ? null : deleteClient,
              icon: isDeleting
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline_rounded),
              label: const Text('Delete Customer'),
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
