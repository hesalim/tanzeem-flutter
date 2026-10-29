import 'package:flutter/material.dart';

import '../auth/auth_session.dart';

import 'dart:convert';

import '../config/api_config.dart';
import '../utils/currency_formatter.dart';

import 'package:http/http.dart' as http;

import '../models/appointment.dart';
import '../models/client.dart';
import '../models/service.dart';
import '../models/staff.dart';

class EditAppointmentScreen extends StatefulWidget {
  final Appointment appointment;
  final List<Client> clients;
  final List<Service> services;

  const EditAppointmentScreen({
    super.key,
    required this.appointment,
    required this.clients,
    required this.services,
  });

  @override
  State<EditAppointmentScreen> createState() => _EditAppointmentScreenState();
}

class _EditAppointmentScreenState extends State<EditAppointmentScreen> {
  static const Color tanzeemGreen = Color(0xFF0B5F4A);
  static const Color tanzeemDarkGreen = Color(0xFF073B31);
  static const Color tanzeemMint = Color(0xFFE4F5EF);
  static const Color tanzeemBackground = Color(0xFFF7F9F8);
  static const Color tanzeemText = Color(0xFF18221F);
  static const Color tanzeemMuted = Color(0xFF6F7D77);

  late Client selectedClient;
  late List<Service> selectedServices;
  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  Staff? selectedStaff;

  final List<Map<String, dynamic>> availableSlots = [];

  bool isLoadingSlots = false;

  final List<Staff> staffMembers = [];
  final List<Service> availableServices = [];

  bool isLoading = true;

  bool get isOwner => AuthSession.role == 'OWNER';

  late TextEditingController notesController;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    selectedClient = widget.appointment.client;

    selectedServices = List<Service>.from(widget.appointment.services);

    selectedDate = widget.appointment.dateTime;

    selectedTime = TimeOfDay.fromDateTime(widget.appointment.dateTime);

    notesController = TextEditingController(
      text: widget.appointment.notes ?? '',
    );
    loadEditData();
  }

  Future<void> loadEditData() async {
    try {
      if (isOwner) {
        await loadStaff();

        await loadCurrentAppointmentStaff();
      } else {
        if (AuthSession.staffId == null) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Staff account is not linked correctly'),
            ),
          );

          setState(() {
            isLoading = false;
          });

          return;
        }

        selectedStaff = Staff(
          id: AuthSession.staffId!,
          userId: AuthSession.userId,
          firstName: AuthSession.firstName ?? 'Staff',
          lastName: AuthSession.lastName,
          phone: null,
          email: AuthSession.email,
          isOwner: false,
          isActive: true,
        );
      }

      if (selectedStaff != null) {
        await loadServicesForStaff(
          selectedStaff!,
          preserveCurrentSelection: true,
        );
      }
    } catch (error) {
      print('Edit appointment initialization error: $error');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> loadStaff() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/staff'),
      headers: {'Authorization': 'Bearer ${AuthSession.token}'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load staff');
    }

    final List<dynamic> data = jsonDecode(response.body);

    staffMembers.clear();

    staffMembers.addAll(
      data.map((item) => Staff.fromJson(Map<String, dynamic>.from(item))),
    );
  }

  Future<void> loadCurrentAppointmentStaff() async {
    if (widget.appointment.id == null) {
      return;
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/appointments'),
      headers: {'Authorization': 'Bearer ${AuthSession.token}'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load appointment staff');
    }

    final List<dynamic> data = jsonDecode(response.body);

    final currentAppointment = data.firstWhere(
      (item) => item['id'].toString() == widget.appointment.id.toString(),
      orElse: () => null,
    );

    if (currentAppointment == null) {
      return;
    }

    final int currentStaffId = int.parse(
      currentAppointment['staff_id'].toString(),
    );

    for (final staff in staffMembers) {
      if (staff.id == currentStaffId) {
        selectedStaff = staff;
        break;
      }
    }
  }

  Future<void> loadServicesForStaff(
    Staff staff, {
    bool preserveCurrentSelection = false,
  }) async {
    final previousServiceIds = preserveCurrentSelection
        ? selectedServices
              .where((service) => service.id != null)
              .map((service) => service.id!)
              .toSet()
        : <int>{};

    availableServices.clear();

    if (staff.isOwner) {
      availableServices.addAll(widget.services);
    } else {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/staff-services?staffId=${staff.id}',
        ),
        headers: {'Authorization': 'Bearer ${AuthSession.token}'},
      );

      if (response.statusCode != 200) {
        String message = 'Failed to load services';

        try {
          final data = jsonDecode(response.body);

          message = data['message']?.toString() ?? message;
        } catch (_) {}

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));

        return;
      }

      final List<dynamic> data = jsonDecode(response.body);

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
    }

    if (preserveCurrentSelection) {
      selectedServices = availableServices.where((service) {
        return service.id != null && previousServiceIds.contains(service.id);
      }).toList();
    } else {
      selectedServices.clear();
    }

    if (mounted) {
      setState(() {});
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

  Future<void> loadAvailableSlots() async {
    if (selectedStaff == null || selectedServices.isEmpty) {
      setState(() {
        availableSlots.clear();
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
    });

    try {
      final date = formatDateForApi(selectedDate);

      final appointmentId = widget.appointment.id;

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/slots'
          '?date=$date'
          '&staffId=${selectedStaff!.id}'
          '&serviceIds=$serviceIds'
          '&excludeAppointmentId=$appointmentId',
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
      print('LOAD EDIT SLOTS ERROR: $error');

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

  String formatDateForApi(DateTime date) {
    final year = date.year.toString();

    final month = date.month.toString().padLeft(2, '0');

    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  Future<void> selectClient() async {
    final Client? client = await showModalBottomSheet<Client>(
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
              children: [
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

                const SizedBox(height: 12),

                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: widget.clients.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final client = widget.clients[index];

                      return ListTile(
                        contentPadding: EdgeInsets.zero,

                        leading: CircleAvatar(
                          backgroundColor: tanzeemMint,
                          child: Text(
                            client.firstName.isNotEmpty
                                ? client.firstName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: tanzeemGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        title: Text(
                          client.fullName,
                          style: const TextStyle(
                            color: tanzeemText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        subtitle: Text(
                          client.phone,
                          style: const TextStyle(color: tanzeemMuted),
                        ),

                        onTap: () {
                          Navigator.pop(context, client);
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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

                const SizedBox(height: 12),

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

    Future<void> selectDate() async {
      final DateTime? date = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );

      if (date == null) {
        return;
      }

      setState(() {
        selectedDate = date;
        availableSlots.clear();
      });

      await loadAvailableSlots();
    }
  }

  Future<void> selectDate() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
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
                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
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

  Future<void> saveChanges() async {
    if (selectedStaff == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Team member is required')));

      return;
    }
    if (selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one service')),
      );

      return;
    }

    if (widget.appointment.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment does not have a database ID'),
        ),
      );

      return;
    }

    if (selectedClient.id == null) {
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

    final updatedDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    final endDateTime = updatedDateTime.add(Duration(minutes: totalDuration));

    setState(() {
      isSaving = true;
    });

    try {
      final response = await http.put(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/appointments/${widget.appointment.id}',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthSession.token}',
        },
        body: jsonEncode({
          'customerId': selectedClient.id,
          'staffId': selectedStaff!.id,
          'startAt': updatedDateTime.toIso8601String(),
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

      if (response.statusCode == 200) {
        final updatedAppointment = Appointment(
          id: widget.appointment.id,
          client: selectedClient,
          services: List<Service>.from(selectedServices),
          dateTime: updatedDateTime,
          notes: notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
          status: widget.appointment.status,
        );

        if (!mounted) return;

        Navigator.pop(context, updatedAppointment);
      } else {
        print(response.statusCode);
        print(response.body);

        String message = 'Failed to update appointment';

        try {
          final data = jsonDecode(response.body);

          message = data['message']?.toString() ?? message;
        } catch (_) {}

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    service.name,
                    style: const TextStyle(
                      color: tanzeemText,
                      fontWeight: FontWeight.w600,
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

            Container(
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
          'Edit Appointment',
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
            title: selectedClient.fullName,
            subtitle: selectedClient.phone,
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

              Text(
                '${selectedServices.length} selected',
                style: const TextStyle(
                  color: tanzeemGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          if (selectedStaff == null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8ECEA)),
              ),
              child: const Text(
                'Select a team member first.',
                style: TextStyle(color: tanzeemMuted),
              ),
            )
          else if (availableServices.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8ECEA)),
              ),
              child: const Text(
                'No services are assigned to this team member.',
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
                  subtitle:
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
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
                      : selectedTime.format(context),
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

            child: Row(
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
          ),

          const SizedBox(height: 18),

          SizedBox(
            height: 54,

            child: ElevatedButton(
              onPressed: isSaving ? null : saveChanges,

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
