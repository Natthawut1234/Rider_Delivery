// คงไม่ได้ใช้แล้ว

// // File: lib/pages/Profile.dart
// import 'package:flutter/material.dart';
// import 'package:awesome_dialog/awesome_dialog.dart';
// import 'package:rider_delivery/APIs/middleware/AuthGuard.dart';

// class ProfilePage extends StatefulWidget {
//   const ProfilePage({Key? key}) : super(key: key);

//   @override
//   State<ProfilePage> createState() => _ProfilePageState();
// }

// class _ProfilePageState extends State<ProfilePage> {
//   bool available = true;

//   // ตัวอย่างข้อมูล (จาก API จริงให้แทนที่ด้วยข้อมูลจริง)
//   final String name = 'สมชาย ขับดี';
//   final String phone = '081-234-5678';
//   final String email = 'rider@example.com';
//   final String vehicle = 'มอเตอร์ไซค์ Honda Click 150';
//   final String plate = '1กข-1234';
//   final String license = 'ใบขับขี่: หมายเลข ABC123456';
//   final double rating = 4.8;
//   final int completed = 1250;
//   final double earnings = 45230.50;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('โปรไฟล์ ไรเดอร์'),
//         backgroundColor: Colors.green[600], // เปลี่ยนสี AppBar
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.settings),
//             onPressed: () {
//               // ไปยังหน้าตั้งค่า
//             },
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         child: Column(
//           children: [
//             _buildHeaderCard(),
//             const SizedBox(height: 16),
//             _buildStatsCard(),
//             const SizedBox(height: 16),
//             _buildInfoList(),
//             const SizedBox(height: 16),
//             _buildActionButtons(),
//             const SizedBox(height: 24),
//             _buildDangerActions(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHeaderCard() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const CircleAvatar(
//               radius: 40,
//               backgroundColor: Colors.blueGrey,
//               child: Icon(Icons.person, size: 48, color: Colors.white),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     name,
//                     style: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Row(
//                     children: [
//                       Icon(Icons.star, color: Colors.amber[700], size: 20),
//                       const SizedBox(width: 6),
//                       Text('$rating', style: const TextStyle(fontSize: 16)),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     vehicle,
//                     style: TextStyle(fontSize: 13, color: Colors.grey[500]),
//                   ),
//                 ],
//               ),
//             ),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 ElevatedButton(
//                   onPressed: () {
//                     // แก้ไขโปรไฟล์
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blueGrey,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                   ),
//                   child: const Text(
//                     'แก้ไข',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Chip(
//                   label: Text(
//                     available ? 'พร้อมรับงาน' : 'ไม่พร้อมรับงาน',
//                     style: TextStyle(
//                       color: available ? Colors.white : Colors.black,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   backgroundColor: available
//                       ? Colors.green[600]
//                       : Colors.grey[400],
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 10,
//                     vertical: 4,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatsCard() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: [
//             _statItem(
//               'รายได้',
//               '฿${earnings.toStringAsFixed(2)}',
//               Icons.account_balance_wallet,
//               Colors.green,
//             ),
//             _statItem(
//               'งานสำเร็จ',
//               '$completed',
//               Icons.check_circle,
//               Colors.blue,
//             ),
//             _statItem('เรตติ้ง', rating.toString(), Icons.star, Colors.amber),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _statItem(String label, String value, IconData icon, Color color) {
//     return Column(
//       children: [
//         Icon(icon, color: color, size: 30),
//         const SizedBox(height: 8),
//         Text(
//           value,
//           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//         ),
//         const SizedBox(height: 4),
//         Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
//       ],
//     );
//   }

//   Widget _buildInfoList() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       elevation: 4,
//       child: Column(
//         children: [
//           ListTile(
//             leading: const Icon(Icons.phone, color: Colors.blueGrey),
//             title: const Text('โทรศัพท์'),
//             subtitle: Text(phone),
//             trailing: const Icon(Icons.edit, color: Colors.blueGrey),
//             onTap: () {},
//           ),
//           const Divider(height: 1),
//           ListTile(
//             leading: const Icon(Icons.email, color: Colors.blueGrey),
//             title: const Text('อีเมล'),
//             subtitle: Text(email),
//             trailing: const Icon(Icons.edit, color: Colors.blueGrey),
//             onTap: () {},
//           ),
//           const Divider(height: 1),
//           ListTile(
//             leading: const Icon(
//               Icons.confirmation_number,
//               color: Colors.blueGrey,
//             ),
//             title: const Text('ใบอนุญาต/ทะเบียน'),
//             subtitle: Text('$license\n$plate'),
//             isThreeLine: true,
//             trailing: const Icon(Icons.file_present, color: Colors.blueGrey),
//             onTap: () {},
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButtons() {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       elevation: 4,
//       child: Column(
//         children: [
//           SwitchListTile(
//             title: const Text('สถานะพร้อมรับงาน'),
//             subtitle: const Text('สลับเพื่อรับงานส่งอาหาร'),
//             value: available,
//             onChanged: (v) {
//               setState(() {
//                 available = v;
//               });
//             },
//             secondary: Icon(
//               Icons.delivery_dining,
//               color: available ? Colors.green : Colors.grey,
//             ),
//           ),
//           _buildListTileMenuItem(
//             Icons.receipt_long,
//             'เอกสารและการยืนยันตัวตน',
//             onTap: () {},
//           ),
//           _buildListTileMenuItem(
//             Icons.account_balance,
//             'บัญชีรับเงิน',
//             subtitle: 'เชื่อมต่อ/แก้ไขบัญชีธนาคาร',
//             onTap: () {},
//           ),
//           _buildListTileMenuItem(Icons.lock, 'เปลี่ยนรหัสผ่าน', onTap: () {}),
//           _buildListTileMenuItem(
//             Icons.headset_mic,
//             'ติดต่อสนับสนุน',
//             onTap: () {},
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildListTileMenuItem(
//     IconData icon,
//     String title, {
//     String? subtitle,
//     VoidCallback? onTap,
//   }) {
//     return ListTile(
//       leading: Icon(icon, color: Colors.blueGrey),
//       title: Text(title),
//       subtitle: subtitle != null ? Text(subtitle) : null,
//       trailing: const Icon(Icons.chevron_right),
//       onTap: onTap,
//     );
//   }

//   Widget _buildDangerActions() {
//     return Column(
//       children: [
//         SizedBox(
//           width: double.infinity,
//           child: ElevatedButton.icon(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red[600],
//               padding: const EdgeInsets.symmetric(vertical: 12),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(30),
//               ),
//             ),
//             onPressed: () async {
//               // ออกจากระบบ
//               AwesomeDialog(
//                 context: context,
//                 dialogType: DialogType.question,
//                 animType: AnimType.scale,
//                 title: 'ออกจากระบบ',
//                 desc: 'คุณต้องการออกจากระบบใช่หรือไม่?',
//                 btnOkOnPress: () async {
//                   // เรียก logout function
//                   await AuthGuard.logout();

//                   // นำทางไปหน้า welcome และล้าง navigation stack ทั้งหมด
//                   if (mounted) {
//                     Navigator.of(context).pushNamedAndRemoveUntil(
//                       '/wellcome',
//                       (route) => false, // ลบ navigation stack ทั้งหมด
//                     );
//                   }
//                 },
//                 btnCancelOnPress: () {},
//                 btnOkText: 'ออกจากระบบ',
//                 btnCancelText: 'ยกเลิก',
//                 btnOkColor: Colors.red[600],
//               ).show();
//             },
//             icon: const Icon(Icons.logout, color: Colors.white),
//             label: const Text(
//               'ออกจากระบบ',
//               style: TextStyle(color: Colors.white, fontSize: 16),
//             ),
//           ),
//         ),
//         const SizedBox(height: 16),
//         TextButton(
//           onPressed: () {
//             // ลบบัญชี (เตือนยืนยันก่อน)
//           },
//           child: const Text(
//             'ลบบัญชี',
//             style: TextStyle(color: Colors.red, fontSize: 14),
//           ),
//         ),
//       ],
//     );
//   }
// }
