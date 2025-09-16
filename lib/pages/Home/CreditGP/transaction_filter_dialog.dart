import 'package:flutter/material.dart';

class TransactionFilterDialog {
  static void show(
    BuildContext context, {
    required String selectedFilter,
    required String selectedTopupSubFilter,
    required Function(String filter, String subFilter) onFilterChanged,
  }) {
    String tempSelectedFilter = selectedFilter;
    String tempSelectedTopupSubFilter = selectedTopupSubFilter;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.filter_list, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  const Text(
                    'เลือกประเภทรายการ',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                  ),
                ],
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ประเภทหลัก',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Main Filter Options
                    _buildFilterOption(
                      context: context,
                      title: 'ทั้งหมด',
                      subtitle: 'แสดงรายการทุกประเภท',
                      icon: Icons.list_alt,
                      isSelected: tempSelectedFilter == 'ทั้งหมด',
                      onTap: () {
                        setState(() {
                          tempSelectedFilter = 'ทั้งหมด';
                          tempSelectedTopupSubFilter = '';
                        });
                      },
                    ),

                    _buildFilterOption(
                      context: context,
                      title: 'ค่าขนส่ง',
                      subtitle: 'รายการหักเครดิตสำหรับออเดอร์',
                      icon: Icons.delivery_dining,
                      isSelected: tempSelectedFilter == 'ค่าขนส่ง',
                      onTap: () {
                        setState(() {
                          tempSelectedFilter = 'ค่าขนส่ง';
                          tempSelectedTopupSubFilter = '';
                        });
                      },
                    ),

                    _buildFilterOption(
                      context: context,
                      title: 'รายการเติม',
                      subtitle: 'รายการเติมเครดิตทั้งหมด',
                      icon: Icons.add_circle,
                      isSelected: tempSelectedFilter == 'รายการเติม',
                      onTap: () {
                        setState(() {
                          tempSelectedFilter = 'รายการเติม';
                          // Keep existing sub-filter if switching to topup
                        });
                      },
                      hasSubOptions: true,
                    ),

                    // Sub-filter options for Topup (แสดงเมื่อเลือก "รายการเติม")
                    if (tempSelectedFilter == 'รายการเติม') ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: Colors.blue[600],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'สถานะการเติม',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            _buildSubFilterOption(
                              title: 'ทั้งหมด',
                              subtitle: 'รายการเติมทุกสถานะ',
                              icon: Icons.all_inclusive,
                              iconColor: Colors.blue[600]!,
                              isSelected: tempSelectedTopupSubFilter.isEmpty,
                              onTap: () {
                                setState(() {
                                  tempSelectedTopupSubFilter = '';
                                });
                              },
                            ),

                            _buildSubFilterOption(
                              title: 'อนุมัติแล้ว',
                              subtitle: 'รายการที่ผ่านการอนุมัติ',
                              icon: Icons.check_circle,
                              iconColor: Colors.green[600]!,
                              isSelected:
                                  tempSelectedTopupSubFilter == 'อนุมัติแล้ว',
                              onTap: () {
                                setState(() {
                                  tempSelectedTopupSubFilter = 'อนุมัติแล้ว';
                                });
                              },
                            ),

                            _buildSubFilterOption(
                              title: 'รออนุมัติ',
                              subtitle: 'รายการที่รอการตรวจสอบ',
                              icon: Icons.pending,
                              iconColor: Colors.amber[600]!,
                              isSelected:
                                  tempSelectedTopupSubFilter == 'รออนุมัติ',
                              onTap: () {
                                setState(() {
                                  tempSelectedTopupSubFilter = 'รออนุมัติ';
                                });
                              },
                            ),

                            _buildSubFilterOption(
                              title: 'ปฏิเสธ',
                              subtitle: 'รายการที่ไม่ผ่านการอนุมัติ',
                              icon: Icons.cancel,
                              iconColor: Colors.red[600]!,
                              isSelected:
                                  tempSelectedTopupSubFilter == 'ปฏิเสธ',
                              onTap: () {
                                setState(() {
                                  tempSelectedTopupSubFilter = 'ปฏิเสธ';
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    'ยกเลิก',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[600]!, Colors.blue[400]!],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onFilterChanged(
                        tempSelectedFilter,
                        tempSelectedTopupSubFilter,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'ตกลง',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Widget _buildFilterOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    bool hasSubOptions = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.blue[300]! : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected ? Colors.blue[50] : Colors.white,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[100] : Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? Colors.blue[600] : Colors.grey[600],
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.blue[700] : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.blue[600] : Colors.grey[600],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasSubOptions)
              Icon(
                Icons.keyboard_arrow_down,
                color: isSelected ? Colors.blue[600] : Colors.grey[400],
                size: 20,
              ),
            const SizedBox(width: 4),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? Colors.blue[600] : Colors.grey[400],
              size: 20,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  static Widget _buildSubFilterOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? Colors.white : Colors.transparent,
        border: isSelected
            ? Border.all(color: Colors.blue[300]!, width: 1.5)
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.blue[700] : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: isSelected ? Colors.blue[600] : Colors.grey[600],
          ),
        ),
        trailing: Icon(
          isSelected ? Icons.check_circle : Icons.circle_outlined,
          color: isSelected ? Colors.blue[600] : Colors.grey[400],
          size: 18,
        ),
        onTap: onTap,
      ),
    );
  }
}
