import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/Income_and_JobHistoryService.dart';
import '../../APIs/Models/Income_and_JobHistory_model.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  DateTime selectedDate = DateTime.now();
  String period =
      'วันนี้'; // 'วันนี้' | 'สัปดาห์นี้' | 'เดือนนี้' | 'ปีนี้' | 'ทั้งหมด'
  final JobHistoryService _service = JobHistoryService();

  // Data from API
  List<JobItem> _allJobs = [];
  List<JobItem> _filteredJobs = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    print('🚀 Jobs: initState called');
    _loadJobHistory();
  }

  // Load job history from API
  Future<void> _loadJobHistory() async {
    print(
      '🚀 Jobs: Starting _loadJobHistory for period: $period, date: $selectedDate',
    );

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Map<String, dynamic> response;

      if (period == 'วันนี้') {
        final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
        print('📅 Jobs: Fetching by date: $dateStr');
        response = await _service.fetchJobHistoryByDate(dateStr);
      } else if (period == 'เดือนนี้') {
        print(
          '📅 Jobs: Fetching by month: ${selectedDate.month}/${selectedDate.year}',
        );
        response = await _service.fetchJobHistoryByMonth(
          selectedDate.month,
          selectedDate.year,
        );
      } else if (period == 'ปีนี้') {
        print('📅 Jobs: Fetching by year: ${selectedDate.year}');
        response = await _service.fetchJobHistoryByYear(selectedDate.year);
      } else if (period == 'ทั้งหมด') {
        print('📅 Jobs: Fetching all job history');
        response = await _service.fetchAllJobHistory();
      } else {
        // For week, use date range
        final start = _startOfWeek(selectedDate);
        final end = _endOfWeek(selectedDate);
        final startStr = DateFormat('yyyy-MM-dd').format(start);
        final endStr = DateFormat('yyyy-MM-dd').format(end);
        print('📅 Jobs: Fetching by range: $startStr to $endStr');
        response = await _service.fetchJobHistoryByDateRange(startStr, endStr);
      }

      print('📡 Jobs: API Response success=${response['success']}');

      if (response['success'] == true) {
        final jobHistoryResponse = JobHistoryResponse.fromJson(
          response['data'],
        );

        setState(() {
          _allJobs = jobHistoryResponse.data.jobHistory;
          _filterJobs();
        });

        print(
          '✅ Jobs: Data loaded successfully. Total: ${_allJobs.length}, Filtered: ${_filteredJobs.length}',
        );
      } else {
        setState(() {
          _error = response['message'] ?? 'เกิดข้อผิดพลาดในการดึงข้อมูล';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Filter jobs for Jobs page (show all jobs - both completed and cancelled)
  void _filterJobs() {
    _filteredJobs = _allJobs; // Show all jobs unlike Income page
    _filteredJobs.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    ); // Sort by date desc
    print('🎯 Jobs Filter Result: ${_filteredJobs.length} total jobs');
  }

  DateTime _startOfWeek(DateTime d) {
    final wd = d.weekday; // 1 = Mon
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: wd - 1));
  }

  DateTime _endOfWeek(DateTime d) {
    return _startOfWeek(d).add(const Duration(days: 6));
  }

  // Calculate total GP deducted from all jobs
  double get totalGpDeducted {
    return _filteredJobs.fold(0.0, (sum, job) => sum + job.riderGpAmount);
  }

  // Calculate total credit support from all jobs
  double get totalCreditSupport {
    return _filteredJobs.fold(0.0, (sum, job) => sum + job.bonusAmount);
  }

  // Calculate actual credit deducted (original - support)
  double get actualCreditDeducted {
    return totalGpDeducted;
  }

  // Calculate total jobs count
  int get jobCount => _filteredJobs.length;

  // Calculate completed jobs count
  int get completedJobCount =>
      _filteredJobs.where((job) => job.isCompleted).length;

  // Calculate cancelled jobs count
  int get cancelledJobCount =>
      _filteredJobs.where((job) => job.isCancelled).length;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  void _prevPeriod() {
    setState(() {
      if (period == 'วันนี้') {
        selectedDate = selectedDate.subtract(const Duration(days: 1));
      } else if (period == 'สัปดาห์นี้') {
        selectedDate = selectedDate.subtract(const Duration(days: 7));
      } else if (period == 'เดือนนี้') {
        selectedDate = DateTime(selectedDate.year, selectedDate.month - 1, 1);
      } else if (period == 'ปีนี้') {
        selectedDate = DateTime(
          selectedDate.year - 1,
          selectedDate.month,
          selectedDate.day,
        );
      }
      // For 'ทั้งหมด', no navigation needed
    });
    if (period != 'ทั้งหมด') {
      _loadJobHistory();
    }
  }

  void _nextPeriod() {
    setState(() {
      if (period == 'วันนี้') {
        selectedDate = selectedDate.add(const Duration(days: 1));
      } else if (period == 'สัปดาห์นี้') {
        selectedDate = selectedDate.add(const Duration(days: 7));
      } else if (period == 'เดือนนี้') {
        selectedDate = DateTime(selectedDate.year, selectedDate.month + 1, 1);
      } else if (period == 'ปีนี้') {
        selectedDate = DateTime(
          selectedDate.year + 1,
          selectedDate.month,
          selectedDate.day,
        );
      }
      // For 'ทั้งหมด', no navigation needed
    });
    if (period != 'ทั้งหมด') {
      _loadJobHistory();
    }
  }

  String get _periodLabel {
    if (period == 'วันนี้') {
      return '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
    } else if (period == 'สัปดาห์นี้') {
      final s = _startOfWeek(selectedDate);
      final e = _endOfWeek(selectedDate);
      return '${s.day}/${s.month} - ${e.day}/${e.month}/${e.year}';
    } else if (period == 'เดือนนี้') {
      final months = [
        '',
        'มกราคม',
        'กุมภาพันธ์',
        'มีนาคม',
        'เมษายน',
        'พฤษภาคม',
        'มิถุนายน',
        'กรกฎาคม',
        'สิงหาคม',
        'กันยายน',
        'ตุลาคม',
        'พฤศจิกายน',
        'ธันวาคม',
      ];
      return '${months[selectedDate.month]} ${selectedDate.year}';
    } else if (period == 'ปีนี้') {
      return 'ปี ${selectedDate.year}';
    } else {
      return 'ประวัติทั้งหมด';
    }
  }

  void _showJobDetail(JobItem job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.receipt_long, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Order #${job.orderId} - ${job.shopName}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: job.isCompleted
                                ? Colors.green[100]
                                : Colors.red[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            job.statusDisplayName,
                            style: TextStyle(
                              color: job.isCompleted
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('ร้านค้า', job.shopName, Icons.store),
                    _buildDetailRow('ลูกค้า', job.displayName, Icons.person),
                    _buildDetailRow(
                      'เวลา',
                      DateFormat('dd/MM/yyyy HH:mm').format(job.createdAt),
                      Icons.access_time,
                    ),
                    _buildDetailRow(
                      'ระยะทาง',
                      '${job.distanceKm} กม.',
                      Icons.location_on,
                    ),
                    _buildDetailRow(
                      'วิธีชำระ',
                      job.paymentMethod,
                      Icons.payment,
                    ),
                    const Divider(),

                    // 💳 ค่าใช้จ่าย
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.credit_card,
                                color: Colors.orange,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'ค่าใช้จ่าย',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            'เครดิตที่ต้องจ่าย',
                            '฿${(job.riderGpAmount + job.bonusAmount).toStringAsFixed(2)}',
                            Icons.payments,
                          ),
                          if (job.bonusAmount > 0) ...[
                            _buildDetailRow(
                              'เครดิตช่วยจ่าย',
                              '-฿${job.bonusAmount.toStringAsFixed(2)}',
                              Icons.savings,
                              valueColor: Colors.orange,
                            ),
                            const SizedBox(height: 4),
                            const Divider(height: 8),
                            _buildDetailRow(
                              'เครดิตที่หักจริง',
                              '฿${(job.riderGpAmount).toStringAsFixed(2)}',
                              Icons.remove_circle_outline,
                              isTotal: true,
                              valueColor: Colors.red,
                            ),
                          ] else ...[
                            _buildDetailRow(
                              'เครดิตที่หักจริง',
                              '฿${job.riderGpAmount.toStringAsFixed(2)}',
                              Icons.remove_circle_outline,
                              isTotal: true,
                              valueColor: Colors.red,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // const SizedBox(height: 16),
                    // Row(
                    //   children: [
                    //     Expanded(
                    //       child: ElevatedButton.icon(
                    //         onPressed: () {
                    //           Navigator.pop(context);
                    //           // TODO: เชื่อมไปดูเส้นทางจริง
                    //         },
                    //         icon: const Icon(Icons.map),
                    //         label: const Text('ดูเส้นทาง'),
                    //         style: ElevatedButton.styleFrom(
                    //           backgroundColor: Colors.green,
                    //           foregroundColor: Colors.white,
                    //         ),
                    //       ),
                    //     ),
                    //     const SizedBox(width: 8),
                    //     Expanded(
                    //       child: OutlinedButton.icon(
                    //         onPressed: () {
                    //           Navigator.pop(context);
                    //           // TODO: ดูรายละเอียดเพิ่มเติม
                    //         },
                    //         icon: const Icon(Icons.info_outline),
                    //         label: const Text('รายละเอียด'),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    // Safe area padding
                    // SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    bool isTotal = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
              color: valueColor ?? (isTotal ? Colors.red : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 💳 ค่าใช้จ่าย Header
            Row(
              children: [
                const Icon(Icons.credit_card, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'ค่าใช้จ่าย',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // เครดิตที่ต้องจ่าย
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'เครดิตที่ต้องจ่าย:',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  '฿${(totalGpDeducted + totalCreditSupport).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),

            // เครดิตช่วยจ่าย (แสดงเฉพาะเมื่อมี)
            if (totalCreditSupport > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'เครดิตช่วยจ่าย:',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    '-฿${totalCreditSupport.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
            ],

            // เครดิตที่หักจริง
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'เครดิตที่หักจริง',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '฿${actualCreditDeducted.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallStat(
    String title,
    String value,
    IconData icon, {
    bool isCredit = false,
  }) {
    final isCancel = title == 'ยกเลิก';
    final cardColor = isCredit
        ? Colors.orange
        : (isCancel ? Colors.red : Colors.green);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.04), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardColor[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: cardColor, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCredit
                          ? Colors.orange
                          : (isCancel ? Colors.red : null),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print(
      '🏗️ Jobs: build called - loading: $_isLoading, error: $_error, jobs: ${_filteredJobs.length}',
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("ประวัติรับงาน"),
        backgroundColor: Colors.green,
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              setState(() {
                period = v;
                selectedDate = DateTime.now();
              });
              _loadJobHistory();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'วันนี้', child: Text('วันนี้')),
              PopupMenuItem(value: 'สัปดาห์นี้', child: Text('สัปดาห์นี้')),
              PopupMenuItem(value: 'เดือนนี้', child: Text('เดือนนี้')),
              PopupMenuItem(value: 'ปีนี้', child: Text('ปีนี้')),
              PopupMenuItem(value: 'ทั้งหมด', child: Text('ทั้งหมด')),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Column(
        children: [
          // date selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: period == 'ทั้งหมด' ? null : _prevPeriod,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      if (period == 'เดือนนี้') {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365 * 2),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365 * 2),
                          ),
                        );
                        if (picked != null)
                          setState(
                            () => selectedDate = DateTime(
                              picked.year,
                              picked.month,
                              1,
                            ),
                          );
                      } else {
                        await _pickDate();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _periodLabel,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: period == 'ทั้งหมด' ? null : _nextPeriod,
                ),
              ],
            ),
          ),

          _summaryCard(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: _smallStat('งาน', '$jobCount', Icons.list_alt)),
                const SizedBox(width: 8),
                Expanded(
                  child: _smallStat(
                    'สำเร็จ',
                    '$completedJobCount',
                    Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 8),
                if (totalCreditSupport > 0) ...[
                  Expanded(
                    child: _smallStat(
                      'ช่วยจ่าย',
                      '฿${totalCreditSupport.toStringAsFixed(0)}',
                      Icons.savings,
                      isCredit: true,
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: _smallStat(
                      'ยกเลิก',
                      '$cancelledJobCount',
                      Icons.cancel,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Header for list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'รายการออเดอร์',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
                // Text(
                //   'GP หัก',
                //   style: const TextStyle(color: Colors.grey, fontSize: 12),
                // ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildJobsList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsList() {
    print(
      '🔍 _buildJobsList called: loading=$_isLoading, error=$_error, jobs=${_filteredJobs.length}',
    );

    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadJobHistory,
                child: const Text('ลองใหม่'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'ไม่มีงานในช่วง $_periodLabel',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _filteredJobs.length,
      separatorBuilder: (_, __) => const Divider(height: 12),
      itemBuilder: (context, index) {
        final job = _filteredJobs[index];
        final dateLabel = DateFormat('dd/MM/yyyy HH:mm').format(job.createdAt);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: InkWell(
            onTap: () => _showJobDetail(job),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: job.isCompleted
                        ? Colors.green[50]
                        : Colors.red[50],
                    child: Icon(
                      job.isCompleted ? Icons.check_circle : Icons.cancel,
                      color: job.isCompleted ? Colors.green : Colors.red,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.shopName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$dateLabel • ${job.displayName}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          job.statusDisplayName,
                          style: TextStyle(
                            fontSize: 11,
                            color: job.isCompleted ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (job.bonusAmount > 0) ...[
                        Text(
                          'หัก ฿${(job.riderGpAmount + job.bonusAmount).toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ช่วย ฿${job.bonusAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '฿${(job.riderGpAmount).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ] else ...[
                        Text(
                          '฿${job.riderGpAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
