import 'dart:convert';

import '../config/api_config.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../auth/auth_session.dart';

class BusinessHoursScreen extends StatefulWidget {
  const BusinessHoursScreen({super.key});

  @override
  State<BusinessHoursScreen> createState() => _BusinessHoursScreenState();
}

class _BusinessHoursScreenState extends State<BusinessHoursScreen> {
  static const Color tanzeemGreen = Color(0xFF0B5F4A);

  static const Color tanzeemDarkGreen = Color(0xFF073B31);

  static const Color tanzeemMint = Color(0xFFE4F5EF);

  static const Color tanzeemBackground = Color(0xFFF7F9F8);

  static const Color tanzeemText = Color(0xFF18221F);

  static const Color tanzeemMuted = Color(0xFF6F7D77);

  bool isLoading = true;
  bool isSaving = false;

  late List<BusinessHourDay> days;

  @override
  void initState() {
    super.initState();

    days = [
      BusinessHourDay(dayOfWeek: 1, name: 'Monday'),
      BusinessHourDay(dayOfWeek: 2, name: 'Tuesday'),
      BusinessHourDay(dayOfWeek: 3, name: 'Wednesday'),
      BusinessHourDay(dayOfWeek: 4, name: 'Thursday'),
      BusinessHourDay(dayOfWeek: 5, name: 'Friday'),
      BusinessHourDay(dayOfWeek: 6, name: 'Saturday'),
      BusinessHourDay(dayOfWeek: 7, name: 'Sunday'),
    ];

    loadBusinessHours();
  }

  Future<void> loadBusinessHours() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/business-hours'),
        headers: {'Authorization': 'Bearer ${AuthSession.token}'},
      );

      if (response.statusCode != 200) {
        String message = 'Failed to load business hours';

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

      for (final item in data) {
        final int dayOfWeek = int.parse(item['day_of_week'].toString());

        final BusinessHourDay day = days.firstWhere(
          (day) => day.dayOfWeek == dayOfWeek,
        );

        final dynamic openValue = item['is_open'];

        day.isOpen =
            openValue == true || openValue == 1 || openValue.toString() == '1';

        day.openTime = parseDatabaseTime(item['open_time']?.toString());

        day.closeTime = parseDatabaseTime(item['close_time']?.toString());
      }
    } catch (error) {
      print('LOAD BUSINESS HOURS ERROR: $error');

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

  TimeOfDay? parseDatabaseTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final parts = value.split(':');

    if (parts.length < 2) {
      return null;
    }

    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String formatApiTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');

    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  Future<void> selectOpenTime(BusinessHourDay day) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: day.openTime ?? const TimeOfDay(hour: 8, minute: 0),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      day.openTime = selected;
    });
  }

  Future<void> selectCloseTime(BusinessHourDay day) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: day.closeTime ?? const TimeOfDay(hour: 20, minute: 0),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      day.closeTime = selected;
    });
  }

  Future<void> saveBusinessHours() async {
    for (final day in days) {
      if (!day.isOpen) {
        continue;
      }

      if (day.openTime == null || day.closeTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select opening hours for ${day.name}'),
          ),
        );

        return;
      }

      final openMinutes = day.openTime!.hour * 60 + day.openTime!.minute;

      final closeMinutes = day.closeTime!.hour * 60 + day.closeTime!.minute;

      if (closeMinutes <= openMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${day.name}: closing time must be after opening time',
            ),
          ),
        );

        return;
      }
    }

    setState(() {
      isSaving = true;
    });

    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/business-hours'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthSession.token}',
        },
        body: jsonEncode({
          'hours': days.map((day) {
            return {
              'dayOfWeek': day.dayOfWeek,

              'isOpen': day.isOpen,

              'openTime': day.isOpen && day.openTime != null
                  ? formatApiTime(day.openTime!)
                  : null,

              'closeTime': day.isOpen && day.closeTime != null
                  ? formatApiTime(day.closeTime!)
                  : null,
            };
          }).toList(),
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Business hours saved')));

        Navigator.pop(context, true);
      } else {
        String message = 'Failed to save business hours';

        try {
          final data = jsonDecode(response.body);

          message = data['message']?.toString() ?? message;
        } catch (_) {}

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (error) {
      print('SAVE BUSINESS HOURS ERROR: $error');

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

  Widget buildTimeButton({
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8ECEA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: tanzeemMuted, fontSize: 10),
              ),

              const SizedBox(height: 3),

              Text(
                time == null ? '--:--' : time.format(context),
                style: const TextStyle(
                  color: tanzeemText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDayCard(BusinessHourDay day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECEA)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  day.name,
                  style: const TextStyle(
                    color: tanzeemText,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              Text(
                day.isOpen ? 'Open' : 'Closed',
                style: TextStyle(
                  color: day.isOpen ? tanzeemGreen : tanzeemMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(width: 8),

              Switch(
                value: day.isOpen,
                activeColor: tanzeemGreen,
                onChanged: (value) {
                  setState(() {
                    day.isOpen = value;

                    if (value) {
                      day.openTime ??= const TimeOfDay(hour: 8, minute: 0);

                      day.closeTime ??= const TimeOfDay(hour: 20, minute: 0);
                    }
                  });
                },
              ),
            ],
          ),

          if (day.isOpen) ...[
            const SizedBox(height: 12),

            Row(
              children: [
                buildTimeButton(
                  label: 'Opens',
                  time: day.openTime,
                  onTap: () {
                    selectOpenTime(day);
                  },
                ),

                const SizedBox(width: 10),

                buildTimeButton(
                  label: 'Closes',
                  time: day.closeTime,
                  onTap: () {
                    selectCloseTime(day);
                  },
                ),
              ],
            ),
          ],
        ],
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
          'Business Hours',
          style: TextStyle(color: tanzeemText, fontWeight: FontWeight.w700),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: tanzeemGreen))
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: tanzeemMint,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.storefront_outlined,
                                  color: tanzeemGreen,
                                ),
                              ),

                              SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Regular opening hours',
                                      style: TextStyle(
                                        color: tanzeemDarkGreen,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),

                                    SizedBox(height: 3),

                                    Text(
                                      'Set when your business is normally open each week',
                                      style: TextStyle(
                                        color: tanzeemMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        ...days.map(buildDayCard),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : saveBusinessHours,

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
                                'Save Business Hours',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
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

class BusinessHourDay {
  final int dayOfWeek;
  final String name;

  bool isOpen;

  TimeOfDay? openTime;
  TimeOfDay? closeTime;

  BusinessHourDay({
    required this.dayOfWeek,
    required this.name,
    this.isOpen = false,
    this.openTime,
    this.closeTime,
  });
}
