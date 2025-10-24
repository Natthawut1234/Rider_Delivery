import 'package:rider_delivery/services/RiderStatusService.dart';

class HomePageData {
  final String userName;
  final String userProfileImage;
  final double currentCredit;
  final double todayIncome;
  final int todayJobCount;
  final double averageRating;
  final int reviewsCount;
  final RiderStatus riderStatus;
  final String statusMessage;
  final int? riderId;
  
  HomePageData({
    required this.userName,
    required this.userProfileImage,
    required this.currentCredit,
    required this.todayIncome,
    required this.todayJobCount,
    required this.averageRating,
    required this.reviewsCount,
    required this.riderStatus,
    required this.statusMessage,
    this.riderId,
  });
  
  HomePageData copyWith({
    String? userName,
    String? userProfileImage,
    double? currentCredit,
    double? todayIncome,
    int? todayJobCount,
    double? averageRating,
    int? reviewsCount,
    RiderStatus? riderStatus,
    String? statusMessage,
    int? riderId,
  }) {
    return HomePageData(
      userName: userName ?? this.userName,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      currentCredit: currentCredit ?? this.currentCredit,
      todayIncome: todayIncome ?? this.todayIncome,
      todayJobCount: todayJobCount ?? this.todayJobCount,
      averageRating: averageRating ?? this.averageRating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      riderStatus: riderStatus ?? this.riderStatus,
      statusMessage: statusMessage ?? this.statusMessage,
      riderId: riderId ?? this.riderId,
    );
  }
}

enum LoadingState {
  initial,
  loading,
  success,
  error,
  refreshing, // สำหรับ pull-to-refresh
}