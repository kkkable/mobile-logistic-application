class Rating {
  final int ratingId;
  final int driverId;
  final int orderId;
  final int customerId;
  final double score;
  final String comment;
  final String createTime;

  Rating({
    required this.ratingId,
    required this.driverId,
    required this.orderId,
    required this.customerId,
    required this.score,
    required this.comment,
    required this.createTime,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      ratingId: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      driverId: int.tryParse(json['driver_id']?.toString() ?? '0') ?? 0,
      orderId: int.tryParse(json['order_id']?.toString() ?? '0') ?? 0,
      customerId: int.tryParse(json['customer_id']?.toString() ?? '0') ?? 0,
      score: double.tryParse(json['score']?.toString() ?? '0') ?? 0.0,
      comment: json['comment'] ?? '',
      createTime: _parseTimestamp(json['create_time']),
    );
  }

  static String _parseTimestamp(dynamic val) {
    if (val == null) return '';
    if (val is Map && val.containsKey('_seconds')) {
      final int seconds = val['_seconds'];
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000).toIso8601String();
    }
    return val.toString();
  }
}