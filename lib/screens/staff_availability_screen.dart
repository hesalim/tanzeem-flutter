import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../auth/auth_session.dart';
import '../models/staff.dart';

class StaffAvailabilityScreen extends StatefulWidget {
  final Staff staff;

  const StaffAvailabilityScreen({super.key, required this.staff});

  @override
  State<StaffAvailabilityScreen> createState() =>
      _StaffAvailabilityScreenState();
}

class _StaffAvailabilityScreenState extends State<StaffAvailabilityScreen> {
  static const Color tanzeemGreen = Color(0xFF0B5F4A);
  static const Color tanzeemDarkGreen = Color(0xFF073B31);
  static const Color tanzeemMint = Color(0xFFE4F5EF);
  static const Color tanzeemBackground = Color(0xFFF7F9F8);
  static const Color tanzeemText = Color(0xFF18221F);
  static const Color tanzeemMuted = Color(0xFF6F7D77);

  bool isLoading = true;
  bool isSaving = false;

  late List<AvailabilityDay> days;

  @override
  void initState() {
    super.initState();

    days = [
      AvailabilityDay(dayOfWeek: 1, name: 'Monday'),
      AvailabilityDay(dayOfWeek: 2, name: 'Tuesday'),
      AvailabilityDay(dayOfWeek: 3, name: 'Wednesday'),
      AvailabilityDay(dayOfWeek: 4, name: 'Thursday'),
      AvailabilityDay(dayOfWeek: 5, name: 'Friday'),
      AvailabilityDay(dayOfWeek: 6, name: 'Saturday'),
      AvailabilityDay(dayOfWeek: 7, name: 'Sunday'),
    ];

    loadAvailability();
  }

  Future<void> loadAvailability() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/staff-availability?staffId=${widget.staff.id}',
        ),
        headers: {'Authorization': 'Bearer ${AuthSession.token}'},
      );

      if (response.statusCode != 200) {
        String message = 'Failed to load working hours';

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

      for (final day in days) {
        day.isWorking = false;
        day.periods.clear();
      }

      for (final item in data) {
        final int dayOfWeek = int.parse(item['day_of_week'].toString());

        final AvailabilityDay day = days.firstWhere(
          (day) => day.dayOfWeek == dayOfWeek,
        );

        final dynamic workingValue = item['is_working'];

        final bool isWorking =
            workingValue == true ||
            workingValue == 1 ||
            workingValue.toString() == '1';

        if (!isWorking) {
          day.isWorking = false;
          continue;
        }

        day.isWorking = true;

        day.periods.add(
          AvailabilityPeriod(
            startTime: parseDatabaseTime(item['start_time']?.toString()),
            endTime: parseDatabaseTime(item['end_time']?.toString()),
          ),
        );
      }
    } catch (error) {
      print('LOAD AVAILABILITY ERROR: $error');

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

  Future<void> selectStartTime(AvailabilityPeriod period) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: period.startTime ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      period.startTime = selected;
    });
  }

  Future<void> selectEndTime(AvailabilityPeriod period) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: period.endTime ?? const TimeOfDay(hour: 17, minute: 0),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      period.endTime = selected;
    });
  }

  Future<void> saveAvailability() async {
    for (final day in days) {
      if (!day.isWorking) {
        continue;
      }

      if (day.periods.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please add at least one working period for ${day.name}',
            ),
          ),
        );

        return;
      }

      final sortedPeriods = [...day.periods]
        ..sort((a, b) {
          final aMinutes =
              (a.startTime?.hour ?? 0) * 60 + (a.startTime?.minute ?? 0);

          final bMinutes =
              (b.startTime?.hour ?? 0) * 60 + (b.startTime?.minute ?? 0);

          return aMinutes.compareTo(bMinutes);
        });

      for (int i = 0; i < sortedPeriods.length; i++) {
        final period = sortedPeriods[i];

        if (period.startTime == null || period.endTime == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please select all working hours for ${day.name}'),
            ),
          );

          return;
        }

        final startMinutes =
            period.startTime!.hour * 60 + period.startTime!.minute;

        final endMinutes = period.endTime!.hour * 60 + period.endTime!.minute;

        if (endMinutes <= startMinutes) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${day.name}: end time must be after start time'),
            ),
          );

          return;
        }

        if (i > 0) {
          final previous = sortedPeriods[i - 1];

          final previousEnd =
              previous.endTime!.hour * 60 + previous.endTime!.minute;

          if (startMinutes < previousEnd) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${day.name}: working periods cannot overlap'),
              ),
            );

            return;
          }
        }
      }
    }

    setState(() {
      isSaving = true;
    });

    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/staff-availability'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthSession.token}',
        },
        body: jsonEncode({
          'staffId': widget.staff.id,
          'availability': days.map((day) {
            return {
              'dayOfWeek': day.dayOfWeek,
              'isWorking': day.isWorking,
              'periods': day.isWorking
                  ? day.periods.map((period) {
                      return {
                        'startTime': period.startTime != null
                            ? formatApiTime(period.startTime!)
                            : null,
                        'endTime': period.endTime != null
                            ? formatApiTime(period.endTime!)
                            : null,
                      };
                    }).toList()
                  : [],
            };
          }).toList(),
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Working hours saved')));

        Navigator.pop(context, true);
      } else {
        String message = 'Failed to save working hours';

        try {
          final data = jsonDecode(response.body);
          message = data['message']?.toString() ?? message;
        } catch (_) {}

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (error) {
      print('SAVE AVAILABILITY ERROR: $error');

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

  Widget buildDayCard(AvailabilityDay day) {
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
                day.isWorking ? 'Working' : 'Off',
                style: TextStyle(
                  color: day.isWorking ? tanzeemGreen : tanzeemMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(width: 8),

              Switch(
                value: day.isWorking,
                activeColor: tanzeemGreen,
                onChanged: (value) {
                  setState(() {
                    day.isWorking = value;

                    if (value && day.periods.isEmpty) {
                      day.periods.add(
                        AvailabilityPeriod(
                          startTime: const TimeOfDay(hour: 9, minute: 0),
                          endTime: const TimeOfDay(hour: 17, minute: 0),
                        ),
                      );
                    }

                    if (!value) {
                      day.periods.clear();
                    }
                  });
                },
              ),
            ],
          ),

          if (day.isWorking) ...[
            const SizedBox(height: 12),

            ...day.periods.asMap().entries.map((entry) {
              final index = entry.key;
              final period = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    buildTimeButton(
                      label: 'Starts',
                      time: period.startTime,
                      onTap: () {
                        selectStartTime(period);
                      },
                    ),

                    const SizedBox(width: 10),

                    buildTimeButton(
                      label: 'Ends',
                      time: period.endTime,
                      onTap: () {
                        selectEndTime(period);
                      },
                    ),

                    if (day.periods.length > 1) ...[
                      const SizedBox(width: 6),

                      IconButton(
                        onPressed: () {
                          setState(() {
                            day.periods.removeAt(index);
                          });
                        },
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFC53B3B),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),

            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    day.periods.add(
                      AvailabilityPeriod(
                        startTime: const TimeOfDay(hour: 14, minute: 0),
                        endTime: const TimeOfDay(hour: 18, minute: 0),
                      ),
                    );
                  });
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add period'),
              ),
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
        elevation: 0,
        surfaceTintColor: tanzeemBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: tanzeemText),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Working Hours',
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
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.schedule_rounded,
                                  color: tanzeemGreen,
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.staff.fullName,
                                      style: const TextStyle(
                                        color: tanzeemDarkGreen,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),

                                    const SizedBox(height: 3),

                                    const Text(
                                      'Set the regular weekly schedule',
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
                    decoration: const BoxDecoration(color: tanzeemBackground),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : saveAvailability,
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
                                'Save Working Hours',
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

class AvailabilityPeriod {
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  AvailabilityPeriod({this.startTime, this.endTime});
}

class AvailabilityDay {
  final int dayOfWeek;
  final String name;

  bool isWorking;
  final List<AvailabilityPeriod> periods;

  AvailabilityDay({
    required this.dayOfWeek,
    required this.name,
    this.isWorking = false,
    List<AvailabilityPeriod>? periods,
  }) : periods = periods ?? [];
}
