import 'package:flutter/material.dart';
import 'transaction_filter_dialog.dart';
import '../../../APIs/middleware/topupGP.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  String selectedFilter = 'ทั้งหมด';
  String selectedTopupSubFilter = ''; // สำหรับกรองย่อยในการเติมเงิน

  // ข้อมูลจาก API
  List<TransactionItem> allTransactions = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  Map<String, dynamic> statistics = {};

  @override
  void initState() {
    super.initState();
    _loadTransactionHistory();
  }

  // ฟังก์ชันดึงประวัติการเติมเงินจาก API
  Future<void> _loadTransactionHistory() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final topupAPI = TopupGP();
      final result = await topupAPI.getTopupHistory();

      if (result['success']) {
        final topupHistory = result['data']['topup_history'] as List<dynamic>;
        final stats = result['data']['statistics'] as Map<String, dynamic>;

        // Mock data สำหรับค่าบริการรับงาน
        final mockJobData = _generateMockJobData();

        setState(() {
          // รวมข้อมูลการเติมเงินและค่าบริการ
          allTransactions = [
            // ข้อมูลการเติมเงินจาก API
            ...topupHistory.map((item) {
              return TransactionItem(
                id: item['topup_id'].toString(),
                type: 'topup',
                icon: Icons.add_circle,
                title: 'เติมเครดิต PromptPay',
                amount: double.parse(item['amount'].toString()),
                date: _formatDate(item['created_at']),
                isDebit: false,
                status: item['status'],
                slipUrl: item['slip_url'],
                rejectionReason: item['rejection_reason'],
                approvedAt: item['approved_at'],
              );
            }).toList(),
            // ข้อมูล Mock ค่าบริการ
            ...mockJobData,
          ];

          // เรียงตามวันที่ล่าสุด
          allTransactions.sort((a, b) => b.date.compareTo(a.date));

          // สถิติรวม
          statistics = {
            ...stats,
            // เพิ่มสถิติค่าบริการ (Mock)
            'total_jobs_taken': mockJobData.length, // จำนวนงานที่รับทั้งหมด
            'total_service_fees': mockJobData.fold(
              0.0,
              (sum, job) => sum + job.amount,
            ),
          };

          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          errorMessage = result['message'] ?? 'ไม่สามารถดึงประวัติได้';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = 'เกิดข้อผิดพลาด: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  // สร้าง Mock data สำหรับค่าบริการรับงาน
  List<TransactionItem> _generateMockJobData() {
    final now = DateTime.now();
    return [
      // ค่าบริการรับงาน
      TransactionItem(
        id: 'fee_001',
        type: 'service_fee',
        icon: Icons.remove_circle,
        title: 'หักค่ารับงาน #001',
        amount: 10.0,
        date: _formatDate(
          now.subtract(const Duration(hours: 2, minutes: 5)).toIso8601String(),
        ),
        isDebit: true,
        status: 'completed',
      ),
      TransactionItem(
        id: 'fee_002',
        type: 'service_fee',
        icon: Icons.remove_circle,
        title: 'หักค่ารับงาน #002',
        amount: 10.0,
        date: _formatDate(
          now.subtract(const Duration(hours: 5, minutes: 5)).toIso8601String(),
        ),
        isDebit: true,
        status: 'completed',
      ),
      TransactionItem(
        id: 'fee_003',
        type: 'service_fee',
        icon: Icons.remove_circle,
        title: 'หักค่ารับงาน #003',
        amount: 10.0,
        date: _formatDate(
          now.subtract(const Duration(days: 1, minutes: 5)).toIso8601String(),
        ),
        isDebit: true,
        status: 'completed',
      ),
      TransactionItem(
        id: 'fee_004',
        type: 'service_fee',
        icon: Icons.remove_circle,
        title: 'หักค่ารับงาน #004',
        amount: 10.0,
        date: _formatDate(
          now.subtract(const Duration(days: 2)).toIso8601String(),
        ),
        isDebit: true,
        status: 'completed',
      ),
      TransactionItem(
        id: 'fee_005',
        type: 'service_fee',
        icon: Icons.remove_circle,
        title: 'หักค่ารับงาน #005',
        amount: 10.0,
        date: _formatDate(
          now.subtract(const Duration(days: 3)).toIso8601String(),
        ),
        isDebit: true,
        status: 'completed',
      ),
    ];
  }

  // ฟังก์ชันแปลงวันที่
  String _formatDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        return 'วันนี้ ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'เมื่อวาน ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} วันที่แล้ว';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return dateString;
    }
  }

  List<TransactionItem> get filteredTransactions {
    List<TransactionItem> filtered = [];

    switch (selectedFilter) {
      case 'ทั้งหมด':
        filtered = allTransactions;
        break;
      case 'รายการเติม':
        filtered = allTransactions
            .where((item) => item.type == 'topup')
            .toList();
        // กรองย่อยตามสถานะ
        if (selectedTopupSubFilter.isNotEmpty) {
          switch (selectedTopupSubFilter) {
            case 'อนุมัติแล้ว':
              filtered = filtered
                  .where((item) => item.status == 'approved')
                  .toList();
              break;
            case 'รออนุมัติ':
              filtered = filtered
                  .where((item) => item.status == 'pending')
                  .toList();
              break;
            case 'ปฏิเสธ':
              filtered = filtered
                  .where((item) => item.status == 'rejected')
                  .toList();
              break;
          }
        }
        break;
      case 'หักค่ารับงาน':
        filtered = allTransactions
            .where((item) => item.type == 'service_fee')
            .toList();
        break;
    }

    return filtered;
  }

  // สร้าง Statistics Widget ตาม Filter ที่เลือก
  Widget _buildStatistics() {
    if (statistics.isEmpty) return Container();

    switch (selectedFilter) {
      case 'ทั้งหมด':
        return _buildAllStatistics();
      case 'หักค่ารับงาน':
        return _buildServiceFeeStatistics();
      case 'รายการเติม':
        return _buildTopupStatistics();
      default:
        return _buildAllStatistics();
    }
  }

  // Statistics สำหรับ "ทั้งหมด"
  Widget _buildAllStatistics() {
    final topupCount = allTransactions.where((t) => t.type == 'topup').length;
    final serviceFeeCount = allTransactions
        .where((t) => t.type == 'service_fee')
        .length;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          // รายการทั้งหมด
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    (allTransactions.length).toString(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'รายการทั้งหมด',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // การเติมทั้งหมด
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    topupCount.toString(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'การเติมทั้งหมด',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // งานที่หักเครดิตทั้งหมด
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    serviceFeeCount.toString(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'งานที่หักเครดิต',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Statistics สำหรับ "หักค่ารับงาน"
  Widget _buildServiceFeeStatistics() {
    final jobCount = statistics['total_jobs_taken'] ?? 0;
    final totalFees = statistics['total_service_fees'] ?? 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          // จำนวนที่รับ
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    jobCount.toString(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'จำนวนที่รับ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // จำนวนเครดิตที่ถูกหัก
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '฿${totalFees.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'เครดิตที่หัก',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Statistics สำหรับ "รายการเติม" (แบบเดิม)
  Widget _buildTopupStatistics() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // บรรทัดแรก: รายการเติมทั้งหมดและยอดเงิน
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        statistics['total_topups']?.toString() ?? '0',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'รายการเติมทั้งหมด',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 50, width: 1, color: Colors.grey[300]),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '฿${double.parse(statistics['total_approved_amount']?.toString() ?? '0').toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'จำนวนเงิน',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // บรรทัดที่สอง: สถานะต่างๆ
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        statistics['approved_topups']?.toString() ?? '0',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'อนุมัติ',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 35, width: 1, color: Colors.grey[300]),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        statistics['pending_topups']?.toString() ?? '0',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'รออนุมัติ',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 35, width: 1, color: Colors.grey[300]),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        statistics['rejected_topups']?.toString() ?? '0',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'ปฏิเสธ',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'ประวัติรายการ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadTransactionHistory,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTransactionHistory,
        child: isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('กำลังโหลดประวัติการเติมเงิน...'),
                  ],
                ),
              )
            : hasError
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'เกิดข้อผิดพลาด',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadTransactionHistory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('ลองใหม่'),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  // Filter Display Bar
                  if (selectedFilter != 'ทั้งหมด' ||
                      selectedTopupSubFilter.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Colors.blue[50],
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_alt,
                            color: Colors.blue[600],
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getFilterDisplayText(),
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (selectedFilter != 'ทั้งหมด' ||
                              selectedTopupSubFilter.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedFilter = 'ทั้งหมด';
                                  selectedTopupSubFilter = '';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'ล้างตัวกรอง',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  // Summary Stats
                  _buildStatistics(),

                  // Transactions List
                  Expanded(
                    child: filteredTransactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'ไม่พบรายการ',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'ยังไม่มีประวัติการเติมเงินในระบบ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredTransactions.length,
                            itemBuilder: (context, index) {
                              final transaction = filteredTransactions[index];
                              return _buildTransactionItem(transaction);
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  String _getFilterDisplayText() {
    if (selectedFilter == 'รายการเติม' && selectedTopupSubFilter.isNotEmpty) {
      return 'กรอง: $selectedFilter - $selectedTopupSubFilter';
    }
    return 'กรอง: $selectedFilter';
  }

  void _showFilterDialog() {
    TransactionFilterDialog.show(
      context,
      selectedFilter: selectedFilter,
      selectedTopupSubFilter: selectedTopupSubFilter,
      onFilterChanged: (filter, subFilter) {
        setState(() {
          selectedFilter = filter;
          selectedTopupSubFilter = subFilter;
        });
      },
    );
  }

  Widget _buildTransactionItem(TransactionItem transaction) {
    Color itemColor = _getTransactionColor(transaction);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: itemColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(transaction.icon, color: itemColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        transaction.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (transaction.type == 'topup' &&
                        transaction.status != 'approved')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(transaction.status),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStatusText(transaction.status),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.date,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (transaction.rejectionReason != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'เหตุผล: ${transaction.rejectionReason}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${transaction.isDebit ? '-' : '+'} ฿ ${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: itemColor,
                ),
              ),
              if (transaction.type == 'topup' &&
                  transaction.status == 'rejected')
                Text(
                  'ไม่สำเร็จ',
                  style: TextStyle(fontSize: 10, color: Colors.red[600]),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTransactionColor(TransactionItem transaction) {
    if (transaction.isWithdraw) {
      return Colors.orange[600]!;
    }
    if (transaction.type == 'topup' && transaction.status == 'rejected') {
      return Colors.red[600]!;
    }
    if (transaction.type == 'topup' && transaction.status == 'pending') {
      return Colors.amber[600]!;
    }
    return transaction.isDebit ? Colors.red[600]! : Colors.green[600]!;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green[600]!;
      case 'pending':
        return Colors.amber[600]!;
      case 'rejected':
        return Colors.red[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
        return 'อนุมัติแล้ว';
      case 'pending':
        return 'รออนุมัติ';
      case 'rejected':
        return 'ปฏิเสธ';
      default:
        return 'สำเร็จ';
    }
  }
}

// Model class สำหรับ Transaction
class TransactionItem {
  final String id;
  final String type; // 'topup', 'service_fee'
  final IconData icon;
  final String title;
  final double amount;
  final String date;
  final bool isDebit;
  final bool isWithdraw;
  final String status; // 'approved', 'pending', 'rejected', 'completed'
  final String? slipUrl;
  final String? rejectionReason;
  final String? approvedAt;

  TransactionItem({
    required this.id,
    required this.type,
    required this.icon,
    required this.title,
    required this.amount,
    required this.date,
    required this.isDebit,
    this.isWithdraw = false,
    required this.status,
    this.slipUrl,
    this.rejectionReason,
    this.approvedAt,
  });
}
