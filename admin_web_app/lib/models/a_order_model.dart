class Order {
  final int orderId;
  final int userId;
  final int driverId;
  final String status;
  final String pickupLocation;
  final String dropoffLocation;
  final String timestamp;
  final Map<String, dynamic>? proofOfDelivery; 
  final double? weight;

  Order({
    required this.orderId,
    required this.userId,
    required this.driverId,
    required this.status,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.timestamp,
    this.proofOfDelivery,
    this.weight,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: _parseInt(json['order_id'] ?? json['id']),
      userId: _parseInt(json['user_id']),
      driverId: _parseInt(json['driver_id']),
      status: json['status']?.toString() ?? 'Unknown',
      pickupLocation: json['pickup_location']?.toString() ?? 'Unknown',
      dropoffLocation: json['dropoff_location']?.toString() ?? 'Unknown',
      timestamp: _parseTimestamp(json['timestamp'] ?? json['create_time']),
      
      proofOfDelivery: _parseProofOfDelivery(json['proof_of_delivery']),
      
      weight: json['weight'] != null ? double.tryParse(json['weight'].toString()) : null,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static String _parseTimestamp(dynamic val) {
    if (val == null) return '';
    if (val is Map && val.containsKey('_seconds')) {
      final int seconds = val['_seconds'];
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000).toIso8601String();
    }
    return val.toString();
  }

  static Map<String, dynamic>? _parseProofOfDelivery(dynamic val) {
    if (val == null) return null;
    
    if (val is Map) {
      return Map<String, dynamic>.from(val);
    }
    
    if (val is String) {
      return {'photo_url': val};
    }
    
    return null;
  }
}