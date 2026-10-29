class Service {
  final int? id;
  final String name;
  final int duration;
  final double price;
  final String bookingType;
  final int? capacity;
  final String? description;

  Service({
    this.id,
    required this.name,
    required this.duration,
    required this.price,
    required this.bookingType,
    this.capacity,
    this.description,
  });
}
