import 'package:flutter/material.dart';

import '../auth/auth_session.dart';

import 'dart:convert';

import '../utils/currency_formatter.dart';
import '../config/api_config.dart';

import 'package:http/http.dart' as http;

import '../models/service.dart';
import 'add_service_screen.dart';
import 'edit_service_screen.dart';

class ServicesScreen extends StatefulWidget {
  final List<Service> services;

  const ServicesScreen({super.key, required this.services});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  static const Color tanzeemGreen = Color(0xFF0B5F4A);
  static const Color tanzeemDarkGreen = Color(0xFF073B31);
  static const Color tanzeemMint = Color(0xFFE4F5EF);
  static const Color tanzeemBackground = Color(0xFFF7F9F8);
  static const Color tanzeemText = Color(0xFF18221F);
  static const Color tanzeemMuted = Color(0xFF6F7D77);

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadServices();
  }

  Future<void> loadServices() async {
    try {
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

          isLoading = false;
        });
      } else {
        print('Failed to load services');
        print(response.body);

        if (!mounted) return;

        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      print('Failed to load services: $error');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> addService() async {
    final Service? newService = await Navigator.push<Service>(
      context,
      MaterialPageRoute(builder: (context) => const AddServiceScreen()),
    );

    if (newService != null) {
      await loadServices();
    }
  }

  Future<void> editService(Service service) async {
    final Service? updatedService = await Navigator.push<Service>(
      context,
      MaterialPageRoute(
        builder: (context) => EditServiceScreen(service: service),
      ),
    );

    if (updatedService != null) {
      await loadServices();
    }
  }

  Widget buildBookingTypeBadge(Service service) {
    final bool isGroup = service.bookingType == 'Group';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isGroup ? const Color(0xFFFFF2DB) : tanzeemMint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        service.bookingType,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isGroup ? const Color(0xFFB26A15) : tanzeemGreen,
        ),
      ),
    );
  }

  Widget buildServiceIcon(Service service) {
    final bool isGroup = service.bookingType == 'Group';

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: isGroup ? const Color(0xFFFFF2DB) : tanzeemMint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        isGroup ? Icons.groups_2_outlined : Icons.spa_outlined,
        color: isGroup ? const Color(0xFFB26A15) : tanzeemGreen,
        size: 23,
      ),
    );
  }

  Widget buildServiceCard(Service service) {
    return InkWell(
      onTap: () {
        editService(service);
      },
      borderRadius: BorderRadius.circular(16),

      child: Container(
        padding: const EdgeInsets.all(14),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8ECEA)),
        ),

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            buildServiceIcon(service),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          service.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: tanzeemText,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      buildBookingTypeBadge(service),
                    ],
                  ),

                  const SizedBox(height: 7),

                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 15,
                        color: tanzeemMuted,
                      ),

                      const SizedBox(width: 4),

                      Text(
                        '${service.duration} min',
                        style: const TextStyle(
                          fontSize: 12,
                          color: tanzeemMuted,
                        ),
                      ),

                      const SizedBox(width: 14),

                      const Icon(
                        Icons.payments_outlined,
                        size: 15,
                        color: tanzeemMuted,
                      ),

                      const SizedBox(width: 4),

                      Text(
                        CurrencyFormatter.usd(service.price),
                        style: const TextStyle(
                          fontSize: 12,
                          color: tanzeemMuted,
                        ),
                      ),
                    ],
                  ),

                  if (service.bookingType == 'Group' &&
                      service.capacity != null) ...[
                    const SizedBox(height: 7),

                    Row(
                      children: [
                        const Icon(
                          Icons.people_outline_rounded,
                          size: 15,
                          color: tanzeemMuted,
                        ),

                        const SizedBox(width: 4),

                        Text(
                          '${service.capacity} spots',
                          style: const TextStyle(
                            fontSize: 12,
                            color: tanzeemMuted,
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (service.description != null &&
                      service.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),

                    Text(
                      service.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: tanzeemMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 6),

            const Padding(
              padding: EdgeInsets.only(top: 11),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: tanzeemMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tanzeemBackground,

      body: SafeArea(
        child: RefreshIndicator(
          color: tanzeemGreen,
          onRefresh: loadServices,

          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),

                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: tanzeemText,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),

                    const SizedBox(width: 14),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            'Services',
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w700,
                              color: tanzeemText,
                            ),
                          ),

                          SizedBox(height: 3),

                          Text(
                            'Manage what you offer',
                            style: TextStyle(fontSize: 13, color: tanzeemMuted),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      width: 42,
                      height: 42,

                      decoration: BoxDecoration(
                        color: tanzeemGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),

                      child: IconButton(
                        onPressed: addService,
                        icon: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 23,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),

                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),

                  decoration: BoxDecoration(
                    color: tanzeemMint,
                    borderRadius: BorderRadius.circular(14),
                  ),

                  child: Row(
                    children: [
                      const Icon(
                        Icons.design_services_outlined,
                        size: 20,
                        color: tanzeemGreen,
                      ),

                      const SizedBox(width: 9),

                      Text(
                        '${widget.services.length} service${widget.services.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: tanzeemDarkGreen,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: tanzeemGreen),
                      )
                    : widget.services.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),

                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.50,

                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(30),

                                child: Column(
                                  mainAxisSize: MainAxisSize.min,

                                  children: [
                                    Container(
                                      width: 66,
                                      height: 66,

                                      decoration: const BoxDecoration(
                                        color: tanzeemMint,
                                        shape: BoxShape.circle,
                                      ),

                                      child: const Icon(
                                        Icons.design_services_outlined,
                                        size: 31,
                                        color: tanzeemGreen,
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    const Text(
                                      'No services yet',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: tanzeemText,
                                      ),
                                    ),

                                    const SizedBox(height: 5),

                                    const Text(
                                      'Add the services your business offers.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: tanzeemMuted,
                                      ),
                                    ),

                                    const SizedBox(height: 18),

                                    ElevatedButton.icon(
                                      onPressed: addService,
                                      icon: const Icon(Icons.add_rounded),
                                      label: const Text('Add Service'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: tanzeemGreen,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),

                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),

                        itemCount: widget.services.length,

                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),

                        itemBuilder: (context, index) {
                          final service = widget.services[index];

                          return buildServiceCard(service);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
