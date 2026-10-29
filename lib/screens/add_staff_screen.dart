import 'dart:convert';

import '../config/api_config.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../widgets/tanzeem_phone_field.dart';
import '../auth/auth_session.dart';

class AddStaffScreen extends StatefulWidget {
  const AddStaffScreen({super.key});

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  static const Color tanzeemGreen = Color(0xFF0B5F4A);
  static const Color tanzeemMint = Color(0xFFE4F5EF);
  static const Color tanzeemBackground = Color(0xFFF7F9F8);
  static const Color tanzeemText = Color(0xFF18221F);
  static const Color tanzeemMuted = Color(0xFF6F7D77);

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  String? phoneNumber;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final List<Map<String, dynamic>> services = [];
  final Set<int> selectedServiceIds = {};

  bool isLoadingServices = true;
  bool isSaving = false;
  bool obscurePassword = true;

  @override
  void initState() {
    super.initState();
    loadServices();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  Future<void> loadServices() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/services'),
        headers: {'Authorization': 'Bearer ${AuthSession.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (!mounted) return;

        setState(() {
          services.clear();

          services.addAll(data.map((item) => Map<String, dynamic>.from(item)));

          isLoadingServices = false;
        });
      } else {
        if (!mounted) return;

        setState(() {
          isLoadingServices = false;
        });

        showMessage('Failed to load services');
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoadingServices = false;
      });

      showMessage('Could not load services');
    }
  }

  InputDecoration inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: tanzeemGreen),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE8ECEA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE8ECEA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: tanzeemGreen, width: 1.4),
      ),
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> saveStaff() async {
    final firstName = firstNameController.text.trim();

    final lastName = lastNameController.text.trim();

    final phone = phoneNumber;

    final emailName = emailController.text.trim().toLowerCase();
    final email = '$emailName@tanzeem.com';

    final password = passwordController.text;

    if (firstName.isEmpty) {
      showMessage('First name is required');
      return;
    }

    if (emailName.isEmpty) {
      showMessage('Tanzeem email is required for the team member login');
      return;
    }

    final validEmailName = RegExp(r'^[a-z0-9._-]+$');

    if (!validEmailName.hasMatch(emailName)) {
      showMessage('Use only letters, numbers, dots, underscores or hyphens');
      return;
    }

    if (password.isEmpty) {
      showMessage('Temporary password is required');
      return;
    }

    if (password.length < 8) {
      showMessage('Password must be at least 8 characters');
      return;
    }

    if (selectedServiceIds.isEmpty) {
      showMessage('Please select at least one service');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      // STEP 1 — Create the staff record
      final staffResponse = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/staff'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthSession.token}',
        },
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName.isEmpty ? null : lastName,
          'phone': phone,
          'email': email,
        }),
      );

      final staffData = jsonDecode(staffResponse.body);

      if (staffResponse.statusCode != 200 && staffResponse.statusCode != 201) {
        if (!mounted) return;

        showMessage(staffData['message'] ?? 'Failed to add team member');

        return;
      }

      final dynamic rawStaffId = staffData['staffId'] ?? staffData['id'];

      if (rawStaffId == null) {
        if (!mounted) return;

        showMessage(
          'Team member was created, but its ID was not returned by the server',
        );

        return;
      }

      final int staffId = int.parse(rawStaffId.toString());

      // STEP 2 — Assign services
      final servicesResponse = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/staff-services'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthSession.token}',
        },
        body: jsonEncode({
          'staffId': staffId,
          'serviceIds': selectedServiceIds.toList(),
        }),
      );

      final servicesData = jsonDecode(servicesResponse.body);

      if (servicesResponse.statusCode != 200) {
        if (!mounted) return;

        showMessage(
          servicesData['message'] ??
              'Team member created, but service assignment failed',
        );

        return;
      }

      // STEP 3 — Create login account
      final accountResponse = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/staff-account'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthSession.token}',
        },
        body: jsonEncode({
          'staffId': staffId,
          'email': email,
          'password': password,
        }),
      );

      final accountData = jsonDecode(accountResponse.body);

      if (accountResponse.statusCode != 201) {
        if (!mounted) return;

        showMessage(
          accountData['message'] ??
              'Team member created, but login account creation failed',
        );

        return;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$firstName can now log in to Tanzeem')),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      showMessage('Could not connect to the server');
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Widget buildServiceItem(Map<String, dynamic> service) {
    final int serviceId = int.parse(service['id'].toString());

    final String serviceName = service['name']?.toString() ?? '';

    final bool selected = selectedServiceIds.contains(serviceId);

    return InkWell(
      onTap: () {
        setState(() {
          if (selected) {
            selectedServiceIds.remove(serviceId);
          } else {
            selectedServiceIds.add(serviceId);
          }
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? tanzeemMint : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? tanzeemGreen : const Color(0xFFE8ECEA),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected ? Colors.white : tanzeemMint,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.design_services_outlined,
                color: tanzeemGreen,
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                serviceName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: tanzeemText,
                ),
              ),
            ),

            Checkbox(
              value: selected,
              activeColor: tanzeemGreen,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    selectedServiceIds.add(serviceId);
                  } else {
                    selectedServiceIds.remove(serviceId);
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tanzeemBackground,
      appBar: AppBar(
        backgroundColor: tanzeemBackground,
        surfaceTintColor: tanzeemBackground,
        elevation: 0,
        title: const Text(
          'Add Team Member',
          style: TextStyle(color: tanzeemText, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          children: [
            const Text(
              'Team Member Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: tanzeemText,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Add their information and create their Tanzeem login.',
              style: TextStyle(fontSize: 13, color: tanzeemMuted),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: firstNameController,
              textCapitalization: TextCapitalization.words,
              decoration: inputDecoration(
                label: 'First Name',
                icon: Icons.person_outline_rounded,
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: lastNameController,
              textCapitalization: TextCapitalization.words,
              decoration: inputDecoration(
                label: 'Last Name',
                icon: Icons.person_outline_rounded,
              ),
            ),

            const SizedBox(height: 12),

            TanzeemPhoneField(
              onChanged: (value) {
                phoneNumber = value;
              },
            ),

            const SizedBox(height: 12),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              decoration: inputDecoration(
                label: 'Tanzeem email',
                icon: Icons.email_outlined,
                suffixIcon: const Padding(
                  padding: EdgeInsets.only(right: 14),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      '@tanzeem.com',
                      style: TextStyle(
                        color: tanzeemMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              decoration: inputDecoration(
                label: 'Temporary Password',
                icon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'The team member will use this email and password to log in.',
              style: TextStyle(fontSize: 12, color: tanzeemMuted),
            ),

            const SizedBox(height: 28),

            const Text(
              'Services',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: tanzeemText,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Select the services this team member provides.',
              style: TextStyle(fontSize: 13, color: tanzeemMuted),
            ),

            const SizedBox(height: 14),

            if (isLoadingServices)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: CircularProgressIndicator(color: tanzeemGreen),
                ),
              )
            else if (services.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8ECEA)),
                ),
                child: const Text(
                  'No services available. Add services before adding team members.',
                  style: TextStyle(fontSize: 13, color: tanzeemMuted),
                ),
              )
            else
              ...services.map(
                (service) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: buildServiceItem(service),
                ),
              ),

            const SizedBox(height: 16),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: isSaving || isLoadingServices ? null : saveStaff,
                style: ElevatedButton.styleFrom(
                  backgroundColor: tanzeemGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Add Team Member',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
