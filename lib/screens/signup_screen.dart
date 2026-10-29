import 'package:flutter/material.dart';

import 'dart:convert';

import '../widgets/tanzeem_phone_field.dart';
import '../config/api_config.dart';
import '../auth/auth_session.dart';

import 'package:http/http.dart' as http;

import 'business_setup_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  static const Color tanzeemGreen = Color(0xFF0B5F4A);
  static const Color tanzeemBackground = Color(0xFFF7F9F8);
  static const Color tanzeemText = Color(0xFF18221F);
  static const Color tanzeemMuted = Color(0xFF6F7D77);

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  String? phoneNumber;
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  Future<void> signup() async {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final emailName = emailController.text.trim().toLowerCase();
    final email = '$emailName@tanzeem.com';
    final phone = phoneNumber;
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (firstName.isEmpty ||
        emailName.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('First name, email and password are required'),
        ),
      );
      return;
    }

    final validEmailName = RegExp(r'^[a-z0-9._-]+$');

    if (!validEmailName.hasMatch(emailName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Use only letters, numbers, dots, underscores or hyphens',
          ),
        ),
      );
      return;
    }

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName.isEmpty ? null : lastName,
          'email': email,
          'phone': phone,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final int userId = data['userId'];

        await AuthSession.saveSession(
          newToken: data['token'],
          newUserId: userId,
          newBusinessId: null,
          newStaffId: null,
          newFirstName: firstNameController.text.trim(),
          newLastName: lastNameController.text.trim().isEmpty
              ? null
              : lastNameController.text.trim(),
          newEmail: email,
          newRole: 'OWNER',
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BusinessSetupScreen(userId: userId),
          ),
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to create account'),
          ),
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
          isLoading = false;
        });
      }
    }
  }

  InputDecoration fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: tanzeemMuted),
      suffixIcon: suffixIcon,
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
      ),

      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
          children: [
            const Text(
              'Create your account',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: tanzeemText,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Start managing your business with Tanzeem.',
              style: TextStyle(fontSize: 14, color: tanzeemMuted),
            ),

            const SizedBox(height: 30),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: firstNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: fieldDecoration(
                      label: 'First name',
                      icon: Icons.person_outline_rounded,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: TextField(
                    controller: lastNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: fieldDecoration(
                      label: 'Last name',
                      icon: Icons.person_outline_rounded,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              decoration: fieldDecoration(
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

            const SizedBox(height: 14),

            TanzeemPhoneField(
              onChanged: (value) {
                phoneNumber = value;
              },
            ),

            const SizedBox(height: 14),

            TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              decoration: fieldDecoration(
                label: 'Password',
                icon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: confirmPasswordController,
              obscureText: obscureConfirmPassword,
              decoration: fieldDecoration(
                label: 'Confirm password',
                icon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      obscureConfirmPassword = !obscureConfirmPassword;
                    });
                  },
                  icon: Icon(
                    obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Use at least 8 characters.',
              style: TextStyle(color: tanzeemMuted, fontSize: 11),
            ),

            const SizedBox(height: 26),

            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: isLoading ? null : signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: tanzeemGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Already have an account?',
                  style: TextStyle(color: tanzeemMuted),
                ),

                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Log in',
                    style: TextStyle(
                      color: tanzeemGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
