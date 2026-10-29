import 'package:flutter/material.dart';

import '../auth/auth_session.dart';

import 'dart:convert';

import '../config/api_config.dart';

import 'package:http/http.dart' as http;

import '../models/appointment.dart';
import '../models/client.dart';
import '../models/service.dart';
import 'new_appointment_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<Client> clients;
  final List<Service> services;
  final List<Appointment> appointments;
  final VoidCallback onSeeAllAppointments;

  const HomeScreen({
    super.key,
    required this.clients,
    required this.services,
    required this.appointments,
    required this.onSeeAllAppointments,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color tanzeemGreen = Color(0xFF0B5F4A);
  static const Color tanzeemDarkGreen = Color(0xFF073B31);
  static const Color tanzeemMint = Color(0xFFE4F5EF);
  static const Color tanzeemBackground = Color(0xFFF7F9F8);
  static const Color tanzeemText = Color(0xFF18221F);
  static const Color tanzeemMuted = Color(0xFF6F7D77);

  bool isLoading = true;
  bool get isOwner => AuthSession.role == 'OWNER';

  int get completedCount {
    return widget.appointments
        .where(
          (appointment) => appointment.status == AppointmentStatus.completed,
        )
        .length;
  }

  @override
  void initState() {
    super.initState();
    loadAppointments();
  }

  Future<void> loadAppointments() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/appointments'),
        headers: {'Authorization': 'Bearer ${AuthSession.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

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
      print('Failed to connect to backend: $error');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> addAppointment() async {
    final Appointment? newAppointment = await Navigator.push<Appointment>(
      context,
      MaterialPageRoute(
        builder: (context) => NewAppointmentScreen(
          clients: widget.clients,
          services: widget.services,
        ),
      ),
    );

    if (newAppointment != null) {
      await loadAppointments();
    }
  }

  bool isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  List<Appointment> get todayAppointments {
    final now = DateTime.now();

    final appointments = widget.appointments.where((appointment) {
      return isSameDay(appointment.dateTime, now) &&
          appointment.status != AppointmentStatus.cancelled;
    }).toList();

    appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return appointments;
  }

  int get thisWeekCount {
    final now = DateTime.now();

    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));

    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    return widget.appointments.where((appointment) {
      return appointment.dateTime.isAfter(
            startOfWeek.subtract(const Duration(seconds: 1)),
          ) &&
          appointment.dateTime.isBefore(endOfWeek) &&
          appointment.status != AppointmentStatus.cancelled;
    }).length;
  }

  double get completedRevenue {
    return widget.appointments
        .where(
          (appointment) => appointment.status == AppointmentStatus.completed,
        )
        .fold(0, (total, appointment) => total + appointment.totalPrice);
  }

  String get greeting {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning';
    }

    if (hour < 18) {
      return 'Good afternoon';
    }

    return 'Good evening';
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

  String formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return '${weekdays[date.weekday - 1]}, '
        '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: tanzeemMint,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: tanzeemGreen),

            const SizedBox(height: 12),

            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: tanzeemText,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              label,
              style: const TextStyle(fontSize: 11, color: tanzeemMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStatusBadge(Appointment appointment) {
    String text;
    Color background;
    Color foreground;

    switch (appointment.status) {
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
        background = const Color(0xFFE4F5EF);
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

  Widget buildAppointmentCard(Appointment appointment) {
    final serviceNames = appointment.services
        .map((service) => service.name)
        .join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECEA)),
      ),

      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tanzeemMint,
              shape: BoxShape.circle,
            ),
            child: Text(
              appointment.client.firstName.isNotEmpty
                  ? appointment.client.firstName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: tanzeemGreen,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      formatTime(appointment.dateTime),
                      style: const TextStyle(
                        fontSize: 12,
                        color: tanzeemMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        appointment.client.fullName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: tanzeemText,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  serviceNames,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: tanzeemMuted),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          buildStatusBadge(appointment),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = todayAppointments;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: tanzeemBackground,

      body: SafeArea(
        child: RefreshIndicator(
          color: tanzeemGreen,
          onRefresh: loadAppointments,

          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),

            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          '$greeting,',
                          style: const TextStyle(
                            color: tanzeemMuted,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          AuthSession.firstName != null &&
                                  AuthSession.firstName!.trim().isNotEmpty
                              ? 'Welcome back, ${AuthSession.firstName} 👋'
                              : 'Welcome back 👋',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: tanzeemText,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          formatDate(now),
                          style: const TextStyle(
                            fontSize: 13,
                            color: tanzeemMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              Row(
                children: [
                  buildStatCard(
                    icon: Icons.calendar_today_outlined,
                    value: today.length.toString(),
                    label: 'Today',
                  ),

                  const SizedBox(width: 10),

                  buildStatCard(
                    icon: Icons.date_range_outlined,
                    value: thisWeekCount.toString(),
                    label: 'This week',
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  if (isOwner)
                    buildStatCard(
                      icon: Icons.attach_money_rounded,
                      value: '\$${completedRevenue.toStringAsFixed(0)}',
                      label: 'Revenue',
                    )
                  else
                    buildStatCard(
                      icon: Icons.check_circle_outline_rounded,
                      value: completedCount.toString(),
                      label: 'Completed',
                    ),

                  const SizedBox(width: 10),

                  buildStatCard(
                    icon: Icons.people_outline_rounded,
                    value: widget.clients.length.toString(),
                    label: 'Customers',
                  ),
                ],
              ),
              const SizedBox(height: 30),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Today's Appointments",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: tanzeemText,
                      ),
                    ),
                  ),

                  TextButton(
                    onPressed: widget.onSeeAllAppointments,
                    child: const Text(
                      'See all',
                      style: TextStyle(
                        color: tanzeemGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 50),
                  child: Center(
                    child: CircularProgressIndicator(color: tanzeemGreen),
                  ),
                )
              else if (today.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 30,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8ECEA)),
                  ),

                  child: const Column(
                    children: [
                      Icon(
                        Icons.event_available_outlined,
                        size: 38,
                        color: tanzeemGreen,
                      ),

                      SizedBox(height: 12),

                      Text(
                        'No appointments today',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: tanzeemText,
                        ),
                      ),

                      SizedBox(height: 4),

                      Text(
                        'Your schedule is clear.',
                        style: TextStyle(color: tanzeemMuted, fontSize: 13),
                      ),
                    ],
                  ),
                )
              else
                ...today.map(buildAppointmentCard),

              const SizedBox(height: 22),

              SizedBox(
                height: 54,

                child: ElevatedButton.icon(
                  onPressed: addAppointment,

                  icon: const Icon(Icons.add_rounded),

                  label: const Text(
                    'New Appointment',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: tanzeemGreen,
                    foregroundColor: Colors.white,

                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
