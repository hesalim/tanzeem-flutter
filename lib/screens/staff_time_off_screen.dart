import 'dart:convert';

import '../config/api_config.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../auth/auth_session.dart';
import '../models/staff.dart';

class StaffTimeOffScreen extends StatefulWidget {
  final Staff staff;

  const StaffTimeOffScreen({super.key, required this.staff});

  @override
  State<StaffTimeOffScreen> createState() => _StaffTimeOffScreenState();
}

class _StaffTimeOffScreenState extends State<StaffTimeOffScreen> {
  static const Color tanzeemGreen = Color(0xFF0B5F4A);

  static const Color tanzeemBackground = Color(0xFFF7F9F8);

  static const Color tanzeemText = Color(0xFF18221F);

  static const Color tanzeemMuted = Color(0xFF6F7D77);

  static const Color danger = Color(0xFFC53B3B);

  bool isLoading = true;
  bool isSaving = false;

  final List<Map<String, dynamic>> timeOffList = [];

  Future<void> loadTimeOff() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/staff-time-off?staffId=${widget.staff.id}',
        ),
        headers: {'Authorization': 'Bearer ${AuthSession.token}'},
      );

      if (response.statusCode != 200) {
        String message = 'Failed to load time off';

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

      if (!mounted) return;

      setState(() {
        timeOffList.clear();

        timeOffList.addAll(data.map((item) => Map<String, dynamic>.from(item)));
      });
    } catch (error) {
      print('LOAD TIME OFF ERROR: $error');

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

  @override
  void initState() {
    super.initState();
    loadTimeOff();
  }

  DateTime parseDate(dynamic value) {
    return DateTime.parse(value.toString()).toLocal();
  }

  String formatDateTime(DateTime value) {
    final date =
        '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';

    final time = TimeOfDay.fromDateTime(value).format(context);

    return '$date • $time';
  }

  Future<DateTime?> pickDateTime({required DateTime initialValue}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initialValue,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (date == null) {
      return null;
    }

    if (!mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialValue),
    );

    if (time == null) {
      return null;
    }

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> addTimeOff() async {
    DateTime startAt = DateTime.now().add(const Duration(hours: 1));

    DateTime endAt = startAt.add(const Duration(hours: 1));

    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Time Off'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Starts'),
                      subtitle: Text(formatDateTime(startAt)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        final value = await pickDateTime(initialValue: startAt);

                        if (value == null) {
                          return;
                        }

                        setDialogState(() {
                          startAt = value;

                          if (endAt.isBefore(startAt) ||
                              endAt.isAtSameMomentAs(startAt)) {
                            endAt = startAt.add(const Duration(hours: 1));
                          }
                        });
                      },
                    ),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ends'),
                      subtitle: Text(formatDateTime(endAt)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        final value = await pickDateTime(initialValue: endAt);

                        if (value == null) {
                          return;
                        }

                        setDialogState(() {
                          endAt = value;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Reason',
                        hintText: 'Optional',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (endAt.isBefore(startAt) ||
                        endAt.isAtSameMomentAs(startAt)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('End time must be after start time'),
                        ),
                      );

                      return;
                    }

                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) {
      reasonController.dispose();
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/staff-time-off'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthSession.token}',
        },
        body: jsonEncode({
          'staffId': widget.staff.id,
          'startAt': startAt.toIso8601String(),
          'endAt': endAt.toIso8601String(),
          'reason': reasonController.text.trim().isEmpty
              ? null
              : reasonController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        await loadTimeOff();
      } else {
        String message = 'Failed to add time off';

        try {
          final data = jsonDecode(response.body);

          message = data['message']?.toString() ?? message;
        } catch (_) {}

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (error) {
      print('ADD TIME OFF ERROR: $error');
    } finally {
      reasonController.dispose();

      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> deleteTimeOff(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove Time Off?'),
          content: const Text('This blocked period will be removed.'),
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
              child: const Text('Remove', style: TextStyle(color: danger)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/staff-time-off?id=$id'),
        headers: {'Authorization': 'Bearer ${AuthSession.token}'},
      );

      if (response.statusCode == 200) {
        await loadTimeOff();
      } else {
        String message = 'Failed to remove time off';

        try {
          final data = jsonDecode(response.body);

          message = data['message']?.toString() ?? message;
        } catch (_) {}

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (error) {
      print('DELETE TIME OFF ERROR: $error');
    }
  }

  Widget buildTimeOffCard(Map<String, dynamic> item) {
    final startAt = parseDate(item['start_at']);

    final endAt = parseDate(item['end_at']);

    final reason = item['reason']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECEA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.block_rounded, color: danger),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reason == null || reason.isEmpty ? 'Blocked time' : reason,
                  style: const TextStyle(
                    color: tanzeemText,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '${formatDateTime(startAt)}\n${formatDateTime(endAt)}',
                  style: const TextStyle(
                    color: tanzeemMuted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () {
              deleteTimeOff(int.parse(item['id'].toString()));
            },
            icon: const Icon(Icons.delete_outline_rounded, color: danger),
          ),
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
        title: Text(
          '${widget.staff.fullName} • Time Off',
          style: const TextStyle(
            color: tanzeemText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: isSaving ? null : addTimeOff,
        backgroundColor: tanzeemGreen,
        foregroundColor: Colors.white,
        icon: isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add_rounded),
        label: const Text('Add Time Off'),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: tanzeemGreen))
          : timeOffList.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Text(
                  'No blocked periods yet.',
                  style: TextStyle(color: tanzeemMuted),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              itemCount: timeOffList.length,
              itemBuilder: (context, index) {
                return buildTimeOffCard(timeOffList[index]);
              },
            ),
    );
  }
}
