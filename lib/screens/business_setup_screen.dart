import 'package:flutter/material.dart';

import 'dart:convert';

import '../config/api_config.dart';
import '../auth/auth_session.dart';
import '../widgets/tanzeem_phone_field.dart';

import 'package:http/http.dart' as http;

import 'main_screen.dart';

class BusinessSetupScreen extends StatefulWidget {
  final int userId;

  const BusinessSetupScreen({super.key, required this.userId});

  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  static const Color tanzeemGreen = Color(0xFF0B5F4A);
  static const Color tanzeemMint = Color(0xFFE4F5EF);
  static const Color tanzeemBackground = Color(0xFFF7F9F8);
  static const Color tanzeemText = Color(0xFF18221F);
  static const Color tanzeemMuted = Color(0xFF6F7D77);

  final TextEditingController businessNameController = TextEditingController();

  String? phoneNumber;

  final TextEditingController emailController = TextEditingController();

  final TextEditingController addressController = TextEditingController();

  final TextEditingController descriptionController = TextEditingController();

  String selectedBusinessType = 'Beauty Salon';

  bool isSaving = false;

  final List<String> businessTypes = [
    'Beauty Salon',
    'Nail Salon',
    'Barbershop',
    'Spa',
    'Clinic',
    'Fitness',
    'Atelier',
    'Workshop',
    'Other',
  ];

  Future<void> setupBusiness() async {
    if (businessNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business name is required')),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/setup-business'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthSession.token}',
        },
        body: jsonEncode({
          'businessName': businessNameController.text.trim(),
          'businessType': selectedBusinessType,
          'phone': phoneNumber,
          'email': emailController.text.trim().isEmpty
              ? null
              : emailController.text.trim(),
          'address': addressController.text.trim().isEmpty
              ? null
              : addressController.text.trim(),
          'description': descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        await AuthSession.saveSession(
          newToken: data['token'],
          newUserId: AuthSession.userId,
          newBusinessId: data['businessId'],
          newStaffId: data['staffId'],
          newFirstName: AuthSession.firstName,
          newLastName: AuthSession.lastName,
          newEmail: AuthSession.email,
          newRole: AuthSession.role,
        );

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to set up business'),
          ),
        );
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

  InputDecoration fieldDecoration({
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
          children: [
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tanzeemMint,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.storefront_outlined,
                color: tanzeemGreen,
                size: 27,
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'Set up your business',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: tanzeemText,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Tell us a little about your business so Tanzeem can be ready for you.',
              style: TextStyle(color: tanzeemMuted, fontSize: 14, height: 1.4),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: businessNameController,
              textCapitalization: TextCapitalization.words,
              decoration: fieldDecoration(
                label: 'Business name',
                icon: Icons.storefront_outlined,
              ),
            ),

            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: selectedBusinessType,
              decoration: fieldDecoration(
                label: 'Business type',
                icon: Icons.category_outlined,
              ),
              items: businessTypes.map((type) {
                return DropdownMenuItem<String>(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedBusinessType = value;
                });
              },
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
              onChanged: (value) {
                phoneNumber = value;
              },
            ),

            const SizedBox(height: 14),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: fieldDecoration(
                label: 'Business email',
                icon: Icons.email_outlined,
                hint: 'Optional',
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: addressController,
              decoration: fieldDecoration(
                label: 'Address',
                icon: Icons.location_on_outlined,
                hint: 'Optional',
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'About your business',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: tanzeemText,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: fieldDecoration(
                label: 'Description',
                icon: Icons.notes_rounded,
                hint: 'Optional',
              ),
            ),

            const SizedBox(height: 28),

            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: tanzeemMint,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: tanzeemGreen,
                    size: 20,
                  ),

                  SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      'You can change these details later from Business Profile.',
                      style: TextStyle(
                        color: tanzeemGreen,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: isSaving ? null : setupBusiness,
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
                        'Finish Setup',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
