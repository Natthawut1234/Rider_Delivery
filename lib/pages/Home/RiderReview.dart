import 'package:flutter/material.dart';
import '../../services/ReviewsService.dart';
import '../../APIs/Models/Reviews_model.dart';

class RiderReviewPage extends StatefulWidget {
  const RiderReviewPage({Key? key}) : super(key: key);

  @override
  State<RiderReviewPage> createState() => _RiderReviewPageState();
}

class _RiderReviewPageState extends State<RiderReviewPage> {
  // Real data from API
  RiderSummary? _riderSummary;
  List<ReviewsModel> _reviews = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ReviewsService().fetchRiderReviews(limit: 100);

      if (result['success']) {
        final data = result['data'];

        setState(() {
          // Parse rider summary with null safety
          if (data['rider_summary'] != null) {
            try {
              _riderSummary = RiderSummary.fromJson(data['rider_summary']);
            } catch (e) {
              print('Error parsing rider summary: $e');
              // สร้าง RiderSummary เริ่มต้นถ้าไม่สามารถ parse ได้
              _riderSummary = RiderSummary(
                riderId: 0,
                riderName: '',
                ratingAvg: 0.0,
                reviewsCount: 0,
              );
            }
          }

          // Parse reviews list with error handling
          try {
            _reviews =
                (data['items'] as List?)
                    ?.map((json) {
                      try {
                        return ReviewsModel.fromJson(json);
                      } catch (e) {
                        print('Error parsing review item: $e');
                        return null;
                      }
                    })
                    .where((review) => review != null)
                    .cast<ReviewsModel>()
                    .toList() ??
                [];
          } catch (e) {
            print('Error parsing reviews list: $e');
            _reviews = [];
          }

          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'ไม่สามารถโหลดรีวิวได้';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error in _loadReviews: $e');
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาดในการเชื่อมต่อ';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshReviews() async {
    await _loadReviews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'รีวิวจากลูกค้า',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green[600],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshReviews,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshReviews,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshReviews,
              child: Column(
                children: [
                  // ส่วนแสดงสรุปคะแนน
                  _buildRatingSummary(),

                  // ส่วนแสดงรายการรีวิว
                  Expanded(
                    child: _reviews.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.star_border,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'ยังไม่มีรีวิวจากลูกค้า',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            itemCount: _reviews.length,
                            itemBuilder: (context, index) {
                              final review = _reviews[index];
                              return _buildReviewCard(review);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  // Widget สำหรับแสดงสรุปคะแนน
  Widget _buildRatingSummary() {
    if (_riderSummary == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'ยังไม่มีข้อมูลรีวิว',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    // คำนวณการกระจายคะแนนจาก _riderSummary (with null safety)
    final Map<int, int> distribution = {
      5: _riderSummary!.rating5,
      4: _riderSummary!.rating4,
      3: _riderSummary!.rating3,
      2: _riderSummary!.rating2,
      1: _riderSummary!.rating1,
    };

    // ปกป้องการหารด้วยศูนย์
    final totalReviews = _riderSummary!.reviewsCount;
    final avgRating =
        _riderSummary!.ratingAvg.isFinite && !_riderSummary!.ratingAvg.isNaN
        ? _riderSummary!.ratingAvg
        : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // ค่าเฉลี่ยคะแนนใหญ่
              Column(
                children: [
                  Text(
                    avgRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                  // ดาวแสดงค่าเฉลี่ย
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: () {
                      final double rounded =
                          (avgRating * 2).round() / 2.0; // ปัดเป็น 0.5
                      return List.generate(5, (index) {
                        final pos = index + 1;
                        IconData icon;
                        if (rounded >= pos) {
                          icon = Icons.star;
                        } else if (rounded >= pos - 0.5) {
                          icon = Icons.star_half;
                        } else {
                          icon = Icons.star_border;
                        }
                        return Icon(icon, color: Colors.amber, size: 20);
                      });
                    }(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalReviews รีวิว',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),

              const SizedBox(width: 24),

              // แท่งกราฟแสดงการกระจายคะแนน
              Expanded(
                child: Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    int count = distribution[star]!;
                    double percentage = totalReviews == 0
                        ? 0
                        : count / totalReviews;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text('$star'),
                          const SizedBox(width: 4),
                          Icon(Icons.star, size: 12, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: FractionallySizedBox(
                                widthFactor: percentage,
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 20,
                            child: Text(
                              '$count',
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget สำหรับแสดงรีวิวแต่ละรายการ
  Widget _buildReviewCard(ReviewsModel review) {
    Color ratingColor = _getRatingColor(review.rating);

    // Format date
    final formattedDate =
        '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนหัวของรีวิว
            Row(
              children: [
                // Avatar ของลูกค้า
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  radius: 20,
                  backgroundImage: review.reviewerPhoto.isNotEmpty
                      ? NetworkImage(review.reviewerPhoto)
                      : null,
                  child: review.reviewerPhoto.isEmpty
                      ? Text(
                          review.reviewerName.isNotEmpty
                              ? review.reviewerName[0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),

                // ชื่อและวันที่
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.reviewerName.isNotEmpty
                            ? review.reviewerName
                            : 'ลูกค้า',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // คะแนนดาว
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ratingColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: ratingColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${review.rating}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: ratingColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ข้อความรีวิว
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
              child: Text(
                review.comment.isNotEmpty ? review.comment : 'ไม่มีความคิดเห็น',
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ฟังก์ชันสำหรับกำหนดสีตามคะแนน
  Color _getRatingColor(int rating) {
    switch (rating) {
      case 5:
        return Colors.green;
      case 4:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 2:
        return Colors.deepOrange;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
