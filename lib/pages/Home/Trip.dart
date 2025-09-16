import 'package:flutter/material.dart';
import 'dart:math';

class TripPage extends StatefulWidget {
  const TripPage({super.key});

  @override
  State<TripPage> createState() => _TripPageState();
}

class _TripPageState extends State<TripPage> {
  DateTime selectedDate = DateTime.now();
  String period = 'วันนี้'; // 'วันนี้' | 'สัปดาห์นี้' | 'เดือนนี้'

  final List<Map<String, dynamic>> _sampleTrips = List.generate(30, (i) {
    final rnd = Random();
    final date = DateTime.now().subtract(Duration(days: rnd.nextInt(20)));
    return {
      'id': i,
      'title': i.isEven
          ? "ร้านอาหาร ${i + 1} → ลูกค้า"
          : "ร้าน ${i + 1} → จุดส่ง",
      'time':
          '${8 + rnd.nextInt(10)}:${(rnd.nextInt(59)).toString().padLeft(2, '0')}',
      'date': date,
      'amount': (10 + rnd.nextInt(45)).toDouble(),
      'distanceKm': (1 + rnd.nextDouble() * 9).toStringAsFixed(1),
      'durationMin': 5 + rnd.nextInt(40),
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

  List<Map<String, dynamic>> get _filteredTrips {
    if (period == 'วันนี้') {
      return _sampleTrips.where((t) {
          final d = t['date'] as DateTime;
          return d.year == selectedDate.year &&
              d.month == selectedDate.month &&
              d.day == selectedDate.day;
        }).toList()
        ..sort((a, b) => (b['time'] as String).compareTo(a['time'] as String));
    } else if (period == 'สัปดาห์นี้') {
      final s = _startOfWeek(selectedDate);
      final e = _endOfWeek(selectedDate);
      return _sampleTrips.where((t) {
        final d = t['date'] as DateTime;
        return !d.isBefore(s) && !d.isAfter(e);
      }).toList()..sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
      );
    } else {
      // เดือนนี้
      return _sampleTrips.where((t) {
        final d = t['date'] as DateTime;
        return d.year == selectedDate.year && d.month == selectedDate.month;
      }).toList()..sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
      );
    }
  }

  double get totalEarn {
    return _filteredTrips.fold(0.0, (s, e) => s + (e['amount'] as double));
  }

  int get tripCount => _filteredTrips.length;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

  void _showTripDetail(Map<String, dynamic> trip) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (c) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_bike, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trip['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    '\$${(trip['amount'] as double).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('เวลา: ${trip['time']}'),
              const SizedBox(height: 6),
              Text(
                'ระยะทาง: ${trip['distanceKm']} กม. • เวลาที่ใช้: ${trip['durationMin']} นาที',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('ดูเส้นทาง'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('รายละเอียด'),
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

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('รวม', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Text(
                  '\$${totalEarn.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$tripCount ทริป • $period',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripTile(Map<String, dynamic> trip) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: Colors.green[50],
        child: const Icon(Icons.directions_bike, color: Colors.green),
      ),
      title: Text(
        trip['title'],
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text('${trip['time']} • ${trip['distanceKm']} กม.'),
      trailing: Text(
        '\$${(trip['amount'] as double).toStringAsFixed(2)}',
        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
      ),
      onTap: () => _showTripDetail(trip),
    );
  }

  Widget _smallStat(String title, String value, IconData icon) {
    return Expanded(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ทริป'),
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
          // date selector row (prev / label / next)
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
                        if (picked != null) {
                          setState(
                            () => selectedDate = DateTime(
                              picked.year,
                              picked.month,
                              1,
                            ),
                          );
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

          _buildSummaryCard(),

          // small stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _smallStat('ทริป', '$tripCount', Icons.list_alt),
                const SizedBox(width: 12),
                _smallStat(
                  'โบนัส',
                  '\$${_filteredTrips.fold(0.0, (s, e) => s + ((e['amount'] as double) > 40 ? (e['amount'] as double) * 0.1 : 0.0)).toStringAsFixed(0)}',
                  Icons.bolt,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: _filteredTrips.isEmpty
                  ? Center(
                      child: Text(
                        'ไม่มีทริปในช่วง ${_periodLabel}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(8),
                        itemCount: _filteredTrips.length,
                        separatorBuilder: (_, __) => const Divider(height: 8),
                        itemBuilder: (context, index) =>
                            _buildTripTile(_filteredTrips[index]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
