import 'client.dart';
import 'service.dart';

enum AppointmentStatus { confirmed, completed, cancelled }

class Appointment {
  final int? id;
  final Client client;
  final List<Service> services;
  final DateTime dateTime;
  final String? notes;
  AppointmentStatus status;

  Appointment({
    this.id,
    required this.client,
    required this.services,
    required this.dateTime,
    this.notes,
    this.status = AppointmentStatus.confirmed,
  });

  int get totalDuration {
    return services.fold(0, (total, service) => total + service.duration);
  }

  double get totalPrice {
    return services.fold(0, (total, service) => total + service.price);
  }
}
