import 'package:flutter/material.dart';

import 'dart:convert';

import '../widgets/tanzeem_phone_field.dart';
import '../config/api_config.dart';
import 'business_hours_screen.dart';
import '../auth/auth_session.dart';

import 'package:http/http.dart' as http;

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  static const Color tanzeemGreen = Color(0xFF0B5F4A);

  static const Color tanzeemMint = Color(0xFFE4F5EF);

  static const Color tanzeemBackground = Color(0xFFF7F9F8);

  static const Color tanzeemText = Color(0xFF18221F);

  static const Color tanzeemMuted = Color(0xFF6F7D77);

  final TextEditingController nameController = TextEditingController();
  String? phoneNumber;

  final TextEditingController emailController = TextEditingController();

  final TextEditingController addressController = TextEditingController();

  final TextEditingController businessTypeController = TextEditingController();

  final TextEditingController descriptionController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadBusiness();
  }

  Future<void> loadBusiness() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/business'),
        headers: {'Authorization': 'Bearer ${AuthSession.token}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (!mounted) return;

        setState(() {
          nameController.text = data['name'] ?? '';

          phoneNumber = data['phone'];

          emailController.text = data['email'] ?? '';

          addressController.text = data['address'] ?? '';

          businessTypeController.text = data['business_type'] ?? '';

          descriptionController.text = data['description'] ?? '';

          isLoading = false;
        });
      } else {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      print(error);

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> saveBusiness() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business name is required')),
      );

      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/business'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthSession.token}',
        },
        body: jsonEncode({
          'name': nameController.text.trim(),
          'businessType': businessTypeController.text.trim().isEmpty
              ? null
              : businessTypeController.text.trim(),
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

      if (response.statusCode == 200) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business profile updated')),
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update business')),
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
    if (isLoading) {
      return Scaffold(
        backgroundColor: tanzeemBackground,

        body: const Center(
          child: CircularProgressIndicator(color: tanzeemGreen),
        ),
      );
    }

    return Scaffold(
      backgroundColor: tanzeemBackground,

      appBar: AppBar(
        backgroundColor: tanzeemBackground,

        elevation: 0,

        surfaceTintColor: tanzeemBackground,

        title: const Text(
          'Business Profile',
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
                Icon(Icons.storefront_outlined, color: tanzeemGreen),

                SizedBox(width: 12),

                Expanded(
                  child: Text(
                    'These details represent your business inside Tanzeem.',
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
            'Business information',
            style: TextStyle(
              fontSize: 15,

              fontWeight: FontWeight.w700,

              color: tanzeemText,
            ),
          ),

          const SizedBox(height: 10),

          TextField(
            controller: nameController,

            decoration: inputDecoration(
              label: 'Business name',

              icon: Icons.storefront_outlined,
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: businessTypeController,

            decoration: inputDecoration(
              label: 'Business type',

              icon: Icons.category_outlined,

              hint: 'Example: Salon',
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: descriptionController,

            maxLines: 3,

            decoration: inputDecoration(
              label: 'Description',

              icon: Icons.notes_rounded,

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
            initialValue: phoneNumber,
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
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: addressController,

            decoration: inputDecoration(
              label: 'Address',

              icon: Icons.location_on_outlined,

              hint: 'Optional',
            ),
          ),

          const SizedBox(height: 28),

          const Text(
            'Business Hours',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: tanzeemText,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Set the regular days and hours your business is open.',
            style: TextStyle(fontSize: 13, color: tanzeemMuted),
          ),

          const SizedBox(height: 14),

          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BusinessHoursScreen(),
                ),
              );
            },
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
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: tanzeemMint,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Icon(
                      Icons.schedule_rounded,
                      color: tanzeemGreen,
                      size: 21,
                    ),
                  ),

                  SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Business Hours',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: tanzeemText,
                          ),
                        ),

                        SizedBox(height: 3),

                        Text(
                          'Choose opening days and hours',
                          style: TextStyle(fontSize: 12, color: tanzeemMuted),
                        ),
                      ],
                    ),
                  ),

                  Icon(Icons.chevron_right_rounded, color: tanzeemMuted),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: isSaving ? null : saveBusiness,
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
        ],
      ),
    );
  }
}
