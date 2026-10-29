import 'package:flutter/material.dart';

import '../utils/currency_formatter.dart';
import '../config/api_config.dart';
import '../auth/auth_session.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/appointment.dart';
import '../models/client.dart';
import '../models/service.dart';
import 'edit_appointment_screen.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final Appointment appointment;
  final List<Client> clients;
  final List<Service> services;

  const AppointmentDetailsScreen({
    super.key,
    required this.appointment,
    required this.clients,
    required this.services,
  });

  @override
  State<AppointmentDetailsScreen> createState() =>
      _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  static const Color tanzeemGreen = Color(0xFF0B5F4A);
  static const Color tanzeemDarkGreen = Color(0xFF073B31);
  static const Color tanzeemMint = Color(0xFFE4F5EF);
  static const Color tanzeemBackground = Color(0xFFF7F9F8);
  static const Color tanzeemText = Color(0xFF18221F);
  static const Color tanzeemMuted = Color(0xFF6F7D77);

  late Appointment appointment;

  bool isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    appointment = widget.appointment;
  }

  String get statusText {
    switch (appointment.status) {
      case AppointmentStatus.confirmed:
        return 'Upcoming';

      case AppointmentStatus.completed:
        return 'Completed';

      case AppointmentStatus.cancelled:
        return 'Cancelled';
    }
  }

  Future<void> editAppointment() async {
    final Appointment? updatedAppointment = await Navigator.push<Appointment>(
      context,
      MaterialPageRoute(
        builder: (context) => EditAppointmentScreen(
          appointment: appointment,
          clients: widget.clients,
          services: widget.services,
        ),
      ),
    );

    if (updatedAppointment != null) {
      setState(() {
        appointment = updatedAppointment;
      });
    }
  }

  Future<void> updateAppointmentStatus(
    String backendStatus,
    AppointmentStatus localStatus,
  ) async {
    if (appointment.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment does not have a database ID'),
        ),
      );
      return;
    }

    setState(() {
      isUpdatingStatus = true;
    });

    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/appointments/${appointment.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthSession.token}',
        },
        body: jsonEncode({'status': backendStatus}),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;

        setState(() {
          appointment.status = localStatus;
        });
      } else {
        print(response.statusCode);
        print(response.body);

        String message = 'Failed to update appointment status';

        try {
          final data = jsonDecode(response.body);

          if (data['message'] != null) {
            message = data['message'].toString();
          }
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
          isUpdatingStatus = false;
        });
      }
    }
  }

  Future<void> completeAppointment() async {
    await updateAppointmentStatus('COMPLETED', AppointmentStatus.completed);
  }

  Future<void> cancelAppointment() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Appointment'),
          content: const Text(
            'Are you sure you want to cancel this appointment?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Keep Appointment'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Cancel Appointment'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await updateAppointmentStatus('CANCELLED', AppointmentStatus.cancelled);
  }

  String formatDate(DateTime date) {
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

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget buildStatusBadge() {
    Color background;
    Color foreground;

    switch (appointment.status) {
      case AppointmentStatus.completed:
        background = const Color(0xFFE1F5EA);
        foreground = const Color(0xFF158353);
        break;

      case AppointmentStatus.cancelled:
        background = const Color(0xFFFDE8E8);
        foreground = const Color(0xFFC53B3B);
        break;

      case AppointmentStatus.confirmed:
        background = tanzeemMint;
        foreground = tanzeemGreen;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: tanzeemMint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: tanzeemGreen, size: 20),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: tanzeemMuted),
              ),

              const SizedBox(height: 3),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: tanzeemText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(appointment.dateTime).format(context);

    return Scaffold(
      backgroundColor: tanzeemBackground,

      appBar: AppBar(
        backgroundColor: tanzeemBackground,
        elevation: 0,
        surfaceTintColor: tanzeemBackground,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: tanzeemText),
          onPressed: () {
            Navigator.pop(context, appointment);
          },
        ),

        title: const Text(
          'Appointment Details',
          style: TextStyle(color: tanzeemText, fontWeight: FontWeight.w700),
        ),

        actions: [
          if (appointment.status == AppointmentStatus.confirmed)
            IconButton(
              onPressed: editAppointment,
              icon: const Icon(Icons.edit_outlined, color: tanzeemGreen),
            ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE8ECEA)),
            ),
            child: Column(
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
                        appointment.client.firstName.isNotEmpty
                            ? appointment.client.firstName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: tanzeemGreen,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment.client.fullName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: tanzeemText,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            appointment.client.phone,
                            style: const TextStyle(
                              color: tanzeemMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    buildStatusBadge(),
                  ],
                ),

                const SizedBox(height: 22),

                buildInfoRow(
                  icon: Icons.calendar_today_outlined,
                  title: 'Date',
                  value: formatDate(appointment.dateTime),
                ),

                const SizedBox(height: 16),

                buildInfoRow(
                  icon: Icons.access_time_rounded,
                  title: 'Time',
                  value: time,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Services',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: tanzeemText,
            ),
          ),

          const SizedBox(height: 10),

          ...appointment.services.map(
            (service) => Container(
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
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: tanzeemMint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.spa_outlined,
                      color: tanzeemGreen,
                      size: 20,
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
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          '${service.duration} min',
                          style: const TextStyle(
                            color: tanzeemMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Text(
                    CurrencyFormatter.usd(service.price),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: tanzeemDarkGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

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
                        '${appointment.totalDuration} min',
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
                        CurrencyFormatter.usd(appointment.totalPrice),
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

          if (appointment.notes != null &&
              appointment.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 22),

            const Text(
              'Notes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: tanzeemText,
              ),
            ),

            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8ECEA)),
              ),
              child: Text(
                appointment.notes!,
                style: const TextStyle(color: tanzeemText, height: 1.5),
              ),
            ),
          ],

          if (appointment.status == AppointmentStatus.confirmed) ...[
            const SizedBox(height: 28),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isUpdatingStatus ? null : completeAppointment,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Mark Completed'),
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

            const SizedBox(height: 10),

            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: isUpdatingStatus ? null : cancelAppointment,
                icon: const Icon(Icons.close_rounded),
                label: const Text('Cancel Appointment'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFC53B3B),
                  side: const BorderSide(color: Color(0xFFE8B7B7)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
