import 'package:flutter/material.dart';

import '../auth/auth_session.dart';

import 'dart:convert';

import '../config/api_config.dart';

import 'package:http/http.dart' as http;

import '../models/service.dart';

class EditServiceScreen extends StatefulWidget {
  final Service service;

  const EditServiceScreen({super.key, required this.service});

  @override
  State<EditServiceScreen> createState() => _EditServiceScreenState();
}

class _EditServiceScreenState extends State<EditServiceScreen> {
  static const Color tanzeemGreen = Color(0xFF0B5F4A);
  static const Color tanzeemDarkGreen = Color(0xFF073B31);
  static const Color tanzeemMint = Color(0xFFE4F5EF);
  static const Color tanzeemBackground = Color(0xFFF7F9F8);
  static const Color tanzeemText = Color(0xFF18221F);
  static const Color tanzeemMuted = Color(0xFF6F7D77);
  static const Color danger = Color(0xFFC53B3B);

  late TextEditingController nameController;
  late TextEditingController durationController;
  late TextEditingController priceController;
  late TextEditingController capacityController;
  late TextEditingController descriptionController;

  late String bookingType;

  bool isSaving = false;
  bool isDeleting = false;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.service.name);

    durationController = TextEditingController(
      text: widget.service.duration.toString(),
    );

    priceController = TextEditingController(
      text: widget.service.price.toString(),
    );

    capacityController = TextEditingController(
      text: widget.service.capacity?.toString() ?? '',
    );

    descriptionController = TextEditingController(
      text: widget.service.description ?? '',
    );

    bookingType = widget.service.bookingType;
  }

  InputDecoration inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: tanzeemMuted),
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: tanzeemMuted),
      hintStyle: const TextStyle(color: tanzeemMuted, fontSize: 13),
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
    );
  }

  Widget buildBookingTypeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final bool selected = bookingType == value;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            bookingType = value;
          });
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : tanzeemMint,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, size: 20, color: tanzeemGreen),
                  ),

                  const Spacer(),

                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: selected ? tanzeemGreen : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? tanzeemGreen
                            : const Color(0xFFB9C3BF),
                      ),
                    ),
                    child: selected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 15,
                          )
                        : null,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                title,
                style: const TextStyle(
                  color: tanzeemText,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                subtitle,
                style: const TextStyle(
                  color: tanzeemMuted,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> saveService() async {
    final duration = int.tryParse(durationController.text.trim());

    final price = double.tryParse(priceController.text.trim());

    final capacity = bookingType == 'Group'
        ? int.tryParse(capacityController.text.trim())
        : null;

    if (nameController.text.trim().isEmpty ||
        duration == null ||
        duration <= 0 ||
        price == null ||
        price < 0 ||
        (bookingType == 'Group' && (capacity == null || capacity <= 0))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields correctly'),
        ),
      );

      return;
    }

    if (widget.service.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service does not have a database ID')),
      );

      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/services/${widget.service.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthSession.token}',
        },
        body: jsonEncode({
          'name': nameController.text.trim(),
          'description': descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
          'durationMinutes': duration,
          'price': price,
          'bookingType': bookingType == 'Individual' ? 'INDIVIDUAL' : 'GROUP',
          'maxParticipants': bookingType == 'Group' ? capacity : null,
        }),
      );

      if (response.statusCode == 200) {
        final updatedService = Service(
          id: widget.service.id,
          name: nameController.text.trim(),
          duration: duration,
          price: price,
          bookingType: bookingType,
          capacity: capacity,
          description: descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
        );

        if (!mounted) return;

        Navigator.pop(context, updatedService);
      } else {
        print(response.statusCode);
        print(response.body);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update service')),
        );
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

  Future<void> deleteService() async {
    if (widget.service.id == null) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Service'),
          content: const Text(
            'This service will be removed from your active service list. Existing appointment history will remain.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Keep Service'),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete', style: TextStyle(color: danger)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      isDeleting = true;
    });

    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/services/${widget.service.id}'),
        headers: {'Authorization': 'Bearer ${AuthSession.token}'},
      );

      if (response.statusCode == 200) {
        if (!mounted) return;

        Navigator.pop(context, widget.service);
      } else {
        print(response.statusCode);
        print(response.body);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete service')),
        );
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
          isDeleting = false;
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
        elevation: 0,
        surfaceTintColor: tanzeemBackground,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: tanzeemText),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Edit Service',
          style: TextStyle(color: tanzeemText, fontWeight: FontWeight.w700),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: tanzeemMint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  bookingType == 'Group'
                      ? Icons.groups_2_outlined
                      : Icons.design_services_outlined,
                  color: tanzeemGreen,
                  size: 25,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.service.name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: tanzeemText,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      bookingType == 'Group'
                          ? 'Group service'
                          : 'Individual service',
                      style: const TextStyle(color: tanzeemMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 26),

          const Text(
            'Service details',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: tanzeemText,
            ),
          ),

          const SizedBox(height: 10),

          TextField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            decoration: inputDecoration(
              label: 'Service name',
              icon: Icons.design_services_outlined,
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: descriptionController,
            maxLines: 3,
            decoration: inputDecoration(
              label: 'Description',
              icon: Icons.notes_rounded,
              hint: 'Optional',
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Duration & price',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: tanzeemText,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  decoration: inputDecoration(
                    label: 'Duration',
                    icon: Icons.schedule_rounded,
                    hint: 'Minutes',
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: inputDecoration(
                    label: bookingType == 'Group'
                        ? 'Price / person (\$)'
                        : 'Price (\$)',
                    icon: Icons.payments_outlined,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 26),

          const Text(
            'Booking type',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: tanzeemText,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              buildBookingTypeOption(
                title: 'Individual',
                subtitle: 'One customer per booking',
                icon: Icons.person_outline_rounded,
                value: 'Individual',
              ),

              const SizedBox(width: 10),

              buildBookingTypeOption(
                title: 'Group',
                subtitle: 'Multiple participants',
                icon: Icons.groups_2_outlined,
                value: 'Group',
              ),
            ],
          ),

          if (bookingType == 'Group') ...[
            const SizedBox(height: 16),

            TextField(
              controller: capacityController,
              keyboardType: TextInputType.number,
              decoration: inputDecoration(
                label: 'Maximum participants',
                icon: Icons.people_outline_rounded,
                hint: 'Example: 8',
              ),
            ),
          ],

          const SizedBox(height: 28),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tanzeemDarkGreen,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    bookingType == 'Group'
                        ? Icons.groups_2_outlined
                        : Icons.person_outline_rounded,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bookingType == 'Group'
                            ? 'Group service'
                            : 'Individual service',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        bookingType == 'Group'
                            ? 'Customers book a spot in this service.'
                            : 'Each booking is for one customer.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 11,
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
              onPressed: isSaving || isDeleting ? null : saveService,
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
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: isSaving || isDeleting ? null : deleteService,
              icon: isDeleting
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline_rounded),
              label: const Text('Delete Service'),
              style: OutlinedButton.styleFrom(
                foregroundColor: danger,
                side: const BorderSide(color: Color(0xFFE8B7B7)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
