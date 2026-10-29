import 'package:flutter/material.dart';

import '../utils/currency_formatter.dart';
import '../auth/auth_session.dart';
import '../models/staff.dart';
import '../config/api_config.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/appointment.dart';
import '../models/client.dart';
import '../models/service.dart';
import 'add_client_screen.dart';

class NewAppointmentScreen extends StatefulWidget {
  final List<Client> clients;
  final List<Service> services;

  const NewAppointmentScreen({
    super.key,
    required this.clients,
    required this.services,
  });

  @override
  State<NewAppointmentScreen> createState() => _NewAppointmentScreenState();
}

class _NewAppointmentScreenState extends State<NewAppointmentScreen> {
  static const Color tanzeemGreen = Color(0xFF0B5F4A);
  static const Color tanzeemDarkGreen = Color(0xFF073B31);
  static const Color tanzeemMint = Color(0xFFE4F5EF);
  static const Color tanzeemBackground = Color(0xFFF7F9F8);
  static const Color tanzeemText = Color(0xFF18221F);
  static const Color tanzeemMuted = Color(0xFF6F7D77);

  bool get isOwner => AuthSession.role == 'OWNER';

  Client? selectedClient;
  Staff? selectedStaff;

  final List<Staff> staffMembers = [];
  final List<Service> availableServices = [];
  final List<Service> selectedServices = [];

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  final List<Map<String, dynamic>> availableSlots = [];

  bool isLoadingSlots = false;

  final TextEditingController notesController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    if (isOwner) {
      await Future.wait([loadServices(), loadStaff()]);
    } else {
      await loadServices();

      if (AuthSession.staffId != null) {
        selectedStaff = Staff(
          id: AuthSession.staffId!,
          userId: AuthSession.userId,
          firstName: AuthSession.firstName ?? 'Staff',
          lastName: AuthSession.lastName,
          email: AuthSession.email,
          phone: null,
          isOwner: false,
          isActive: true,
        );

        await loadServicesForStaff(selectedStaff!);
      }
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  Future<void> loadCustomers() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/customers'),
      headers: {'Authorization': 'Bearer ${AuthSession.token}'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        widget.clients.clear();

        widget.clients.addAll(
          data.map(
            (item) => Client(
              id: item['id'],
              firstName: item['first_name'],
              lastName: item['last_name'],
              phone: item['phone'],
              email: item['email'],
              notes: item['notes'],
            ),
          ),
        );
      });
    } else {
      print('Failed to load customers');
      print(response.body);
    }
  }

  Future<void> loadServices() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/services'),
      headers: {'Authorization': 'Bearer ${AuthSession.token}'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        widget.services.clear();

        widget.services.addAll(
          data.map(
            (item) => Service(
              id: item['id'],
              name: item['name'],
              duration: item['duration_minutes'],
              price: double.parse(item['price'].toString()),
              bookingType: item['booking_type'] == 'INDIVIDUAL'
                  ? 'Individual'
                  : 'Group',
              capacity: item['max_participants'],
              description: item['description'],
            ),
          ),
        );
      });
    } else {
      print('Failed to load services');
      print(response.body);
    }
  }

  Future<void> loadStaff() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/staff'),
      headers: {'Authorization': 'Bearer ${AuthSession.token}'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        staffMembers.clear();

        staffMembers.addAll(
          data.map((item) => Staff.fromJson(Map<String, dynamic>.from(item))),
        );
      });
    } else {
      print('Failed to load staff');
      print(response.body);
    }
  }

  Future<void> loadServicesForStaff(Staff staff) async {
    selectedServices.clear();
    availableServices.clear();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/staff-services?staffId=${staff.id}'),
      headers: {'Authorization': 'Bearer ${AuthSession.token}'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        availableServices.addAll(
          data.map(
            (item) => Service(
              id: item['id'],
              name: item['name'],
              duration: item['duration_minutes'],
              price: double.parse(item['price'].toString()),
              bookingType: item['booking_type'] == 'INDIVIDUAL'
                  ? 'Individual'
                  : 'Group',
              capacity: item['max_participants'],
              description: item['description'],
            ),
          ),
        );
      });
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load services for this team member'),
        ),
      );
    }
  }

  double get totalPrice {
    return selectedServices.fold(0, (total, service) => total + service.price);
  }

  int get totalDuration {
    return selectedServices.fold(
      0,
      (total, service) => total + service.duration,
    );
  }

  String formatDateForApi(DateTime date) {
    final year = date.year.toString();

    final month = date.month.toString().padLeft(2, '0');

    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  Future<void> loadAvailableSlots() async {
    if (selectedStaff == null ||
        selectedDate == null ||
        selectedServices.isEmpty) {
      setState(() {
        availableSlots.clear();
        selectedTime = null;
      });

      return;
    }

    final serviceIds = selectedServices
        .where((service) => service.id != null)
        .map((service) => service.id.toString())
        .join(',');

    if (serviceIds.isEmpty) {
      return;
    }

    setState(() {
      isLoadingSlots = true;
      availableSlots.clear();
      selectedTime = null;
    });

    try {
      final date = formatDateForApi(selectedDate!);

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/slots'
          '?date=$date'
          '&staffId=${selectedStaff!.id}'
          '&serviceIds=$serviceIds',
        ),
        headers: {'Authorization': 'Bearer ${AuthSession.token}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List<dynamic> slots = data['slots'] ?? [];

        if (!mounted) return;

        setState(() {
          availableSlots.addAll(
            slots.map((slot) => Map<String, dynamic>.from(slot)),
          );
        });
      } else {
        String message = 'Failed to load available times';

        try {
          final data = jsonDecode(response.body);

          message = data['message']?.toString() ?? message;
        } catch (_) {}

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (error) {
      print('LOAD SLOTS ERROR: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load available times')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoadingSlots = false;
        });
      }
    }
  }

  Client clientFromJson(dynamic item) {
    return Client(
      id: item['id'],
      firstName: item['first_name'],
      lastName: item['last_name'],
      phone: item['phone'],
      email: item['email'],
      notes: item['notes'],
    );
  }

  Future<List<Client>> fetchCustomers({
    String? search,
    bool recent = false,
  }) async {
    final queryParameters = <String, String>{};

    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    } else if (recent) {
      queryParameters['recent'] = 'true';
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/customers').replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer ${AuthSession.token}'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load customers');
    }

    final List<dynamic> data = jsonDecode(response.body);

    return data.map(clientFromJson).toList();
  }

  Future<void> selectClient() async {
    List<Client> customers = [];
    final searchController = TextEditingController();
    try {
      customers = await fetchCustomers(recent: true);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not load customers')));

      return;
    }

    if (!mounted) return;

    final Client? client = await showModalBottomSheet<Client>(
      context: context,
      isScrollControlled: true,
      backgroundColor: tanzeemBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.78,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  child: Column(
                    children: [
                      Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD7DEDA),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Select Customer',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: tanzeemText,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by name or phone',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: tanzeemMuted,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE8ECEA),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE8ECEA),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: tanzeemGreen),
                          ),
                        ),

                        onChanged: (value) async {
                          try {
                            final results = value.trim().isEmpty
                                ? await fetchCustomers(recent: true)
                                : await fetchCustomers(search: value);

                            setModalState(() {
                              customers = results;
                            });
                          } catch (_) {}
                        },
                      ),

                      const SizedBox(height: 12),

                      InkWell(
                        onTap: () async {
                          Navigator.pop(context);

                          final Client? newClient =
                              await Navigator.push<Client>(
                                this.context,
                                MaterialPageRoute(
                                  builder: (context) => const AddClientScreen(),
                                ),
                              );

                          if (newClient != null && mounted) {
                            setState(() {
                              selectedClient = newClient;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: tanzeemMint,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.person_add_alt_1_rounded,
                                color: tanzeemGreen,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Add new customer',
                                style: TextStyle(
                                  color: tanzeemGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          searchController.text.trim().isEmpty
                              ? 'Recent customers'
                              : 'Search results',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: tanzeemMuted,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Expanded(
                        child: customers.isEmpty
                            ? const Center(
                                child: Text(
                                  'No customers found',
                                  style: TextStyle(color: tanzeemMuted),
                                ),
                              )
                            : ListView.separated(
                                itemCount: customers.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final customer = customers[index];

                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: tanzeemMint,
                                      child: Text(
                                        customer.firstName.isNotEmpty
                                            ? customer.firstName[0]
                                                  .toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: tanzeemGreen,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      customer.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: tanzeemText,
                                      ),
                                    ),
                                    subtitle: Text(
                                      customer.phone,
                                      style: const TextStyle(
                                        color: tanzeemMuted,
                                      ),
                                    ),
                                    trailing: const Icon(
                                      Icons.chevron_right_rounded,
                                      color: tanzeemMuted,
                                    ),
                                    onTap: () {
                                      Navigator.pop(context, customer);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (client != null) {
      setState(() {
        selectedClient = client;
      });
    }
  }

  Future<void> selectStaff() async {
    final Staff? staff = await showModalBottomSheet<Staff>(
      context: context,
      backgroundColor: tanzeemBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7DEDA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 18),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select Team Member',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: tanzeemText,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                if (staffMembers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No team members available',
                      style: TextStyle(color: tanzeemMuted),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: staffMembers.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final staff = staffMembers[index];

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: tanzeemMint,
                            child: Icon(
                              staff.isOwner
                                  ? Icons.workspace_premium_outlined
                                  : Icons.person_outline_rounded,
                              color: tanzeemGreen,
                            ),
                          ),
                          title: Text(
                            staff.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: tanzeemText,
                            ),
                          ),
                          subtitle: Text(
                            staff.isOwner ? 'Owner' : 'Team member',
                            style: const TextStyle(color: tanzeemMuted),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: tanzeemMuted,
                          ),
                          onTap: () {
                            Navigator.pop(context, staff);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (staff != null) {
      setState(() {
        selectedStaff = staff;

        selectedServices.clear();
        availableServices.clear();
        availableSlots.clear();

        selectedTime = null;
      });

      await loadServicesForStaff(staff);
    }
  }

  Future<void> selectDate() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null) {
      return;
    }

    setState(() {
      selectedDate = date;
      selectedTime = null;
      availableSlots.clear();
    });

    await loadAvailableSlots();
  }

  Future<void> selectTime() async {
    if (selectedStaff == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a team member first')),
      );

      return;
    }

    if (selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one service first')),
      );

      return;
    }

    if (selectedDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select a date first')));

      return;
    }

    await loadAvailableSlots();

    if (!mounted) return;

    if (availableSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available times on this date')),
      );

      return;
    }

    final Map<String, dynamic>?
    slot = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: tanzeemBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available Times',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: tanzeemText,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                  style: const TextStyle(color: tanzeemMuted),
                ),

                const SizedBox(height: 18),

                Flexible(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: availableSlots.map((slot) {
                        final startTime = slot['startTime'].toString();

                        final endTime = slot['endTime'].toString();

                        return InkWell(
                          onTap: () {
                            Navigator.pop(context, slot);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE8ECEA),
                              ),
                            ),
                            child: Text(
                              '$startTime – $endTime',
                              style: const TextStyle(
                                color: tanzeemText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (slot == null) {
      return;
    }

    final startTime = slot['startTime'].toString().split(':');

    setState(() {
      selectedTime = TimeOfDay(
        hour: int.parse(startTime[0]),
        minute: int.parse(startTime[1]),
      );
    });
  }

  Future<void> saveAppointment() async {
    if (selectedClient == null ||
        selectedStaff == null ||
        selectedServices.isEmpty ||
        selectedDate == null ||
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select customer, team member, services, date and time',
          ),
        ),
      );

      return;
    }

    if (selectedClient!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected customer does not have a database ID'),
        ),
      );

      return;
    }

    if (selectedServices.any((service) => service.id == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('One or more services do not have a database ID'),
        ),
      );

      return;
    }

    final appointmentDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    final endDateTime = appointmentDateTime.add(
      Duration(minutes: totalDuration),
    );

    setState(() {
      isSaving = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/appointments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthSession.token}',
        },
        body: jsonEncode({
          'customerId': selectedClient!.id,
          'staffId': selectedStaff!.id,
          'startAt': appointmentDateTime.toIso8601String(),
          'endAt': endDateTime.toIso8601String(),
          'notes': notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
          'services': selectedServices.map((service) {
            return {
              'serviceId': service.id,
              'price': service.price,
              'durationMinutes': service.duration,
            };
          }).toList(),
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        final appointment = Appointment(
          id: responseData['appointmentId'],
          client: selectedClient!,
          services: List.from(selectedServices),
          dateTime: appointmentDateTime,
          notes: notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
        );

        if (!mounted) return;

        Navigator.pop(context, appointment);
      } else {
        print('Appointment POST failed');
        print(response.statusCode);
        print(response.body);

        final responseData = jsonDecode(response.body);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              responseData['message'] ?? 'Failed to save appointment',
            ),
          ),
        );
      }
    } catch (error) {
      print('Appointment request error: $error');

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

  Widget buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: tanzeemText,
      ),
    );
  }

  Widget buildSelectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
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
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: tanzeemMint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: tanzeemGreen, size: 21),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: tanzeemText,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    subtitle,
                    style: const TextStyle(color: tanzeemMuted, fontSize: 12),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right_rounded, color: tanzeemMuted),
          ],
        ),
      ),
    );
  }

  Widget buildServiceCard(Service service) {
    final selected = selectedServices.contains(service);

    return InkWell(
      onTap: () async {
        setState(() {
          if (selected) {
            selectedServices.remove(service);
          } else {
            selectedServices.add(service);
          }

          selectedTime = null;
        });

        await loadAvailableSlots();
      },
      borderRadius: BorderRadius.circular(16),

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),

        padding: const EdgeInsets.all(14),

        decoration: BoxDecoration(
          color: selected ? tanzeemMint : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? tanzeemGreen : const Color(0xFFE8ECEA),
            width: selected ? 1.4 : 1,
          ),
        ),

        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected ? Colors.white : tanzeemMint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                service.bookingType == 'Group'
                    ? Icons.groups_2_outlined
                    : Icons.spa_outlined,
                color: tanzeemGreen,
                size: 21,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: tanzeemText,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '${service.duration} min • ${CurrencyFormatter.usd(service.price)}',
                    style: const TextStyle(color: tanzeemMuted, fontSize: 12),
                  ),
                ],
              ),
            ),

            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selected ? tanzeemGreen : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? tanzeemGreen : const Color(0xFFB9C3BF),
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: tanzeemBackground,
        body: const SafeArea(
          child: Center(child: CircularProgressIndicator(color: tanzeemGreen)),
        ),
      );
    }

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
          'New Appointment',
          style: TextStyle(color: tanzeemText, fontWeight: FontWeight.w700),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),

        children: [
          buildSectionTitle('Customer'),

          const SizedBox(height: 8),

          buildSelectionCard(
            icon: Icons.person_outline_rounded,
            title: selectedClient?.fullName ?? 'Select customer',
            subtitle: selectedClient == null
                ? 'Choose an existing customer'
                : selectedClient!.phone,
            onTap: selectClient,
          ),

          if (isOwner) ...[
            const SizedBox(height: 26),

            buildSectionTitle('Team Member'),

            const SizedBox(height: 8),

            buildSelectionCard(
              icon: Icons.person_pin_outlined,
              title: selectedStaff?.fullName ?? 'Select team member',
              subtitle: selectedStaff == null
                  ? 'Choose who will handle the appointment'
                  : selectedStaff!.isOwner
                  ? 'Owner'
                  : 'Team member',
              onTap: selectStaff,
            ),
          ],

          const SizedBox(height: 26),

          Row(
            children: [
              Expanded(child: buildSectionTitle('Services')),

              if (selectedServices.isNotEmpty)
                Text(
                  '${selectedServices.length} selected',
                  style: const TextStyle(
                    color: tanzeemGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          if (selectedStaff == null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8ECEA)),
              ),
              child: const Text(
                'Select a team member first to see their services.',
                style: TextStyle(color: tanzeemMuted),
              ),
            )
          else if (availableServices.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8ECEA)),
              ),
              child: const Text(
                'This team member has no assigned services.',
                style: TextStyle(color: tanzeemMuted),
              ),
            )
          else
            ...availableServices.map(
              (service) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: buildServiceCard(service),
              ),
            ),

          const SizedBox(height: 18),

          buildSectionTitle('Schedule'),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: buildSelectionCard(
                  icon: Icons.calendar_today_outlined,
                  title: 'Date',
                  subtitle: selectedDate == null
                      ? 'Select date'
                      : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                  onTap: selectDate,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: buildSelectionCard(
                  icon: Icons.access_time_rounded,
                  title: 'Time',
                  subtitle: isLoadingSlots
                      ? 'Loading available times...'
                      : selectedTime == null
                      ? 'Select available time'
                      : selectedTime!.format(context),
                  onTap: selectTime,
                ),
              ),
            ],
          ),

          const SizedBox(height: 26),

          buildSectionTitle('Notes'),

          const SizedBox(height: 8),

          TextField(
            controller: notesController,
            maxLines: 3,

            decoration: InputDecoration(
              hintText: 'Add notes about this appointment...',

              hintStyle: const TextStyle(color: tanzeemMuted, fontSize: 13),

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
            ),
          ),

          const SizedBox(height: 26),

          Container(
            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(
              color: tanzeemDarkGreen,
              borderRadius: BorderRadius.circular(18),
            ),

            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'Appointment summary',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const Spacer(),

                    Text(
                      '${selectedServices.length} service${selectedServices.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Duration',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 11,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            '$totalDuration min',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      width: 1,
                      height: 38,
                      color: Colors.white.withOpacity(0.15),
                    ),

                    const SizedBox(width: 20),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 11,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            CurrencyFormatter.usd(totalPrice),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            height: 54,

            child: ElevatedButton(
              onPressed: isSaving ? null : saveAppointment,

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
                      'Save Appointment',
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
