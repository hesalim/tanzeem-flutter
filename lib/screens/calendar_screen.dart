import 'package:flutter/material.dart';

import '../auth/auth_session.dart';
import '../utils/currency_formatter.dart';

import 'dart:convert';

import '../config/api_config.dart';

import 'package:http/http.dart' as http;

import '../models/staff.dart';
import '../models/appointment.dart';
import '../models/client.dart';
import '../models/service.dart';
import 'appointment_details_screen.dart';

class CalendarScreen extends StatefulWidget {
  final List<Appointment> appointments;
  final List<Client> clients;
  final List<Service> services;

  const CalendarScreen({
    super.key,
    required this.appointments,
    required this.clients,
    required this.services,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const Color tanzeemGreen = Color(0xFF0B5F4A);
  static const Color tanzeemDarkGreen = Color(0xFF073B31);
  static const Color tanzeemMint = Color(0xFFE4F5EF);
  static const Color tanzeemBackground = Color(0xFFF7F9F8);
  static const Color tanzeemText = Color(0xFF18221F);
  static const Color tanzeemMuted = Color(0xFF6F7D77);

  DateTime selectedDate = DateTime.now();

  bool isLoading = true;
  bool get isOwner => AuthSession.role == 'OWNER';

  final Map<int, String> appointmentStaffNames = {};
  final Map<int, int> appointmentStaffIds = {};

  final List<Staff> staffMembers = [];

  int? selectedStaffId;

  @override
  void initState() {
    super.initState();
    loadCalendarData();
  }

  Future<void> loadCalendarData() async {
    if (isOwner) {
      await loadStaff();
    }

    await loadAppointments();
  }

  Future<void> loadStaff() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/staff'),
        headers: {'Authorization': 'Bearer ${AuthSession.token}'},
      );

      if (response.statusCode != 200) {
        print('Failed to load staff');
        print(response.body);
        return;
      }

      final List<dynamic> data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        staffMembers.clear();

        staffMembers.addAll(
          data.map((item) => Staff.fromJson(Map<String, dynamic>.from(item))),
        );
      });
    } catch (error) {
      print('Failed to load staff: $error');
    }
  }

  Future<void> loadAppointments() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/appointments'),
        headers: {'Authorization': 'Bearer ${AuthSession.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        appointmentStaffNames.clear();
        appointmentStaffIds.clear();

        final loadedAppointments = data.map((item) {
          final client = Client(
            id: item['customer_id'],
            firstName: item['customer_first_name'],
            lastName: item['customer_last_name'],
            phone: item['customer_phone'],
          );

          final List<Service> appointmentServices =
              (item['services'] as List<dynamic>).map((service) {
                return Service(
                  id: service['id'],
                  name: service['name'],
                  duration: service['duration_minutes'],
                  price: double.parse(service['price'].toString()),
                  bookingType: 'Individual',
                );
              }).toList();

          AppointmentStatus status;

          switch (item['status']) {
            case 'COMPLETED':
              status = AppointmentStatus.completed;
              break;

            case 'CANCELLED':
              status = AppointmentStatus.cancelled;
              break;

            default:
              status = AppointmentStatus.confirmed;
          }

          final int appointmentId = int.parse(item['id'].toString());

          final String firstName = item['staff_first_name']?.toString() ?? '';

          final String lastName = item['staff_last_name']?.toString() ?? '';

          final String staffName = '$firstName $lastName'.trim();

          appointmentStaffNames[appointmentId] = staffName.isEmpty
              ? 'Team member'
              : staffName;

          appointmentStaffIds[appointmentId] = int.parse(
            item['staff_id'].toString(),
          );

          return Appointment(
            id: item['id'],
            client: client,
            services: appointmentServices,
            dateTime: DateTime.parse(item['start_at']),
            notes: item['notes'],
            status: status,
          );
        }).toList();

        if (!mounted) return;

        setState(() {
          widget.appointments.clear();
          widget.appointments.addAll(loadedAppointments);
          isLoading = false;
        });
      } else {
        print('Failed to load appointments');
        print(response.body);

        if (!mounted) return;

        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      print('Failed to load appointments: $error');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  bool isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  List<Appointment> get selectedDayAppointments {
    final appointments = widget.appointments.where((appointment) {
      if (!isSameDay(appointment.dateTime, selectedDate)) {
        return false;
      }

      if (isOwner && selectedStaffId != null && appointment.id != null) {
        final appointmentStaffId = appointmentStaffIds[appointment.id!];

        if (appointmentStaffId != selectedStaffId) {
          return false;
        }
      }

      return true;
    }).toList();

    appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return appointments;
  }

  Future<void> chooseDate() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
  }

  void previousDay() {
    setState(() {
      selectedDate = selectedDate.subtract(const Duration(days: 1));
    });
  }

  void nextDay() {
    setState(() {
      selectedDate = selectedDate.add(const Duration(days: 1));
    });
  }

  List<DateTime> get weekDays {
    final startOfWeek = selectedDate.subtract(
      Duration(days: selectedDate.weekday - 1),
    );

    return List.generate(
      7,
      (index) => DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day + index,
      ),
    );
  }

  String formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');

    final displayHour = hour == 0
        ? 12
        : hour > 12
        ? hour - 12
        : hour;

    final period = hour >= 12 ? 'PM' : 'AM';

    return '$displayHour:$minute $period';
  }

  String monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  String shortWeekday(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return weekdays[weekday - 1];
  }

  Widget buildStatusBadge(AppointmentStatus status) {
    String text;
    Color background;
    Color foreground;

    switch (status) {
      case AppointmentStatus.completed:
        text = 'Completed';
        background = const Color(0xFFE1F5EA);
        foreground = const Color(0xFF158353);
        break;

      case AppointmentStatus.cancelled:
        text = 'Cancelled';
        background = const Color(0xFFFDE8E8);
        foreground = const Color(0xFFC53B3B);
        break;

      case AppointmentStatus.confirmed:
        text = 'Upcoming';
        background = tanzeemMint;
        foreground = tanzeemGreen;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color appointmentAccent(Appointment appointment) {
    switch (appointment.status) {
      case AppointmentStatus.completed:
        return const Color(0xFF66CFA0);

      case AppointmentStatus.cancelled:
        return const Color(0xFFE98B8B);

      case AppointmentStatus.confirmed:
        return tanzeemGreen;
    }
  }

  Future<void> openAppointment(Appointment appointment) async {
    final Appointment? updatedAppointment = await Navigator.push<Appointment>(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentDetailsScreen(
          appointment: appointment,
          clients: widget.clients,
          services: widget.services,
        ),
      ),
    );

    if (updatedAppointment != null) {
      await loadAppointments();
    }
  }

  Widget buildWeekStrip() {
    final days = weekDays;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((date) {
        final selected = isSameDay(date, selectedDate);

        return GestureDetector(
          onTap: () {
            setState(() {
              selectedDate = date;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 42,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: selected ? tanzeemGreen : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  shortWeekday(date.weekday),
                  style: TextStyle(
                    fontSize: 10,
                    color: selected
                        ? Colors.white.withOpacity(0.85)
                        : tanzeemMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  date.day.toString(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : tanzeemText,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String staffNameFor(Appointment appointment) {
    if (appointment.id == null) {
      return 'Team member';
    }

    return appointmentStaffNames[appointment.id!] ?? 'Team member';
  }

  Widget buildStaffFilters() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('All'),
              selected: selectedStaffId == null,
              onSelected: (_) {
                setState(() {
                  selectedStaffId = null;
                });
              },
              selectedColor: tanzeemGreen,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: selectedStaffId == null ? Colors.white : tanzeemText,
                fontWeight: FontWeight.w600,
              ),
              side: const BorderSide(color: Color(0xFFE8ECEA)),
              showCheckmark: false,
            ),
          ),

          ...staffMembers.map((staff) {
            final selected = selectedStaffId == staff.id;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(staff.isOwner ? 'Owner' : staff.firstName),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    selectedStaffId = staff.id;
                  });
                },
                selectedColor: tanzeemGreen,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : tanzeemText,
                  fontWeight: FontWeight.w600,
                ),
                side: const BorderSide(color: Color(0xFFE8ECEA)),
                showCheckmark: false,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget buildAppointmentCard(Appointment appointment) {
    final services = appointment.services
        .map((service) => service.name)
        .join(', ');

    return InkWell(
      onTap: () {
        openAppointment(appointment);
      },
      borderRadius: BorderRadius.circular(16),

      child: Container(
        margin: const EdgeInsets.only(bottom: 12),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8ECEA)),
        ),

        child: Row(
          children: [
            Container(
              width: 5,
              height: isOwner ? 132 : 112,
              decoration: BoxDecoration(
                color: appointmentAccent(appointment),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),

                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    SizedBox(
                      width: 72,

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            formatTime(appointment.dateTime),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: tanzeemText,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            '${appointment.totalDuration} min',
                            style: const TextStyle(
                              fontSize: 11,
                              color: tanzeemMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            appointment.client.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: tanzeemText,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            services,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: tanzeemMuted,
                              fontSize: 12,
                            ),
                          ),

                          if (isOwner) ...[
                            const SizedBox(height: 6),

                            Row(
                              children: [
                                const Icon(
                                  Icons.person_outline_rounded,
                                  size: 14,
                                  color: tanzeemGreen,
                                ),

                                const SizedBox(width: 4),

                                Expanded(
                                  child: Text(
                                    staffNameFor(appointment),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: tanzeemGreen,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 9),

                          Row(
                            children: [
                              buildStatusBadge(appointment.status),

                              const Spacer(),

                              Text(
                                CurrencyFormatter.usd(appointment.totalPrice),
                                style: const TextStyle(
                                  color: tanzeemDarkGreen,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointments = selectedDayAppointments;

    return Scaffold(
      backgroundColor: tanzeemBackground,

      body: SafeArea(
        child: RefreshIndicator(
          color: tanzeemGreen,
          onRefresh: loadCalendarData,

          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),

            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),

                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const Text(
                      'Calendar',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                        color: tanzeemText,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE8ECEA)),
                      ),

                      child: Row(
                        children: [
                          IconButton(
                            onPressed: previousDay,
                            icon: const Icon(Icons.chevron_left_rounded),
                          ),

                          Expanded(
                            child: InkWell(
                              onTap: chooseDate,

                              child: Column(
                                children: [
                                  Text(
                                    '${selectedDate.day} ${monthName(selectedDate.month)} ${selectedDate.year}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: tanzeemText,
                                    ),
                                  ),

                                  const SizedBox(height: 2),

                                  const Text(
                                    'Tap to choose date',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: tanzeemMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          IconButton(
                            onPressed: nextDay,
                            icon: const Icon(Icons.chevron_right_rounded),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE8ECEA)),
                      ),
                      child: buildWeekStrip(),
                    ),

                    const SizedBox(height: 20),

                    if (isOwner) ...[
                      buildStaffFilters(),

                      const SizedBox(height: 20),
                    ],

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${appointments.length} appointment${appointments.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: tanzeemText,
                            ),
                          ),
                        ),

                        Text(
                          '${selectedDate.day} ${monthName(selectedDate.month)}',
                          style: const TextStyle(
                            color: tanzeemMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                  ]),
                ),
              ),

              if (isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(color: tanzeemGreen),
                  ),
                )
              else if (appointments.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,

                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30),

                      child: Column(
                        mainAxisSize: MainAxisSize.min,

                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: tanzeemMint,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.event_available_outlined,
                              size: 30,
                              color: tanzeemGreen,
                            ),
                          ),

                          const SizedBox(height: 16),

                          const Text(
                            'No appointments',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: tanzeemText,
                            ),
                          ),

                          const SizedBox(height: 5),

                          const Text(
                            'Nothing scheduled for this day.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: tanzeemMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),

                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return buildAppointmentCard(appointments[index]);
                    }, childCount: appointments.length),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
