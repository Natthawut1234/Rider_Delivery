import 'package:flutter/material.dart';
import 'dart:math';

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  DateTime selectedDate = DateTime.now();
  String period = 'วันนี้'; // 'วันนี้' | 'สัปดาห์นี้' | 'เดือนนี้'

  // ตัวอย่างข้อมูลย้อนหลัง (มีวันที่/เวลา/ร้านา/ลูกค้า/ยอด/สถานะ)
  final List<Map<String, dynamic>> _jobs = List.generate(20, (i) {
    final rnd = Random();
    final date = DateTime.now().subtract(Duration(days: rnd.nextInt(30)));
    return {
      'id': i,
      'date': date,
      'time':
          '${9 + rnd.nextInt(10)}:${(rnd.nextInt(59)).toString().padLeft(2, '0')}',
      'shop': 'ร้าน ตัวอย่าง ${rnd.nextInt(6) + 1}',
      'customer': 'ลูกค้า ${['สมุย', 'น้องขวัญ', 'มะลิ'][rnd.nextInt(3)]}',
      'amount': (20 + rnd.nextInt(50)).toDouble(),
      'distance': (1 + rnd.nextDouble() * 8).toStringAsFixed(1),
      'duration': 5 + rnd.nextInt(40),
      'status': rnd.nextBool() ? 'สำเร็จ' : 'ยกเลิก',
    };
  });

  DateTime _startOfWeek(DateTime d) {
    final wd = d.weekday; // 1 = Mon
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: wd - 1));
  }

  DateTime _endOfWeek(DateTime d) {
    return _startOfWeek(d).add(const Duration(days: 6));
  }

  // records filtered by selected period + date
  List<Map<String, dynamic>> get _filteredJobs {
    if (period == 'วันนี้') {
      return _jobs.where((j) {
          final d = j['date'] as DateTime;
          return d.year == selectedDate.year &&
              d.month == selectedDate.month &&
              d.day == selectedDate.day;
        }).toList()
        ..sort((a, b) => (b['time'] as String).compareTo(a['time'] as String));
    } else if (period == 'สัปดาห์นี้') {
      final s = _startOfWeek(selectedDate);
      final e = _endOfWeek(selectedDate);
      return _jobs.where((j) {
        final d = j['date'] as DateTime;
        return !d.isBefore(s) && !d.isAfter(e);
      }).toList()..sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
      );
    } else {
      // เดือนนี้
      return _jobs.where((j) {
        final d = j['date'] as DateTime;
        return d.year == selectedDate.year && d.month == selectedDate.month;
      }).toList()..sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
      );
    }
  }

  double get totalEarn {
    return _filteredJobs.fold(
      0.0,
      (s, e) => s + (e['status'] == 'สำเร็จ' ? (e['amount'] as double) : 0.0),
    );
  }

  int get jobCount => _filteredJobs.length;

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
      } else {
        // เดือนก่อน
        selectedDate = DateTime(selectedDate.year, selectedDate.month - 1, 1);
      }
    });
  }

  void _nextPeriod() {
    setState(() {
      if (period == 'วันนี้') {
        selectedDate = selectedDate.add(const Duration(days: 1));
      } else if (period == 'สัปดาห์นี้') {
        selectedDate = selectedDate.add(const Duration(days: 7));
      } else {
        // เดือนถัดไป
        selectedDate = DateTime(selectedDate.year, selectedDate.month + 1, 1);
      }
    });
  }

  String get _periodLabel {
    if (period == 'วันนี้') {
      return '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
    } else if (period == 'สัปดาห์นี้') {
      final s = _startOfWeek(selectedDate);
      final e = _endOfWeek(selectedDate);
      return '${s.day}/${s.month} - ${e.day}/${e.month}/${e.year}';
    } else {
      return '${selectedDate.month}/${selectedDate.year}';
    }
  }

  void _showJobDetail(Map<String, dynamic> job) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${job['shop']} → ${job['customer']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    job['status'],
                    style: TextStyle(
                      color: job['status'] == 'สำเร็จ'
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                dense: true,
                leading: const Icon(Icons.access_time),
                title: Text(
                  '${job['date'].day}/${job['date'].month}/${job['date'].year} ${job['time']}',
                ),
                subtitle: const Text('เวลาเริ่มงาน'),
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.location_on),
                title: Text('${job['distance']} กม. • ${job['duration']} นาที'),
                subtitle: const Text('ระยะทาง/เวลา'),
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.monetization_on),
                title: Text(
                  '\$${(job['amount'] as double).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('รายได้จากงาน'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: เชื่อมไปดูเส้นทางจริง
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('ดูเส้นทาง'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: ดูใบส่ง/รายละเอียดเพิ่มเติม
                      },
                      icon: const Icon(Icons.info_outline),
                      label: const Text('รายละเอียด'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryCard() {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('รายได้รวม', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(
                    '\$${totalEarn.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$jobCount งาน • $period',
                    style: const TextStyle(color: Colors.grey),
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
                Icons.assignment_turned_in,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallStat(String title, String value, IconData icon) {
    final isCancel = title == 'ยกเลิก';
    return Expanded(
      // ยกเลิก เป็นสีแดง
      child: Container(
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
                color: isCancel ? Colors.red[50] : Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isCancel ? Colors.red : Colors.green,
                size: 18,
              ),
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCancel ? Colors.red : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'วันนี้', child: Text('วันนี้')),
              PopupMenuItem(value: 'สัปดาห์นี้', child: Text('สัปดาห์นี้')),
              PopupMenuItem(value: 'เดือนนี้', child: Text('เดือนนี้')),
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
                  onPressed: _prevPeriod,
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
                  onPressed: _nextPeriod,
                ),
              ],
            ),
          ),

          _summaryCard(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _smallStat('งาน', '$jobCount', Icons.list_alt),
                const SizedBox(width: 12),
                _smallStat(
                  'สำเร็จ',
                  '${_filteredJobs.where((j) => j['status'] == 'สำเร็จ').length}',
                  Icons.check_circle,
                ),
                // ยกเลิก
                const SizedBox(width: 12),
                _smallStat(
                  'ยกเลิก',
                  '${_filteredJobs.where((j) => j['status'] == 'ยกเลิก').length}',
                  Icons.cancel,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: _filteredJobs.isEmpty
                  ? Center(
                      child: Text(
                        'ไม่มีงานในช่วง ${_periodLabel}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(8),
                        itemCount: _filteredJobs.length,
                        separatorBuilder: (_, __) => const Divider(height: 8),
                        itemBuilder: (context, index) {
                          final job = _filteredJobs[index];
                          return ListTile(
                            onTap: () => _showJobDetail(job),
                            leading: CircleAvatar(
                              backgroundColor: Colors.green[50],
                              child: const Icon(
                                Icons.directions_bike,
                                color: Colors.green,
                              ),
                            ),
                            title: Text(
                              job['shop'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${job['date'].day}/${job['date'].month}/${job['date'].year} ${job['time']} • ${job['customer']}',
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${(job['amount'] as double).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: job['status'] == 'สำเร็จ'
                                        ? Colors.blue
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  job['status'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
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
}
