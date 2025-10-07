// รีวิวของไรเดอร์ (Reviews_model)
class RiderSummary {
  final int riderId;
  final String riderName;
  final double ratingAvg;
  final int reviewsCount;
  final int rating5;
  final int rating4;
  final int rating3;
  final int rating2;
  final int rating1;

  RiderSummary({
    required this.riderId,
    required this.riderName,
    required this.ratingAvg, // ค่าเฉลี่ยรีวิว
    required this.reviewsCount, // จำนวนรีวิวทั้งหมด
    this.rating5 = 0,
    this.rating4 = 0,
    this.rating3 = 0,
    this.rating2 = 0,
    this.rating1 = 0,
  });

  factory RiderSummary.fromJson(Map<String, dynamic> json) {
    return RiderSummary(
      riderId: json['rider_id'] ?? 0,
      riderName: json['rider_name'] ?? '',
      ratingAvg: _parseDouble(json['rating_avg']),
      reviewsCount: _parseInt(json['reviews_count']),
      rating5: _parseInt(json['rating_5']),
      rating4: _parseInt(json['rating_4']),
      rating3: _parseInt(json['rating_3']),
      rating2: _parseInt(json['rating_2']),
      rating1: _parseInt(json['rating_1']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      if (value.isEmpty) return 0.0;
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      if (value.isEmpty) return 0;
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}

class ReviewsModel {
  final int reviewId;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String reviewerName;
  final String reviewerPhoto;
  final int userId;

  ReviewsModel({
    required this.reviewId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.reviewerName,
    required this.reviewerPhoto,
    required this.userId,
  });

  factory ReviewsModel.fromJson(Map<String, dynamic> json) {
    return ReviewsModel(
      reviewId: json['review_id'] ?? 0,
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      reviewerName: json['reviewer_name'] ?? '',
      reviewerPhoto: json['reviewer_photo'] ?? '',
      userId: json['user_id'] ?? 0,
    );
  }
}
