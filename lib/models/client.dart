class Client {
  final int? id;
  final String firstName;
  final String? lastName;
  final String phone;
  final String? email;
  final String? notes;

  Client({
    this.id,
    required this.firstName,
    this.lastName,
    required this.phone,
    this.email,
    this.notes,
  });

  String get fullName {
    if (lastName == null || lastName!.trim().isEmpty) {
      return firstName;
    }

    return '$firstName $lastName';
  }
}
