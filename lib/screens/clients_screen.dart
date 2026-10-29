import 'package:flutter/material.dart';

import '../auth/auth_session.dart';

import 'dart:convert';

import '../config/api_config.dart';

import 'package:http/http.dart' as http;

import '../models/client.dart';
import 'add_client_screen.dart';
import 'edit_client_screen.dart';

class ClientsScreen extends StatefulWidget {
  final List<Client> clients;

  const ClientsScreen({super.key, required this.clients});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  static const Color tanzeemGreen = Color(0xFF0B5F4A);
  static const Color tanzeemMint = Color(0xFFE4F5EF);
  static const Color tanzeemBackground = Color(0xFFF7F9F8);
  static const Color tanzeemText = Color(0xFF18221F);
  static const Color tanzeemMuted = Color(0xFF6F7D77);

  final TextEditingController searchController = TextEditingController();

  String searchText = '';

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/customers'),
        headers: {'Authorization': 'Bearer ${AuthSession.token}'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (!mounted) return;

        setState(() {
          widget.clients.clear();

          widget.clients.addAll(
            data.map(
              (item) => Client(
                id: item['id'],
                firstName: item['first_name'],
                lastName: item['last_name'],
                phone: item['phone'],
                email: item['email'],
                notes: item['notes'],
              ),
            ),
          );

          isLoading = false;
        });
      } else {
        print('Failed to load customers');
        print(response.body);

        if (!mounted) return;

        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      print('Failed to load customers: $error');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> addClient() async {
    final Client? newClient = await Navigator.push<Client>(
      context,
      MaterialPageRoute(builder: (context) => const AddClientScreen()),
    );

    if (newClient != null) {
      await loadCustomers();
    }
  }

  Future<void> editClient(Client client) async {
    final Client? updatedClient = await Navigator.push<Client>(
      context,
      MaterialPageRoute(builder: (context) => EditClientScreen(client: client)),
    );

    if (updatedClient != null) {
      await loadCustomers();
    }
  }

  List<Client> get filteredClients {
    if (searchText.trim().isEmpty) {
      return widget.clients;
    }

    final query = searchText.toLowerCase();

    return widget.clients.where((client) {
      final name = client.fullName.toLowerCase();
      final phone = client.phone.toLowerCase();
      final email = client.email?.toLowerCase() ?? '';

      return name.contains(query) ||
          phone.contains(query) ||
          email.contains(query);
    }).toList();
  }

  Color avatarColor(int index) {
    const colors = [
      Color(0xFFE7E5FF),
      Color(0xFFFFE4EC),
      Color(0xFFE0F5EA),
      Color(0xFFFFEEDB),
      Color(0xFFE5F0FF),
    ];

    return colors[index % colors.length];
  }

  Color avatarTextColor(int index) {
    const colors = [
      Color(0xFF5546C7),
      Color(0xFFC8496A),
      Color(0xFF16865B),
      Color(0xFFB46D21),
      Color(0xFF3E67B1),
    ];

    return colors[index % colors.length];
  }

  String getInitials(Client client) {
    final first = client.firstName.trim();

    final last = client.lastName?.trim() ?? '';

    if (first.isEmpty) {
      return '?';
    }

    if (last.isEmpty) {
      return first[0].toUpperCase();
    }

    return '${first[0]}${last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final visibleClients = filteredClients;

    return Scaffold(
      backgroundColor: tanzeemBackground,

      body: SafeArea(
        child: RefreshIndicator(
          color: tanzeemGreen,
          onRefresh: loadCustomers,

          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),

                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Customers',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w700,
                          color: tanzeemText,
                        ),
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
                        onPressed: addClient,
                        icon: const Icon(
                          Icons.person_add_alt_1_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),

                child: TextField(
                  controller: searchController,

                  onChanged: (value) {
                    setState(() {
                      searchText = value;
                    });
                  },

                  decoration: InputDecoration(
                    hintText: 'Search by name, phone or email',

                    hintStyle: const TextStyle(
                      color: tanzeemMuted,
                      fontSize: 13,
                    ),

                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: tanzeemMuted,
                    ),

                    filled: true,
                    fillColor: Colors.white,

                    contentPadding: const EdgeInsets.symmetric(vertical: 14),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE8ECEA)),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE8ECEA)),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: tanzeemGreen,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),

                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: tanzeemGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'All (${widget.clients.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: tanzeemGreen),
                      )
                    : visibleClients.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),

                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.45,
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
                                        Icons.people_outline_rounded,
                                        size: 30,
                                        color: tanzeemGreen,
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    Text(
                                      searchText.isEmpty
                                          ? 'No customers yet'
                                          : 'No customers found',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: tanzeemText,
                                      ),
                                    ),

                                    const SizedBox(height: 5),

                                    Text(
                                      searchText.isEmpty
                                          ? 'Add your first customer to get started.'
                                          : 'Try searching with another name or phone number.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: tanzeemMuted,
                                        fontSize: 13,
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

                        itemCount: visibleClients.length,

                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),

                        itemBuilder: (context, index) {
                          final client = visibleClients[index];

                          return InkWell(
                            onTap: () {
                              editClient(client);
                            },

                            borderRadius: BorderRadius.circular(16),

                            child: Container(
                              padding: const EdgeInsets.all(14),

                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),

                                border: Border.all(
                                  color: const Color(0xFFE8ECEA),
                                ),
                              ),

                              child: Row(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    alignment: Alignment.center,

                                    decoration: BoxDecoration(
                                      color: avatarColor(index),
                                      shape: BoxShape.circle,
                                    ),

                                    child: Text(
                                      getInitials(client),
                                      style: TextStyle(
                                        color: avatarTextColor(index),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 13),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,

                                      children: [
                                        Text(
                                          client.fullName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,

                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: tanzeemText,
                                          ),
                                        ),

                                        const SizedBox(height: 4),

                                        Text(
                                          client.phone,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: tanzeemMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 22,
                                    color: tanzeemMuted,
                                  ),
                                ],
                              ),
                            ),
                          );
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
