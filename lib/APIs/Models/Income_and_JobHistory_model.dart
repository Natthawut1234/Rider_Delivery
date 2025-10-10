// Models for Job History API Response

// Main API Response wrapper
class JobHistoryResponse {
  final bool success;
  final int count;
  final String? selectedDate;
  final JobHistoryData data;

  JobHistoryResponse({
    required this.success,
    required this.count,
    this.selectedDate,
    required this.data,
  });

  factory JobHistoryResponse.fromJson(Map<String, dynamic> json) {
    return JobHistoryResponse(
      success: json['success'] ?? false,
      count: json['count'] ?? 0,
      selectedDate: json['selected_date'],
      data: JobHistoryData.fromJson(json['data']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'count': count,
      if (selectedDate != null) 'selected_date': selectedDate,
      'data': data.toJson(),
    };
  }
}

// Data container for job history
class JobHistoryData {
  final int riderId;
  final int userId;
  final List<JobItem> jobHistory;
  final JobStatistics statistics;
  final List<JobItem>? selectedDateJobs;
  final JobStatistics? selectedDateStatistics;
  final PreviousDayComparison? comparisonWithPreviousDay;

  JobHistoryData({
    required this.riderId,
    required this.userId,
    required this.jobHistory,
    required this.statistics,
    this.selectedDateJobs,
    this.selectedDateStatistics,
    this.comparisonWithPreviousDay,
  });

  factory JobHistoryData.fromJson(Map<String, dynamic> json) {
    // Handle different field names for different API endpoints
    List<JobItem> jobs = [];

    // Try different possible field names for job lists
    if (json['job_history'] != null) {
      jobs = (json['job_history'] as List<dynamic>)
          .map((item) => JobItem.fromJson(item))
          .toList();
    } else if (json['selected_date_jobs'] != null) {
      jobs = (json['selected_date_jobs'] as List<dynamic>)
          .map((item) => JobItem.fromJson(item))
          .toList();
    } else if (json['selected_month_jobs'] != null) {
      jobs = (json['selected_month_jobs'] as List<dynamic>)
          .map((item) => JobItem.fromJson(item))
          .toList();
    } else if (json['selected_year_jobs'] != null) {
      jobs = (json['selected_year_jobs'] as List<dynamic>)
          .map((item) => JobItem.fromJson(item))
          .toList();
    } else if (json['date_range_jobs'] != null) {
      jobs = (json['date_range_jobs'] as List<dynamic>)
          .map((item) => JobItem.fromJson(item))
          .toList();
    }

    return JobHistoryData(
      riderId: json['rider_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      jobHistory: jobs,
      statistics: JobStatistics.fromJson(
        json['statistics'] ??
            json['selected_date_statistics'] ??
            json['selected_month_statistics'] ??
            json['selected_year_statistics'] ??
            json['date_range_statistics'] ??
            {},
      ),
      selectedDateJobs: (json['selected_date_jobs'] as List<dynamic>?)
          ?.map((item) => JobItem.fromJson(item))
          .toList(),
      selectedDateStatistics: json['selected_date_statistics'] != null
          ? JobStatistics.fromJson(json['selected_date_statistics'])
          : null,
      comparisonWithPreviousDay: json['comparison_with_previous_day'] != null
          ? PreviousDayComparison.fromJson(json['comparison_with_previous_day'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rider_id': riderId,
      'user_id': userId,
      'job_history': jobHistory.map((item) => item.toJson()).toList(),
      'statistics': statistics.toJson(),
      if (selectedDateJobs != null)
        'selected_date_jobs': selectedDateJobs!
            .map((item) => item.toJson())
            .toList(),
      if (selectedDateStatistics != null)
        'selected_date_statistics': selectedDateStatistics!.toJson(),
      if (comparisonWithPreviousDay != null)
        'comparison_with_previous_day': comparisonWithPreviousDay!.toJson(),
    };
  }
}

// Individual job item
class JobItem {
  final int orderId;
  final int customerId;
  final int marketId;
  final int riderId;
  final String? address;
  final String? deliveryType;
  final String paymentMethod;
  final String? note;
  final String distanceKm;
  final String deliveryFee;
  final String bonus;
  final String totalPrice;
  final String status; // 'completed', 'cancelled'
  final String? shopStatus;
  final String riderRequiredGp;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String shopName;
  final String shopAddress;
  final String displayName;
  final String customerPhone;

  JobItem({
    required this.orderId,
    required this.customerId,
    required this.marketId,
    required this.riderId,
    this.address,
    this.deliveryType,
    required this.paymentMethod,
    this.note,
    required this.distanceKm,
    required this.deliveryFee,
    required this.bonus,
    required this.totalPrice,
    required this.status,
    this.shopStatus,
    required this.riderRequiredGp,
    required this.createdAt,
    required this.updatedAt,
    required this.shopName,
    required this.shopAddress,
    required this.displayName,
    required this.customerPhone,
  });

  factory JobItem.fromJson(Map<String, dynamic> json) {
    return JobItem(
      orderId: json['order_id'] ?? 0,
      customerId: json['customer_id'] ?? 0,
      marketId: json['market_id'] ?? 0,
      riderId: json['rider_id'] ?? 0,
      address: json['address'],
      deliveryType: json['delivery_type'],
      paymentMethod: json['payment_method'] ?? '',
      note: json['note'],
      distanceKm: json['distance_km']?.toString() ?? '0.00',
      deliveryFee: json['delivery_fee']?.toString() ?? '0.00',
      bonus: json['bonus']?.toString() ?? '0.00',
      totalPrice: json['total_price']?.toString() ?? '0.00',
      status: json['status'] ?? '',
      shopStatus: json['shop_status'],
      riderRequiredGp: json['rider_required_gp']?.toString() ?? '0.00',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      shopName: json['shop_name'] ?? '',
      shopAddress: json['shop_address'] ?? '',
      displayName: json['display_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'customer_id': customerId,
      'market_id': marketId,
      'rider_id': riderId,
      if (address != null) 'address': address,
      if (deliveryType != null) 'delivery_type': deliveryType,
      'payment_method': paymentMethod,
      if (note != null) 'note': note,
      'distance_km': distanceKm,
      'delivery_fee': deliveryFee,
      'bonus': bonus,
      'total_price': totalPrice,
      'status': status,
      if (shopStatus != null) 'shop_status': shopStatus,
      'rider_required_gp': riderRequiredGp,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'shop_name': shopName,
      'shop_address': shopAddress,
      'display_name': displayName,
      'customer_phone': customerPhone,
    };
  }

  // Helper methods for UI
  double get totalEarnings => double.parse(deliveryFee);
  double get deliveryFeeAmount => double.parse(deliveryFee);
  double get bonusAmount => double.parse(bonus);
  double get riderGpAmount => double.parse(riderRequiredGp);
  double get distanceKmAmount => double.parse(distanceKm);
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  String get statusDisplayName => isCompleted ? 'สำเร็จ' : 'ยกเลิก';
}

// Statistics for job history
class JobStatistics {
  final String totalJobs;
  final String completedJobs;
  final String cancelledJobs;
  final String totalEarningsNoBonus;
  final String totalBonus;
  final String totalEarnings;
  final String avgEarningsPerJob;
  final String totalDistance;
  final String? totalGpDeducted;
  final String? totalJobsSelectedDate;
  final String? completedJobsSelectedDate;
  final String? cancelledJobsSelectedDate;
  final String? selectedDateEarningsNoBonus;
  final String? selectedDateBonus;
  final String? totalEarningsSelectedDate;
  final String? totalDistanceSelectedDate;
  final String? totalGpDeductedSelectedDate;
  final String? avgEarningsPerJobSelectedDate;

  JobStatistics({
    required this.totalJobs,
    required this.completedJobs,
    required this.cancelledJobs,
    required this.totalEarningsNoBonus,
    required this.totalBonus,
    required this.totalEarnings,
    required this.avgEarningsPerJob,
    required this.totalDistance,
    this.totalGpDeducted,
    this.totalJobsSelectedDate,
    this.completedJobsSelectedDate,
    this.cancelledJobsSelectedDate,
    this.selectedDateEarningsNoBonus,
    this.selectedDateBonus,
    this.totalEarningsSelectedDate,
    this.totalDistanceSelectedDate,
    this.totalGpDeductedSelectedDate,
    this.avgEarningsPerJobSelectedDate,
  });

  factory JobStatistics.fromJson(Map<String, dynamic> json) {
    // Helper function to get value from multiple possible field names
    String getValue(List<String> fieldNames, String defaultValue) {
      for (String fieldName in fieldNames) {
        if (json[fieldName] != null) {
          return json[fieldName].toString();
        }
      }
      return defaultValue;
    }

    return JobStatistics(
      totalJobs: getValue([
        'total_jobs',
        'total_jobs_selected_date',
        'total_jobs_selected_month',
        'total_jobs_selected_year',
        'total_jobs_date_range',
      ], '0'),
      completedJobs: getValue([
        'completed_jobs',
        'completed_jobs_selected_date',
        'completed_jobs_selected_month',
        'completed_jobs_selected_year',
        'completed_jobs_date_range',
      ], '0'),
      cancelledJobs: getValue([
        'cancelled_jobs',
        'cancelled_jobs_selected_date',
        'cancelled_jobs_selected_month',
        'cancelled_jobs_selected_year',
        'cancelled_jobs_date_range',
      ], '0'),
      totalEarningsNoBonus: getValue([
        'total_earnings_nobonus',
        'selected_date_earnings_nobonus',
        'selected_month_earnings_no_bonus',
        'selected_year_earnings_no_bonus',
        'date_range_earnings_no_bonus',
      ], '0.00'),
      totalBonus: getValue([
        'total_bonus',
        'selected_date_bonus',
        'selected_month_bonus',
        'selected_year_bonus',
        'date_range_bonus',
      ], '0.00'),
      totalEarnings: getValue([
        'total_earnings',
        'total_earnings_selected_date',
        'total_earnings_selected_month',
        'total_earnings_selected_year',
        'total_earnings_date_range',
      ], '0.00'),
      avgEarningsPerJob: getValue([
        'avg_earnings_per_job',
        'avg_earnings_per_job_selected_date',
        'avg_earnings_per_job_selected_month',
        'avg_earnings_per_job_selected_year',
        'avg_earnings_per_job_date_range',
      ], '0.00'),
      totalDistance: getValue([
        'total_distance',
        'total_distance_selected_date',
        'total_distance_selected_month',
        'total_distance_selected_year',
        'total_distance_date_range',
      ], '0.00'),
      totalGpDeducted:
          json['total_gp_deducted']?.toString() ??
          json['total_gp_deducted_selected_date']?.toString() ??
          json['total_gp_deducted_selected_month']?.toString() ??
          json['total_gp_deducted_selected_year']?.toString() ??
          json['total_gp_deducted_date_range']?.toString(),
      totalJobsSelectedDate: json['total_jobs_selected_date']?.toString(),
      completedJobsSelectedDate: json['completed_jobs_selected_date']
          ?.toString(),
      cancelledJobsSelectedDate: json['cancelled_jobs_selected_date']
          ?.toString(),
      selectedDateEarningsNoBonus: json['selected_date_earnings_nobonus']
          ?.toString(),
      selectedDateBonus: json['selected_date_bonus']?.toString(),
      totalEarningsSelectedDate: json['total_earnings_selected_date']
          ?.toString(),
      totalDistanceSelectedDate: json['total_distance_selected_date']
          ?.toString(),
      totalGpDeductedSelectedDate: json['total_gp_deducted_selected_date']
          ?.toString(),
      avgEarningsPerJobSelectedDate: json['avg_earnings_per_job_selected_date']
          ?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_jobs': totalJobs,
      'completed_jobs': completedJobs,
      'cancelled_jobs': cancelledJobs,
      'total_earnings_nobonus': totalEarningsNoBonus,
      'total_bonus': totalBonus,
      'total_earnings': totalEarnings,
      'avg_earnings_per_job': avgEarningsPerJob,
      'total_distance': totalDistance,
      if (totalGpDeducted != null) 'total_gp_deducted': totalGpDeducted,
      if (totalJobsSelectedDate != null)
        'total_jobs_selected_date': totalJobsSelectedDate,
      if (completedJobsSelectedDate != null)
        'completed_jobs_selected_date': completedJobsSelectedDate,
      if (cancelledJobsSelectedDate != null)
        'cancelled_jobs_selected_date': cancelledJobsSelectedDate,
      if (selectedDateEarningsNoBonus != null)
        'selected_date_earnings_nobonus': selectedDateEarningsNoBonus,
      if (selectedDateBonus != null) 'selected_date_bonus': selectedDateBonus,
      if (totalEarningsSelectedDate != null)
        'total_earnings_selected_date': totalEarningsSelectedDate,
      if (totalDistanceSelectedDate != null)
        'total_distance_selected_date': totalDistanceSelectedDate,
      if (totalGpDeductedSelectedDate != null)
        'total_gp_deducted_selected_date': totalGpDeductedSelectedDate,
      if (avgEarningsPerJobSelectedDate != null)
        'avg_earnings_per_job_selected_date': avgEarningsPerJobSelectedDate,
    };
  }

  // Helper methods for UI
  int get totalJobsInt => int.parse(totalJobs);
  int get completedJobsInt => int.parse(completedJobs);
  int get cancelledJobsInt => int.parse(cancelledJobs);
  double get totalEarningsAmount => double.parse(totalEarnings);
  double get totalBonusAmount => double.parse(totalBonus);
  double get avgEarningsAmount => double.parse(avgEarningsPerJob);
  double get totalDistanceAmount => double.parse(totalDistance);
}

// Comparison with previous day (for date-specific queries)
class PreviousDayComparison {
  final String previousDate;
  final String earningsChange;
  final String earningsChangePercent;
  final int jobsChange;
  final String previousDayEarnings;
  final String previousDayJobs;

  PreviousDayComparison({
    required this.previousDate,
    required this.earningsChange,
    required this.earningsChangePercent,
    required this.jobsChange,
    required this.previousDayEarnings,
    required this.previousDayJobs,
  });

  factory PreviousDayComparison.fromJson(Map<String, dynamic> json) {
    return PreviousDayComparison(
      previousDate: json['previous_date'] ?? '',
      earningsChange: json['earnings_change']?.toString() ?? '0.00',
      earningsChangePercent:
          json['earnings_change_percent']?.toString() ?? '0.00',
      jobsChange: json['jobs_change'] ?? 0,
      previousDayEarnings: json['previous_day_earnings']?.toString() ?? '0.00',
      previousDayJobs: json['previous_day_jobs']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'previous_date': previousDate,
      'earnings_change': earningsChange,
      'earnings_change_percent': earningsChangePercent,
      'jobs_change': jobsChange,
      'previous_day_earnings': previousDayEarnings,
      'previous_day_jobs': previousDayJobs,
    };
  }

  // Helper methods for UI
  double get earningsChangeAmount => double.parse(earningsChange);
  double get earningsChangePercentAmount => double.parse(earningsChangePercent);
  bool get isEarningsIncreased => earningsChangeAmount > 0;
  bool get isJobsIncreased => jobsChange > 0;
}
