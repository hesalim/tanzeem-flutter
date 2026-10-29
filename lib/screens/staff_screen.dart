import 'dart:convert';

import '../config/api_config.dart';
import 'add_staff_screen.dart';
import 'edit_staff_screen.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../auth/auth_session.dart';
import '../models/staff.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  static const Color tanzeemGreen = Color(0xFF0B5F4A);
  static const Color tanzeemDarkGreen = Color(0xFF073B31);
  static const Color tanzeemMint = Color(0xFFE4F5EF);
  static const Color tanzeemBackground = Color(0xFFF7F9F8);
  static const Color tanzeemText = Color(0xFF18221F);
  static const Color tanzeemMuted = Color(0xFF6F7D77);

  final List<Staff> staffMembers = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadStaff();
  }

  Future<void> loadStaff() async {
    try {
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

          isLoading = false;
        });
      } else {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load team: ${response.body}')),
        );
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not connect to the server')),
      );
    }
  }

  Widget buildStaffCard(Staff staff) {
    return InkWell(
      onTap: () async {
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => EditStaffScreen(staff: staff),
          ),
        );

        if (changed == true) {
          await loadStaff();
        }
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
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: staff.isOwner ? tanzeemMint : const Color(0xFFF1F4F3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                staff.isOwner
                    ? Icons.workspace_premium_outlined
                    : Icons.person_outline_rounded,
                color: staff.isOwner ? tanzeemGreen : tanzeemMuted,
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          staff.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: tanzeemText,
                          ),
                        ),
                      ),

                      if (staff.isOwner) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: tanzeemMint,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'OWNER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: tanzeemDarkGreen,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  if (staff.email != null &&
                      staff.email!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      staff.email!,
                      style: const TextStyle(fontSize: 12, color: tanzeemMuted),
                    ),
                  ],

                  if (staff.phone != null &&
                      staff.phone!.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      staff.phone!,
                      style: const TextStyle(fontSize: 12, color: tanzeemMuted),
                    ),
                  ],
                ],
              ),
            ),

            if (!staff.isOwner)
              const Icon(Icons.chevron_right_rounded, color: tanzeemMuted),
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
          onRefresh: loadStaff,
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
                            'Team',
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w700,
                              color: tanzeemText,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Manage your team members',
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
                        onPressed: () async {
                          final added = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddStaffScreen(),
                            ),
                          );

                          if (added == true) {
                            await loadStaff();
                          }
                        },
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
                        Icons.groups_2_outlined,
                        color: tanzeemGreen,
                        size: 20,
                      ),

                      const SizedBox(width: 9),

                      Text(
                        '${staffMembers.length} team member${staffMembers.length == 1 ? '' : 's'}',
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
                    : staffMembers.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.50,
                            child: const Center(
                              child: Text(
                                'No team members yet',
                                style: TextStyle(color: tanzeemMuted),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                        itemCount: staffMembers.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final staff = staffMembers[index];

                          return buildStaffCard(staff);
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
