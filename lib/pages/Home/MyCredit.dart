import 'package:flutter/material.dart';

class MyCreditPage extends StatelessWidget {
  const MyCreditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'เครดิตของฉัน',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green[600],
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Non-scrollable content
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
                      const Text(
                        'ยอดเครดิตปัจจุบัน',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '฿ 1,250.00',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'อัพเดทล่าสุด: วันนี้ 14:30',
                            style: TextStyle(
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
                            child: const Text(
                              'ใช้งานได้',
                              style: TextStyle(
                                color: Colors.white,
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
                        onTap: () => _showTopUpDialog(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.remove_circle_outline,
                        title: 'ถอนเครดิต',
                        color: Colors.orange,
                        onTap: () => _showWithdrawDialog(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.history,
                        title: 'ประวัติ',
                        color: Colors.blue,
                        onTap: () => _showTransactionHistory(context),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Section Header
                const Text(
                  'รายการล่าสุด',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // Scrollable Transactions List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                _buildTransactionItem(
                  icon: Icons.card_giftcard,
                  title: 'โบนัสสำหรับ Rider ใหม่',
                  amount: '+ ฿ 100.00',
                  date: '2 วันที่แล้ว',
                  isDebit: false,
                ),
                _buildTransactionItem(
                  icon: Icons.delivery_dining,
                  title: 'ค่าขนส่ง - ออเดอร์ #12343',
                  amount: '- ฿ 95.00',
                  date: '3 วันที่แล้ว',
                  isDebit: true,
                ),
                _buildTransactionItem(
                  icon: Icons.add_circle,
                  title: 'เติมเครดิตจาก PromptPay',
                  amount: '+ ฿ 300.00',
                  date: '3 วันที่แล้ว',
                  isDebit: false,
                ),
                _buildTransactionItem(
                  icon: Icons.account_balance_wallet,
                  title: 'ถอนเครดิตไปยัง PromptPay',
                  amount: '- ฿ 150.00',
                  date: '4 วันที่แล้ว',
                  isDebit: true,
                  isWithdraw: true,
                ),
                _buildTransactionItem(
                  icon: Icons.delivery_dining,
                  title: 'ค่าขนส่ง - ออเดอร์ #12342',
                  amount: '- ฿ 110.50',
                  date: '4 วันที่แล้ว',
                  isDebit: true,
                ),
                _buildTransactionItem(
                  icon: Icons.card_giftcard,
                  title: 'โบนัสทำงานครบ 10 ออเดอร์',
                  amount: '+ ฿ 50.00',
                  date: '5 วันที่แล้ว',
                  isDebit: false,
                ),

                // Credit Info Card at bottom
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
  }) {
    Color itemColor;
    if (isWithdraw) {
      itemColor = Colors.orange[600]!;
    } else {
      itemColor = isDebit ? Colors.red[600]! : Colors.green[600]!;
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
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

  void _showTopUpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'เติมเครดิต',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('เลือกจำนวนเงินที่ต้องการเติม'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildAmountChip('100'),
                  _buildAmountChip('300'),
                  _buildAmountChip('500'),
                  _buildAmountChip('1,000'),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'วิธีการชำระเงิน',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              _buildPaymentMethodTile('บัตรเครดิต/เดบิต', Icons.credit_card),
              _buildPaymentMethodTile('PromptPay', Icons.qr_code),
              _buildPaymentMethodTile('โอนผ่านธนาคาร', Icons.account_balance),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กำลังดำเนินการเติมเครดิต...'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('ยืนยัน'),
            ),
          ],
        );
      },
    );
  }

  void _showWithdrawDialog(BuildContext context) {
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.remove_circle_outline, color: Colors.orange[600]),
              const SizedBox(width: 8),
              const Text(
                'ถอนเครดิต',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ยอดเครดิตปัจจุบัน: ฿ 1,250.00'),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'จำนวนเงินที่ต้องการถอน',
                  hintText: 'ขั้นต่ำ 50 บาท',
                  prefixText: '฿ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ค่าธรรมเนียมการถอน',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.orange[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• ค่าธรรมเนียม: 10 บาทต่อครั้ง\n'
                      '• ระยะเวลาโอนเงิน: 1-2 วันทำการ',
                      style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'ปลายทางการโอน',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              _buildPaymentMethodTile(
                'บัญชีธนาคารที่ลงทะเบียน',
                Icons.account_balance,
              ),
              _buildPaymentMethodTile('PromptPay', Icons.qr_code),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กำลังดำเนินการถอนเครดิต...'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('ยืนยันการถอน'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAmountChip(String amount) {
    return ActionChip(
      label: Text('฿ $amount'),
      onPressed: () {},
      backgroundColor: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildPaymentMethodTile(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        leading: Icon(icon, size: 20),
        title: Text(title, style: const TextStyle(fontSize: 14)),
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey[300]!),
        ),
        onTap: () {
          // Handle payment method selection
        },
      ),
    );
  }

  void _showTransactionHistory(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('เปิดหน้าประวัติรายการ...'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
