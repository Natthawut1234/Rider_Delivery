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
      riderId: json['rider_id'],
      riderName: json['rider_name'],
      ratingAvg: double.parse(json['rating_avg'].toString()),
      reviewsCount: json['reviews_count'],
      rating5: int.parse(json['rating_5']?.toString() ?? '0'),
      rating4: int.parse(json['rating_4']?.toString() ?? '0'),
      rating3: int.parse(json['rating_3']?.toString() ?? '0'),
      rating2: int.parse(json['rating_2']?.toString() ?? '0'),
      rating1: int.parse(json['rating_1']?.toString() ?? '0'),
    );
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
      reviewId: json['review_id'],
      rating: json['rating'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
      reviewerName: json['reviewer_name'],
      reviewerPhoto: json['reviewer_photo'],
      userId: json['user_id'],
    );
  }
}
