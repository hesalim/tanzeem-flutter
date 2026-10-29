import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../widgets/tanzeem_phone_field.dart';
import '../config/api_config.dart';
import 'staff_time_off_screen.dart';
import 'staff_availability_screen.dart';
import '../auth/auth_session.dart';
import '../models/staff.dart';

class EditStaffScreen extends StatefulWidget {
  final Staff staff;

  const EditStaffScreen({super.key, required this.staff});

  @override
  State<EditStaffScreen> createState() => _EditStaffScreenState();
}

class _EditStaffScreenState extends State<EditStaffScreen> {
  static const Color tanzeemGreen = Color(0xFF0B5F4A);
  static const Color tanzeemMint = Color(0xFFE4F5EF);
  static const Color tanzeemBackground = Color(0xFFF7F9F8);
  static const Color tanzeemText = Color(0xFF18221F);
  static const Color tanzeemMuted = Color(0xFF6F7D77);
  static const Color danger = Color(0xFFC53B3B);

  late final TextEditingController firstNameController;
  late final TextEditingController lastNameController;
  String? phoneNumber;
  late final TextEditingController emailController;

  final List<Map<String, dynamic>> services = [];
  final Set<int> selectedServiceIds = {};

  bool isLoadingServices = true;
  bool isSaving = false;
  bool isDeactivating = false;

  @override
  void initState() {
    super.initState();

    firstNameController = TextEditingController(text: widget.staff.firstName);

    lastNameController = TextEditingController(
      text: widget.staff.lastName ?? '',
    );

    phoneNumber = widget.staff.phone;

    emailController = TextEditingController(text: widget.staff.email ?? '');

    loadServices();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();

    super.dispose();
  }

  Future<void> loadServices() async {
    try {
      final allServicesResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/services'),
        headers: {'Authorization': 'Bearer ${AuthSession.token}'},
      );

      final assignedServicesResponse = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/staff-services?staffId=${widget.staff.id}',
        ),
        headers: {'Authorization': 'Bearer ${AuthSession.token}'},
      );

      if (allServicesResponse.statusCode != 200) {
        if (!mounted) return;

        setState(() {
          isLoadingServices = false;
        });

        showMessage('Failed to load services');

        return;
      }

      if (assignedServicesResponse.statusCode != 200) {
        if (!mounted) return;

        setState(() {
          isLoadingServices = false;
        });

        showMessage('Failed to load assigned services');

        return;
      }

      final List<dynamic> allServicesData = jsonDecode(
        allServicesResponse.body,
      );

      final List<dynamic> assignedServicesData = jsonDecode(
        assignedServicesResponse.body,
      );

      if (!mounted) return;

      setState(() {
        services.clear();

        services.addAll(
          allServicesData.map((item) => Map<String, dynamic>.from(item)),
        );

        selectedServiceIds.clear();

        selectedServiceIds.addAll(
          assignedServicesData.map<int>(
            (item) => int.parse(item['id'].toString()),
          ),
        );

        isLoadingServices = false;
      });
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
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: tanzeemGreen),
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

  Future<void> saveStaff() async {
    final firstName = firstNameController.text.trim();

    final lastName = lastNameController.text.trim();

    final phone = phoneNumber;

    final email = emailController.text.trim();

    if (firstName.isEmpty) {
      showMessage('First name is required');
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
      // 1. Update team member details
      final staffResponse = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/staff/${widget.staff.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthSession.token}',
        },
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName.isEmpty ? null : lastName,
          'phone': phone,
          'email': email.isEmpty ? null : email,
        }),
      );

      final staffData = jsonDecode(staffResponse.body);

      if (staffResponse.statusCode != 200) {
        if (!mounted) return;

        showMessage(staffData['message'] ?? 'Failed to update team member');

        return;
      }

      // 2. Update assigned services
      final servicesResponse = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/staff-services'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthSession.token}',
        },
        body: jsonEncode({
          'staffId': widget.staff.id,
          'serviceIds': selectedServiceIds.toList(),
        }),
      );

      final servicesData = jsonDecode(servicesResponse.body);

      if (servicesResponse.statusCode != 200) {
        if (!mounted) return;

        showMessage(
          servicesData['message'] ??
              'Team member updated, but services failed to save',
        );

        return;
      }

      if (!mounted) return;

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

  Future<void> deactivateStaff() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Deactivate team member?'),
          content: Text(
            '${widget.staff.fullName} will no longer appear as an active team member.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Deactivate', style: TextStyle(color: danger)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      isDeactivating = true;
    });

    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/staff/${widget.staff.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthSession.token}',
        },
      );

      if (response.statusCode == 200) {
        if (!mounted) return;

        Navigator.pop(context, true);
      } else {
        final data = jsonDecode(response.body);

        if (!mounted) return;

        showMessage(data['message'] ?? 'Failed to deactivate team member');
      }
    } catch (error) {
      if (!mounted) return;

      showMessage('Could not connect to the server');
    } finally {
      if (mounted) {
        setState(() {
          isDeactivating = false;
        });
      }
    }
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
          'Edit Team Member',
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

            const SizedBox(height: 18),

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
              initialValue: widget.staff.phone,
              onChanged: (value) {
                phoneNumber = value;
              },
            ),

            const SizedBox(height: 12),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: inputDecoration(
                label: 'Email',
                icon: Icons.email_outlined,
              ),
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
                  'No services available.',
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

            const SizedBox(height: 28),

            const Text(
              'Working Hours',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: tanzeemText,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Set the regular weekly availability for this team member.',
              style: TextStyle(fontSize: 13, color: tanzeemMuted),
            ),

            const SizedBox(height: 14),

            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        StaffAvailabilityScreen(staff: widget.staff),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
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
                            'Edit Working Hours',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: tanzeemText,
                            ),
                          ),
                          const SizedBox(height: 12),

                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      StaffTimeOffScreen(staff: widget.staff),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE8ECEA),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: Color(0xFFFFF0F0),
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(12),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.block_rounded,
                                      color: danger,
                                      size: 21,
                                    ),
                                  ),

                                  SizedBox(width: 12),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Time Off & Blocked Periods',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: tanzeemText,
                                          ),
                                        ),

                                        SizedBox(height: 3),

                                        Text(
                                          'Vacations, breaks and unavailable times',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: tanzeemMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: tanzeemMuted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 3),

                          Text(
                            'Choose working days and hours',
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
              height: 52,
              child: ElevatedButton(
                onPressed: isSaving || isDeactivating || isLoadingServices
                    ? null
                    : saveStaff,
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
                        'Save Changes',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),

            const SizedBox(height: 32),

            const Divider(color: Color(0xFFE8ECEA)),

            const SizedBox(height: 20),

            const Text(
              'Team Member Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: tanzeemText,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Deactivate this team member if they no longer work at the business.',
              style: TextStyle(fontSize: 13, height: 1.4, color: tanzeemMuted),
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: isSaving || isDeactivating ? null : deactivateStaff,
                icon: isDeactivating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: danger,
                        ),
                      )
                    : const Icon(Icons.person_off_outlined),
                label: Text(
                  isDeactivating ? 'Deactivating...' : 'Deactivate Team Member',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: danger,
                  side: const BorderSide(color: danger),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
