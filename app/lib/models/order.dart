class Order {
  final int orderId;
  final int userId;
  final int? driverId;
  final String pickupLocation;
  final String dropoffLocation;
  final String status;
  final double? weight;

  Order({
    required this.orderId,
    required this.userId,
    this.driverId,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.status,
    this.weight,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['order_id'],
      userId: json['user_id'],
      driverId: json['driver_id'] as int?,
      pickupLocation: json['pickup_location'],
      dropoffLocation: json['dropoff_location'],
      status: json['status'],
      weight: json['weight'] != null ? double.parse(json['weight'].toString()) : null,
    );
  }
}