import 'package:flutter/material.dart';
import 'credit_dialogs.dart';
import 'transaction_history.dart'; // เพิ่ม import
import '../../../APIs/middleware/topupGP.dart';

class MyCreditPage extends StatefulWidget {
  const MyCreditPage({super.key});

  @override
  State<MyCreditPage> createState() => _MyCreditPageState();
}

class _MyCreditPageState extends State<MyCreditPage> {
  // ดึงยอดเครดิตจาก API getGPBalance
  double currentCredit = 0.0; // เริ่มต้นที่ 0 แล้วค่อยโหลดจาก API
  bool isLoading = true; // แสดง loading ขณะดึงข้อมูล
  bool hasError = false; // ตรวจสอบ error
  String errorMessage = '';
  String lastUpdateTime = ''; // เวลาอัพเดทล่าสุด

  @override
  void initState() {
    super.initState();
    _loadGPBalance(); // โหลดยอดเครดิตเมื่อเปิดหน้า
  }

  // ฟังก์ชันดึงยอดเครดิต GP จาก API
  Future<void> _loadGPBalance() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final topupAPI = TopupGP();
      final result = await topupAPI.getGPBalance();

      if (result['success']) {
        final now = DateTime.now();
        final timeStr =
            '${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

        setState(() {
          // แปลง gp_balance จาก String เป็น double
          final gpBalanceStr = result['data']['gp_balance'].toString();
          currentCredit = double.parse(gpBalanceStr);
          lastUpdateTime = timeStr;
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          errorMessage = result['message'] ?? 'ไม่สามารถดึงยอดเครดิตได้';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'เครดิตของฉัน',
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'ตั้งค่า':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('เปิดหน้าตั้งค่า...'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                  break;
                case 'ช่วยเหลือ':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('เปิดหน้าช่วยเหลือ...'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                  break;
                case 'ออก':
                  Navigator.pop(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'ตั้งค่า',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 18),
                    SizedBox(width: 8),
                    Text('ตั้งค่า'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'ช่วยเหลือ',
                child: Row(
                  children: [
                    Icon(Icons.help, size: 18),
                    SizedBox(width: 8),
                    Text('ช่วยเหลือ'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'ออก',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, size: 18),
                    SizedBox(width: 8),
                    Text('ออก'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadGPBalance,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header (previously non-scrollable content)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Credit Balance Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.green[600]!, Colors.green[400]!],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ยอดเครดิตปัจจุบัน',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            if (isLoading)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white70,
                                  ),
                                ),
                              ),
                            if (!isLoading && !hasError)
                              GestureDetector(
                                onTap: _loadGPBalance,
                                child: Icon(
                                  Icons.refresh,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (hasError)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ไม่สามารถโหลดยอดเครดิตได้',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                errorMessage.isNotEmpty
                                    ? errorMessage
                                    : 'เกิดข้อผิดพลาด',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _loadGPBalance,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(
                                    0.2,
                                  ),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text(
                                  'ลองใหม่',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            '฿ ${currentCredit.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              lastUpdateTime.isNotEmpty
                                  ? 'อัพเดทล่าสุด: $lastUpdateTime'
                                  : 'อัพเดทล่าสุด: วันนี้ 14:30',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                hasError ? 'ไม่พร้อมใช้งาน' : 'ใช้งานได้',
                                style: TextStyle(
                                  color: hasError ? Colors.red : Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick Actions - 3 buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionCard(
                          icon: Icons.add_circle_outline,
                          title: 'เติมเครดิต',
                          color: Colors.green,
                          onTap: () => _showTopUpDialog(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQuickActionCard(
                          icon: Icons.remove_circle_outline,
                          title: 'ถอนเครดิต',
                          color: Colors.orange,
                          onTap: () => _showWithdrawDialog(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQuickActionCard(
                          icon: Icons.history,
                          title: 'ประวัติ',
                          color: Colors.blue,
                          onTap: () => _showTransactionHistory(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'รายการล่าสุด',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      // (optional 'ดูทั้งหมด' button omitted)
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Transactions (scrollable part)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _buildTransactionItem(
                    icon: Icons.delivery_dining,
                    title: 'ค่าขนส่ง - ออเดอร์ #12345',
                    amount: '- ฿ 85.00',
                    date: 'วันนี้ 12:30',
                    isDebit: true,
                  ),
                  _buildTransactionItem(
                    icon: Icons.add_circle,
                    title: 'เติมเครดิตจากบัตรเครดิต',
                    amount: '+ ฿ 500.00',
                    date: 'เมื่อวาน 16:45',
                    isDebit: false,
                    status: 'approved',
                  ),
                  _buildTransactionItem(
                    icon: Icons.add_circle,
                    title: 'เติมเครดิต PromptPay',
                    amount: '+ ฿ 200.00',
                    date: 'เมื่อวาน 14:15',
                    isDebit: false,
                    status: 'pending',
                  ),
                  _buildTransactionItem(
                    icon: Icons.account_balance_wallet,
                    title: 'ถอนเครดิตไปยังบัญชีธนาคาร',
                    amount: '- ฿ 200.00',
                    date: 'เมื่อวาน 15:20',
                    isDebit: true,
                    isWithdraw: true,
                  ),
                  _buildTransactionItem(
                    icon: Icons.delivery_dining,
                    title: 'ค่าขนส่ง - ออเดอร์ #12344',
                    amount: '- ฿ 125.50',
                    date: 'เมื่อวาน 14:20',
                    isDebit: true,
                  ),

                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ข้อมูลเครดิต',
                              style: TextStyle(
                                color: Colors.blue[800],
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• เครดิตจะถูกหักโดยอัตโนมัติเมื่อรับงานขนส่ง\n'
                          '• สามารถเติมเครดิตได้ขั้นต่ำ 100 บาท\n'
                          '• ถอนเครดิตขั้นต่ำ 50 บาท (ค่าธรรมเนียม 10 บาท)\n'
                          '• เครดิตไม่มีวันหมดอายุ',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem({
    required IconData icon,
    required String title,
    required String amount,
    required String date,
    required bool isDebit,
    bool isWithdraw = false,
    String? status,
  }) {
    Color itemColor;
    if (isWithdraw) {
      itemColor = Colors.orange[600]!;
    } else {
      itemColor = isDebit ? Colors.red[600]! : Colors.green[600]!;
    }

    // สำหรับรายการเติมเงินที่รออนุมัติ
    if (status == 'pending') {
      itemColor = Colors.amber[600]!;
    } else if (status == 'rejected') {
      itemColor = Colors.red[600]!;
    }

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
            child: Icon(icon, color: itemColor, size: 20),
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
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (status != null &&
                        status != 'approved' &&
                        status != 'completed')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: itemColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status == 'pending' ? 'รออนุมัติ' : 'ปฏิเสธ',
                          style: TextStyle(
                            fontSize: 10,
                            color: itemColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: itemColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showTopUpDialog() {
    CreditDialogs.showTopUpDialog(context, (amount) {
      // ไม่ต้องเพิ่มเครดิตทันที เพราะต้องรอการอนุมัติจากแอดมิน
      // แต่อาจจะเพิ่ม transaction รายการ "รอการอนุมัติ" ลงในรายการ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ส่งคำขอเติมเครดิต ฿ ${amount.toStringAsFixed(2)} แล้ว\nรอการอนุมัติจากแอดมิน',
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 3),
        ),
      );

      // อัพเดทยอดเครดิต (รีเฟรชจาก API)
      Future.delayed(const Duration(seconds: 1), () {
        _loadGPBalance();
      });
    });
  }

  void _showWithdrawDialog() {
    CreditDialogs.showWithdrawDialog(context, currentCredit, (amount) {
      setState(() {
        currentCredit -= amount;
      });
    });
  }

  void _showTransactionHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TransactionHistoryPage()),
    );
  }
}
