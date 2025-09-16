import 'package:flutter/material.dart';
import 'transaction_filter_dialog.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  String selectedFilter = 'ทั้งหมด';
  String selectedTopupSubFilter = ''; // สำหรับกรองย่อยในการเติมเงิน

  // ข้อมูลตัวอย่างรายการทั้งหมด
  List<TransactionItem> allTransactions = [
    TransactionItem(
      id: '12348',
      type: 'topup',
      icon: Icons.add_circle,
      title: 'เติมเครดิต PromptPay',
      amount: 500.00,
      date: 'วันนี้ 16:30',
      isDebit: false,
      status: 'approved',
    ),
    TransactionItem(
      id: '12347',
      type: 'topup',
      icon: Icons.add_circle,
      title: 'เติมเครดิต PromptPay',
      amount: 200.00,
      date: 'วันนี้ 14:15',
      isDebit: false,
      status: 'pending',
    ),
    TransactionItem(
      id: '12346',
      type: 'order',
      icon: Icons.delivery_dining,
      title: 'ค่าขนส่ง - ออเดอร์ #12346',
      amount: 95.00,
      date: 'วันนี้ 13:20',
      isDebit: true,
      status: 'completed',
    ),
    TransactionItem(
      id: '12345',
      type: 'order',
      icon: Icons.delivery_dining,
      title: 'ค่าขนส่ง - ออเดอร์ #12345',
      amount: 85.00,
      date: 'วันนี้ 12:30',
      isDebit: true,
      status: 'completed',
    ),
    TransactionItem(
      id: '12344',
      type: 'topup',
      icon: Icons.add_circle,
      title: 'เติมเครดิต PromptPay',
      amount: 1000.00,
      date: 'เมื่อวาน 18:45',
      isDebit: false,
      status: 'rejected',
    ),
    TransactionItem(
      id: '12343',
      type: 'withdraw',
      icon: Icons.account_balance_wallet,
      title: 'ถอนเครดิตไปยังบัญชีธนาคาร',
      amount: 200.00,
      date: 'เมื่อวาน 15:20',
      isDebit: true,
      isWithdraw: true,
      status: 'completed',
    ),
    TransactionItem(
      id: '12342',
      type: 'order',
      icon: Icons.delivery_dining,
      title: 'ค่าขนส่ง - ออเดอร์ #12342',
      amount: 125.50,
      date: 'เมื่อวาน 14:20',
      isDebit: true,
      status: 'completed',
    ),
    TransactionItem(
      id: '12341',
      type: 'topup',
      icon: Icons.add_circle,
      title: 'เติมเครดิต PromptPay',
      amount: 300.00,
      date: '2 วันที่แล้ว',
      isDebit: false,
      status: 'approved',
    ),
    TransactionItem(
      id: '12340',
      type: 'bonus',
      icon: Icons.card_giftcard,
      title: 'โบนัสสำหรับ Rider ใหม่',
      amount: 100.00,
      date: '2 วันที่แล้ว',
      isDebit: false,
      status: 'completed',
    ),
  ];

  List<TransactionItem> get filteredTransactions {
    List<TransactionItem> filtered = [];

    switch (selectedFilter) {
      case 'ทั้งหมด':
        filtered = allTransactions;
        break;
      case 'ค่าขนส่ง':
        filtered = allTransactions
            .where((item) => item.type == 'order')
            .toList();
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
    }

    return filtered;
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
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Display Bar
          if (selectedFilter != 'ทั้งหมด' || selectedTopupSubFilter.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Icon(Icons.filter_alt, color: Colors.blue[600], size: 18),
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
          Container(
            margin: const EdgeInsets.all(16),
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
                        '${filteredTransactions.length}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Text(
                        'รายการทั้งหมด',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(height: 30, width: 1, color: Colors.grey[300]),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${filteredTransactions.where((t) => !t.isDebit).length}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Text(
                        'รายการรับ',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(height: 30, width: 1, color: Colors.grey[300]),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${filteredTransactions.where((t) => t.isDebit).length}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const Text(
                        'รายการจ่าย',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

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
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ลองเปลี่ยนตัวกรองหรือเพิ่มรายการใหม่',
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
                        transaction.status != 'completed')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            transaction.status,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStatusText(transaction.status),
                          style: TextStyle(
                            fontSize: 10,
                            color: _getStatusColor(transaction.status),
                            fontWeight: FontWeight.w500,
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
  final String type; // 'topup', 'order', 'withdraw', 'bonus'
  final IconData icon;
  final String title;
  final double amount;
  final String date;
  final bool isDebit;
  final bool isWithdraw;
  final String status; // 'approved', 'pending', 'rejected', 'completed'

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
  });
}
