import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/Income_and_JobHistoryService.dart';
import '../../APIs/Models/Income_and_JobHistory_model.dart';

class IncomePage extends StatefulWidget {
  const IncomePage({super.key});

  @override
  _IncomePageState createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  String selectedPeriod = "วันนี้";
  DateTime selectedDate = DateTime.now();
  final JobHistoryService _service = JobHistoryService();

  // Data from API
  List<JobItem> _allJobs = [];
  List<JobItem> _filteredJobs = [];
  JobStatistics? _statistics;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadJobHistory();
  }

  // Load job history from API
  Future<void> _loadJobHistory() async {
    print(
      '🚀 Income: Starting _loadJobHistory for period: $selectedPeriod, date: $selectedDate',
    );

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Map<String, dynamic> response;

      if (selectedPeriod == 'วันนี้') {
        final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
        print('📅 Income: Fetching by date: $dateStr');
        response = await _service.fetchJobHistoryByDate(dateStr);
      } else if (selectedPeriod == 'เดือนนี้') {
        print(
          '📅 Income: Fetching by month: ${selectedDate.month}/${selectedDate.year}',
        );
        response = await _service.fetchJobHistoryByMonth(
          selectedDate.month,
          selectedDate.year,
        );
      } else if (selectedPeriod == 'ปีนี้') {
        print('📅 Income: Fetching by year: ${selectedDate.year}');
        response = await _service.fetchJobHistoryByYear(selectedDate.year);
      } else if (selectedPeriod == 'ทั้งหมด') {
        print('📅 Income: Fetching all job history');
        response = await _service.fetchAllJobHistory();
      } else {
        // For week, use date range
        final start = _startOfWeek(selectedDate);
        final end = _endOfWeek(selectedDate);
        final startStr = DateFormat('yyyy-MM-dd').format(start);
        final endStr = DateFormat('yyyy-MM-dd').format(end);
        print('📅 Income: Fetching by range: $startStr to $endStr');
        response = await _service.fetchJobHistoryByDateRange(startStr, endStr);
      }

      print('📡 Income: API Response success=${response['success']}');

      if (response['success'] == true) {
        final jobHistoryResponse = JobHistoryResponse.fromJson(
          response['data'],
        );
        print(
          '🔍 Income Debug - Total jobs from API: ${jobHistoryResponse.data.jobHistory.length}',
        );

        // Debug: print all jobs with their status
        for (var job in jobHistoryResponse.data.jobHistory) {
          print(
            '📝 Job ${job.orderId}: ${job.shopName} - Status: ${job.status} (${job.isCompleted ? "✅ Completed" : "❌ Not Completed"})',
          );
        }

        setState(() {
          _allJobs = jobHistoryResponse.data.jobHistory;
          _statistics = jobHistoryResponse.data.statistics;
          _filterJobs();
        });

        print(
          '✅ Income: Data loaded successfully. Total: ${_allJobs.length}, Filtered: ${_filteredJobs.length}',
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

  // Filter jobs for Income page (only completed jobs)
  void _filterJobs() {
    _filteredJobs = _allJobs.where((job) => job.isCompleted).toList();
    print(
      '🎯 Income Filter Result: ${_filteredJobs.length} completed jobs out of ${_allJobs.length} total jobs',
    );

    if (_filteredJobs.isEmpty && _allJobs.isNotEmpty) {
      print(
        '⚠️ Warning: No completed jobs found, but ${_allJobs.length} total jobs exist',
      );
      // Debug: Show status of all jobs
      for (var job in _allJobs) {
        print(
          '   Job ${job.orderId}: status="${job.status}", isCompleted=${job.isCompleted}',
        );
      }
    }
  }

  DateTime _startOfWeek(DateTime d) {
    final wd = d.weekday; // 1 = Mon
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: wd - 1));
  }

  DateTime _endOfWeek(DateTime d) {
    return _startOfWeek(d).add(const Duration(days: 6));
  }

  // Calculate total income from completed jobs
  double get _totalIncome {
    return _filteredJobs.fold(0.0, (sum, job) => sum + job.totalEarnings);
  }

  // Calculate total bonus from completed jobs
  double get _totalBonus {
    return _filteredJobs.fold(0.0, (sum, job) => sum + job.bonusAmount);
  }

  // Get job count
  int get _jobCount {
    return _filteredJobs.length;
  }

  void _prevPeriod() {
    setState(() {
      if (selectedPeriod == 'วันนี้') {
        selectedDate = selectedDate.subtract(const Duration(days: 1));
      } else if (selectedPeriod == 'สัปดาห์นี้') {
        selectedDate = selectedDate.subtract(const Duration(days: 7));
      } else if (selectedPeriod == 'เดือนนี้') {
        selectedDate = DateTime(
          selectedDate.year,
          selectedDate.month - 1,
          selectedDate.day,
        );
      } else if (selectedPeriod == 'ปีนี้') {
        selectedDate = DateTime(
          selectedDate.year - 1,
          selectedDate.month,
          selectedDate.day,
        );
      }
      // For 'ทั้งหมด', no navigation needed
    });
    if (selectedPeriod != 'ทั้งหมด') {
      _loadJobHistory();
    }
  }

  void _nextPeriod() {
    setState(() {
      if (selectedPeriod == 'วันนี้') {
        selectedDate = selectedDate.add(const Duration(days: 1));
      } else if (selectedPeriod == 'สัปดาห์นี้') {
        selectedDate = selectedDate.add(const Duration(days: 7));
      } else if (selectedPeriod == 'เดือนนี้') {
        selectedDate = DateTime(
          selectedDate.year,
          selectedDate.month + 1,
          selectedDate.day,
        );
      } else if (selectedPeriod == 'ปีนี้') {
        selectedDate = DateTime(
          selectedDate.year + 1,
          selectedDate.month,
          selectedDate.day,
        );
      }
      // For 'ทั้งหมด', no navigation needed
    });
    if (selectedPeriod != 'ทั้งหมด') {
      _loadJobHistory();
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
      _loadJobHistory();
    }
  }

  String get _periodLabel {
    if (selectedPeriod == 'วันนี้') {
      return '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
    } else if (selectedPeriod == 'สัปดาห์นี้') {
      final s = _startOfWeek(selectedDate);
      final e = _endOfWeek(selectedDate);
      return '${s.day}/${s.month} - ${e.day}/${e.month}/${e.year}';
    } else if (selectedPeriod == 'เดือนนี้') {
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
    } else if (selectedPeriod == 'ปีนี้') {
      return 'ปี ${selectedDate.year}';
    } else {
      return 'ประวัติทั้งหมด';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายได้'),
        backgroundColor: Colors.green,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadJobHistory,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                selectedPeriod = value;
                selectedDate = DateTime.now();
              });
              _loadJobHistory();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: "วันนี้", child: Text("วันนี้")),
              PopupMenuItem(value: "สัปดาห์นี้", child: Text("สัปดาห์นี้")),
              PopupMenuItem(value: "เดือนนี้", child: Text("เดือนนี้")),
              PopupMenuItem(value: "ปีนี้", child: Text("ปีนี้")),
              PopupMenuItem(value: "ทั้งหมด", child: Text("ทั้งหมด")),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Column(
        children: [
          // date / period selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: selectedPeriod == 'ทั้งหมด' ? null : _prevPeriod,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      if (selectedPeriod == 'ทั้งหมด') {
                        // No date picker for "ทั้งหมด"
                        return;
                      } else if (selectedPeriod == 'เดือนนี้') {
                        // Month picker: open date picker and use selected month
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
                        if (picked != null) {
                          setState(
                            () => selectedDate = DateTime(
                              picked.year,
                              picked.month,
                              1,
                            ),
                          );
                          _loadJobHistory();
                        }
                      } else if (selectedPeriod == 'ปีนี้') {
                        // Year picker: open date picker and use selected year
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365 * 5),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365 * 2),
                          ),
                        );
                        if (picked != null) {
                          setState(
                            () => selectedDate = DateTime(picked.year, 1, 1),
                          );
                          _loadJobHistory();
                        }
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _periodLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: selectedPeriod == 'ทั้งหมด' ? null : _nextPeriod,
                ),
              ],
            ),
          ),

          // Summary card
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'รวมรายได้',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '฿${_totalIncome.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      // const SizedBox(height: 8),
                      // Text(
                      //   '$selectedPeriod • $_jobCount งาน',
                      //   style: const TextStyle(
                      //     fontSize: 12,
                      //     color: Colors.grey,
                      //   ),
                      // ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.green,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),

          // Breakdown cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Adjust layout based on screen width
                final isSmallScreen = constraints.maxWidth < 350;

                if (isSmallScreen) {
                  // Stack cards vertically for very small screens
                  return Column(
                    children: [
                      Row(
                        children: [
                          _buildSmallStat(
                            'งานสำเร็จ',
                            '$_jobCount',
                            Icons.assignment_turned_in,
                          ),
                          const SizedBox(width: 8),
                          _buildSmallStat(
                            'โบนัส',
                            '฿${_totalBonus.toStringAsFixed(2)}',
                            Icons.bolt,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildSmallStat(
                            'เฉลี่ย/งาน',
                            '฿${_jobCount > 0 ? (_totalIncome / _jobCount).toStringAsFixed(2) : '0.00'}',
                            Icons.trending_up,
                          ),
                        ],
                      ),
                    ],
                  );
                } else {
                  // Single row for larger screens
                  return Row(
                    children: [
                      _buildSmallStat(
                        'งานสำเร็จ',
                        '$_jobCount',
                        Icons.assignment_turned_in,
                      ),
                      const SizedBox(width: 8),
                      _buildSmallStat(
                        'โบนัส',
                        '฿${_totalBonus.toStringAsFixed(2)}',
                        Icons.bolt,
                      ),
                      const SizedBox(width: 8),
                      _buildSmallStat(
                        'เฉลี่ย/งาน',
                        '฿${_jobCount > 0 ? (_totalIncome / _jobCount).toStringAsFixed(2) : '0.00'}',
                        Icons.trending_up,
                      ),
                    ],
                  );
                }
              },
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
                    'ประวัติการรับเงิน',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  selectedPeriod,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // List
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
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'ไม่มีรายได้ในช่วง $_periodLabel',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Debug info
              if (_allJobs.isNotEmpty)
                Column(
                  children: [
                    Text(
                      'Debug: มี ${_allJobs.length} งานทั้งหมด',
                      style: TextStyle(color: Colors.orange[600], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'แต่ไม่มีงาน "completed"',
                      style: TextStyle(color: Colors.red[600], fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Show all jobs temporarily for debugging
                        setState(() {
                          _filteredJobs = _allJobs; // Show all jobs temporarily
                        });
                      },
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text(
                        'แสดงทั้งหมด (Debug)',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
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
                  // Leading icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delivery_dining,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ส่งอาหาร - ${job.shopName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ลูกค้า: ${job.displayName}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Trailing price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '฿${job.totalEarnings.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (job.bonusAmount > 0) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'โบนัส ฿${job.bonusAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
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

  void _showJobDetail(JobItem job) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) {
        return Padding(
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
                      'Order #${job.orderId}',
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
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      job.statusDisplayName,
                      style: const TextStyle(
                        color: Colors.green,
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
              _buildDetailRow('วิธีชำระ', job.paymentMethod, Icons.payment),
              const Divider(),
              _buildDetailRow(
                'ค่าส่ง',
                '฿${job.deliveryFeeAmount.toStringAsFixed(2)}',
                Icons.local_shipping,
              ),
              if (job.bonusAmount > 0)
                _buildDetailRow(
                  'โบนัส',
                  '฿${job.bonusAmount.toStringAsFixed(2)}',
                  Icons.bolt,
                ),
              _buildDetailRow(
                'รายได้รวม',
                '฿${job.totalEarnings.toStringAsFixed(2)}',
                Icons.monetization_on,
                isTotal: true,
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    bool isTotal = false,
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
              color: isTotal ? Colors.blue : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStat(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 6),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 100;

            if (isNarrow) {
              // Vertical layout for very narrow cards
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(icon, color: Colors.green, size: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            } else {
              // Horizontal layout for wider cards
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: Colors.green, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            value,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
