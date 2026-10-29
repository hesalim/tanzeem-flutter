class Staff {
  final int id;
  final int? userId;
  final String firstName;
  final String? lastName;
  final String? phone;
  final String? email;
  final bool isOwner;
  final bool isActive;

  Staff({
    required this.id,
    this.userId,
    required this.firstName,
    this.lastName,
    this.phone,
    this.email,
    required this.isOwner,
    required this.isActive,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id'],
      userId: json['user_id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'],
      phone: json['phone'],
      email: json['email'],
      isOwner: json['is_owner'] == 1 || json['is_owner'] == true,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  String get fullName {
    final last = lastName?.trim() ?? '';

    if (last.isEmpty) {
      return firstName;
    }

    return '$firstName $last';
  }
}
