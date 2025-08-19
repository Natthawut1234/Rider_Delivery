import 'package:flutter/material.dart';

class IncomePage extends StatefulWidget {
  const IncomePage({super.key});

  @override
  _IncomePageState createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  String selectedPeriod = "วันนี้";
  DateTime selectedDate = DateTime.now();

  // ตัวอย่างข้อมูล (เพิ่มฟิลด์ date)
  final List<Map<String, dynamic>> _records = [
    {
      'date': DateTime.now(),
      'time': '08:12',
      'title': 'ส่งอาหาร - ร้าน ผญ.โซ้',
      'subtitle': 'ลูกค้า: สมุย',
      'amount': 45.0,
      'type': 'ค่าส่ง',
    },
    {
      'date': DateTime.now(),
      'time': '09:05',
      'title': 'ส่งอาหาร - ร้าน ครัวตามใจ',
      'subtitle': 'ลูกค้า: น้องขวัญ',
      'amount': 60.0,
      'type': 'ค่าส่ง',
    },
    {
      'date': DateTime.now().subtract(Duration(days: 1)),
      'time': '10:30',
      'title': 'โบนัสช่วงเร่งด่วน',
      'subtitle': 'โบนัสเวลา 10:00-11:00',
      'amount': 30.0,
      'type': 'โบนัส',
    },
    {
      'date': DateTime.now().subtract(Duration(days: 3)),
      'time': '12:15',
      'title': 'ทิปจากลูกค้า',
      'subtitle': 'ขอบคุณครับ',
      'amount': 15.0,
      'type': 'ทิป',
    },
  ];

  DateTime _startOfWeek(DateTime d) {
    final wd = d.weekday; // 1 = Mon
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: wd - 1));
  }

  DateTime _endOfWeek(DateTime d) {
    return _startOfWeek(d).add(const Duration(days: 6));
  }

  // records filtered by selectedPeriod + selectedDate
  List<Map<String, dynamic>> get _filteredRecords {
    if (selectedPeriod == 'วันนี้') {
      return _records.where((r) {
        final d = r['date'] as DateTime;
        return d.year == selectedDate.year &&
            d.month == selectedDate.month &&
            d.day == selectedDate.day;
      }).toList();
    } else if (selectedPeriod == 'สัปดาห์นี้') {
      final start = _startOfWeek(selectedDate);
      final end = _endOfWeek(selectedDate);
      return _records.where((r) {
        final d = r['date'] as DateTime;
        return !d.isBefore(start) && !d.isAfter(end);
      }).toList();
    } else {
      // เดือนนี้
      return _records.where((r) {
        final d = r['date'] as DateTime;
        return d.year == selectedDate.year && d.month == selectedDate.month;
      }).toList();
    }
  }

  double get total {
    return _filteredRecords.fold(0.0, (s, e) => s + (e['amount'] as double));
  }

  void _prevPeriod() {
    setState(() {
      if (selectedPeriod == 'วันนี้') {
        selectedDate = selectedDate.subtract(const Duration(days: 1));
      } else if (selectedPeriod == 'สัปดาห์นี้') {
        selectedDate = selectedDate.subtract(const Duration(days: 7));
      } else {
        selectedDate = DateTime(
          selectedDate.year,
          selectedDate.month - 1,
          selectedDate.day,
        );
      }
    });
  }

  void _nextPeriod() {
    setState(() {
      if (selectedPeriod == 'วันนี้') {
        selectedDate = selectedDate.add(const Duration(days: 1));
      } else if (selectedPeriod == 'สัปดาห์นี้') {
        selectedDate = selectedDate.add(const Duration(days: 7));
      } else {
        selectedDate = DateTime(
          selectedDate.year,
          selectedDate.month + 1,
          selectedDate.day,
        );
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  String get _periodLabel {
    if (selectedPeriod == 'วันนี้') {
      return '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
    } else if (selectedPeriod == 'สัปดาห์นี้') {
      final s = _startOfWeek(selectedDate);
      final e = _endOfWeek(selectedDate);
      return '${s.day}/${s.month} - ${e.day}/${e.month}/${e.year}';
    } else {
      return '${selectedDate.month}/${selectedDate.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายได้'),
        backgroundColor: Colors.green,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                selectedPeriod = value;
                selectedDate = DateTime.now();
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: "วันนี้", child: Text("วันนี้")),
              PopupMenuItem(value: "สัปดาห์นี้", child: Text("สัปดาห์นี้")),
              PopupMenuItem(value: "เดือนนี้", child: Text("เดือนนี้")),
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
                  onPressed: _prevPeriod,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      if (selectedPeriod == 'เดือนนี้') {
                        // simple month picker: open date picker and use selected month
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
                  onPressed: _nextPeriod,
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
                        '\$${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$selectedPeriod • ${_filteredRecords.length} รายการ',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
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
            child: Row(
              children: [
                _buildSmallStat(
                  'งาน',
                  '${_filteredRecords.length}',
                  Icons.assignment,
                ),
                const SizedBox(width: 12),
                _buildSmallStat(
                  'โบนัส',
                  '\$${_filteredRecords.where((r) => r['type'] == 'โบนัส').fold(0.0, (s, e) => s + (e['amount'] as double)).toStringAsFixed(2)}',
                  Icons.bolt,
                ),
                const SizedBox(width: 12),
                _buildSmallStat(
                  'ทิป',
                  '\$${_filteredRecords.where((r) => r['type'] == 'ทิป').fold(0.0, (s, e) => s + (e['amount'] as double)).toStringAsFixed(2)}',
                  Icons.card_giftcard,
                ),
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
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _filteredRecords.length,
                  separatorBuilder: (_, __) => const Divider(height: 12),
                  itemBuilder: (context, index) {
                    final r = _filteredRecords[index];
                    final d = r['date'] as DateTime;
                    final dateLabel =
                        '${d.day}/${d.month}/${d.year} ${r['time']}';
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Colors.green[50],
                        child: Icon(
                          r['type'] == 'ค่าส่ง'
                              ? Icons.delivery_dining
                              : (r['type'] == 'โบนัส'
                                    ? Icons.bolt
                                    : Icons.favorite),
                          color: Colors.green,
                        ),
                      ),
                      title: Text(
                        r['title'],
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        dateLabel,
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        '\$${(r['amount'] as double).toStringAsFixed(2)}',
                        style: TextStyle(
                          color: r['type'] == 'โบนัส'
                              ? Colors.orange
                              : Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStat(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 6),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.green, size: 18),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
