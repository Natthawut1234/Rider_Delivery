import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:rider_delivery/services/RiderStatusService.dart';
import 'package:rider_delivery/APIs/middleware/authService.dart';

class RiderIdentityPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const RiderIdentityPage({super.key, this.userData});

  @override
  State<RiderIdentityPage> createState() => _RiderIdentityPageState();
}

class _RiderIdentityPageState extends State<RiderIdentityPage>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;
  late AnimationController _bounceController;
  late Animation<double> _fadeAnimation;
  // late Animation<double> _bounceAnimation;

  File? _selfieWithId;
  File? _idCard;
  File? _driverLicense;
  File? _vehiclePhoto;
  File? _vehicleRegistration;

  // Text controllers for form data
  final TextEditingController _idCardNumberController = TextEditingController();
  final TextEditingController _driverLicenseNumberController =
      TextEditingController();

  final TextEditingController _vehicleBrandController = TextEditingController();
  final TextEditingController _vehicleColorController = TextEditingController();
  final TextEditingController _vehiclePlateController = TextEditingController();
  final TextEditingController _vehicleProvinceController =
      TextEditingController();

  String? _selectedVehicleType;
  final List<String> _vehicleTypes = [
    // 'รถยนต์',
    'มอเตอร์ไซค์',
    // 'จักรยาน',
    // 'รถกระบะ',
  ];

  // แปลงประเภทยานพาหนะจากภาษาไทยเป็นภาษาอังกฤษสำหรับ API
  String _getVehicleTypeForAPI(String thaiVehicleType) {
    switch (thaiVehicleType) {
      case 'มอเตอร์ไซค์':
        return 'motorcycle';
      case 'รถยนต์':
        return 'car';
      case 'จักรยาน':
        return 'bicycle';
      case 'รถกระบะ':
        return 'pickup';
      default:
        return 'motorcycle'; // default fallback
    }
  }

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
    //   CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    // );

    _animationController.forward();
    _bounceController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bounceController.dispose();
    _idCardNumberController.dispose();
    _driverLicenseNumberController.dispose();
    _vehicleBrandController.dispose();
    _vehicleColorController.dispose();
    _vehiclePlateController.dispose();
    _vehicleProvinceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(
    ImageSource source,
    ValueSetter<File> onPicked,
  ) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      setState(() {
        onPicked(File(picked.path));
      });
    }
  }

  Widget _buildStepHeader(String stepNumber, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green[500]!, Colors.green[700]!],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green[600]!.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A202C),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentUploader({
    required String title,
    required String description,
    required IconData icon,
    required File? file,
    required VoidCallback onPickCamera,
    required VoidCallback onPickGallery,
    bool isRequired = false,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    final isUploaded = file != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUploaded
              ? Colors.green[300]!
              : (isRequired ? Colors.orange[200]! : Colors.grey[200]!),
          width: isUploaded ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isUploaded
                ? Colors.green[100]!.withOpacity(0.5)
                : Colors.grey[100]!.withOpacity(0.8),
            blurRadius: isUploaded ? 12 : 8,
            offset: const Offset(0, 4),
            spreadRadius: isUploaded ? 2 : 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primaryColor, secondaryColor],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
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
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2D3748),
                                height: 1.2,
                              ),
                            ),
                          ),
                          if (isRequired)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.orange[400]!,
                                    Colors.red[400]!,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'จำเป็น',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isUploaded)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[400]!, Colors.green[600]!],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green[400]!.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Image preview area
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isUploaded ? Colors.green[300]! : Colors.grey[300]!,
                  width: 2,
                  style: BorderStyle.solid,
                ),
                gradient: file == null
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryColor.withOpacity(0.05),
                          secondaryColor.withOpacity(0.1),
                        ],
                      )
                    : null,
              ),
              child: file == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.cloud_upload_outlined,
                            size: 32,
                            color: primaryColor.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'แตะเพื่อเลือกรูปภาพ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'รองรับ JPG, PNG (ไม่เกิน 10MB)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            file,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 180,
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Success indicator
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green[400]!,
                                      Colors.green[600]!,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green[600]!.withOpacity(
                                        0.4,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Delete button
                              GestureDetector(
                                onTap: () => setState(() {
                                  if (title.contains('ถ่ายรูปคู่บัตร'))
                                    _selfieWithId = null;
                                  if (title.contains('บัตรประชาชน'))
                                    _idCard = null;
                                  if (title.contains('ใบขับขี่'))
                                    _driverLicense = null;
                                  if (title.contains('รูปรถ'))
                                    _vehiclePhoto = null;
                                  if (title.contains('ทะเบียน'))
                                    _vehicleRegistration = null;
                                }),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red[500],
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red[500]!.withOpacity(
                                          0.4,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primaryColor, secondaryColor],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: onPickCamera,
                      icon: const Icon(Icons.camera_alt_rounded, size: 20),
                      label: const Text(
                        'ถ่ายรูป',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: primaryColor, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: OutlinedButton.icon(
                      onPressed: onPickGallery,
                      icon: Icon(
                        Icons.photo_library_rounded,
                        size: 20,
                        color: primaryColor,
                      ),
                      label: Text(
                        'เลือกรูป',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: primaryColor,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        side: BorderSide.none,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
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

  Widget _buildProgressSection() {
    // รายการเอกสารที่เป็น required (ปรับได้ตามจริง)
    final requiredDocs = [
      _selfieWithId,
      _idCard,
      _driverLicense,
      _vehiclePhoto,
      _vehicleRegistration,
    ];

    // รายการฟิลด์ข้อมูลที่ต้องกรอก
    final requiredFields = [
      _idCardNumberController.text,
      _driverLicenseNumberController.text,
      _selectedVehicleType,
      _vehicleBrandController.text,
      _vehicleColorController.text,
      _vehiclePlateController.text,
      _vehicleProvinceController.text,
    ];

    // นับที่กรอก/อัพโหลดแล้ว
    int completedDocs = requiredDocs.where((f) => f != null).length;
    int completedFields = requiredFields
        .where((v) => v != null && v.toString().trim().isNotEmpty)
        .length;

    final int totalRequiredFields = requiredDocs.length + requiredFields.length;
    final int completedTotal = completedDocs + completedFields;
    double progress = totalRequiredFields > 0
        ? (completedTotal / totalRequiredFields)
        : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF667EEA), const Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ความคืบหน้าการอัปโหลด',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      progress >= 1.0
                          ? 'เอกสารและข้อมูลครบถ้วนแล้ว!'
                          : 'เอกสารและข้อมูลที่ต้องการ ${totalRequiredFields - completedTotal} รายการ',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              ),
            ),
          ),
          if (progress >= 1.0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.celebration_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'พร้อมส่งข้อมูลครบถ้วนแล้ว!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String title,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required Color primaryColor,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLength = 50,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey[200]!,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              maxLength: maxLength,
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: Icon(icon, color: primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              validator: validator,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String title,
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required Color primaryColor,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey[200]!,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonFormField<String>(
              value: value,
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: Icon(icon, color: primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              items: items
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[50]!, Colors.indigo[50]!],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[500]!, Colors.indigo[600]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'ข้อมูลสำคัญ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoItem(
            Icons.verified_user_rounded,
            'ข้อมูลได้รับการปกป้อง',
            'ระบบเข้ารหัสข้อมูลทั้งหมดด้วยมาตรฐาน SSL',
            Colors.green[600]!,
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            Icons.speed_rounded,
            'ตรวจสอบเร็ว',
            'ทีมงานจะตรวจสอบภายใน 24 ชั่วโมง',
            Colors.orange[600]!,
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            Icons.support_agent_rounded,
            'ช่วยเหลือ 24/7',
            'มีทีมงานคอยให้คำปรึกษาตลอดเวลา',
            Colors.purple[600]!,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _submit() async {
    // ตรวจสอบเอกสารที่จำเป็น
    if (_selfieWithId == null ||
        _driverLicense == null ||
        _vehicleRegistration == null) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        animType: AnimType.scale,
        title: '⚠️ เอกสารไม่ครบถ้วน',
        desc: 'กรุณาอัปโหลดเอกสารที่จำเป็นให้ครบถ้วนก่อนส่งยืนยัน',
        btnOkOnPress: () {},
        btnOkColor: Colors.orange[600],
        btnOkText: 'เข้าใจแล้ว',
      ).show();
      return;
    }

    // ตรวจสอบข้อมูลที่กรอก
    if (_idCardNumberController.text.isEmpty ||
        _driverLicenseNumberController.text.isEmpty ||
        _selectedVehicleType == null ||
        _vehicleBrandController.text.isEmpty ||
        _vehicleColorController.text.isEmpty ||
        _vehiclePlateController.text.isEmpty ||
        _vehicleProvinceController.text.isEmpty) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        animType: AnimType.scale,
        title: '⚠️ ข้อมูลไม่ครบถ้วน',
        desc: 'กรุณากรอกข้อมูลส่วนตัวและยานพาหนะให้ครบถ้วน',
        btnOkOnPress: () {},
        btnOkColor: Colors.orange[600],
        btnOkText: 'เข้าใจแล้ว',
      ).show();
      return;
    }

    // ตรวจสอบเลขบัตรประชาชน
    if (_idCardNumberController.text.length != 13) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        animType: AnimType.scale,
        title: '⚠️ เลขบัตรประชาชนไม่ถูกต้อง',
        desc: 'เลขบัตรประชาชนต้องมี 13 หลัก',
        btnOkOnPress: () {},
        btnOkColor: Colors.orange[600],
        btnOkText: 'เข้าใจแล้ว',
      ).show();
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // เช็คสถานะปัจจุบัน ถ้าถูกปฏิเสธให้รีเซ็ตก่อนส่งใหม่
      final currentStatus = await RiderStatusService.getCurrentStatus();
      if (currentStatus == RiderStatus.rejected) {
        await RiderStatusService.resetForResubmission();
        print('🔄 Reset status for resubmission');
      }

      // เตรียมไฟล์เอกสาร - รองรับไฟล์ที่อาจจะไม่มี
      final documents = <String, File>{};

      // เอกสารที่จำเป็น
      documents['id_card_selfie'] = _selfieWithId!;
      documents['driving_license_photo'] = _driverLicense!;
      documents['vehicle_registration_photo'] = _vehicleRegistration!;

      // เอกสารที่ไม่จำเป็น (ถ้ามี)
      if (_idCard != null) {
        documents['id_card_photo'] = _idCard!;
      }
      if (_vehiclePhoto != null) {
        documents['vehicle_photo'] = _vehiclePhoto!;
      }

      print('📋 Preparing to submit with ${documents.length} files');

      // เรียก API
      final authService = AuthService();
      final result = await authService.submitIdentityVerification(
        idCardNumber: _idCardNumberController.text.trim(),
        driverLicenseNumber: _driverLicenseNumberController.text.trim(),
        vehicleType: _getVehicleTypeForAPI(_selectedVehicleType!),
        vehicleBrandModel: _vehicleBrandController.text.trim(),
        vehicleColor: _vehicleColorController.text.trim(),
        vehicleRegistrationNumber: _vehiclePlateController.text.trim(),
        vehicleRegistrationProvince: _vehicleProvinceController.text.trim(),
        documents: documents,
      );

      if (result['success']) {
        // อัพเดทสถานะในแอพ
        await RiderStatusService.setPending(
          'ส่งเอกสารยืนยันตัวตนเรียบร้อยแล้ว รอการตรวจสอบจากทีมงาน',
        );

        AwesomeDialog(
          context: context,
          dialogType: DialogType.success,
          animType: AnimType.scale,
          title: '🎉 ส่งเอกสารสำเร็จ',
          desc:
              result['message'] ??
              'ส่งเอกสารยืนยันตัวตนเรียบร้อยแล้ว\nทีมงานจะตรวจสอบและแจ้งผลภายใน 24 ชั่วโมง',
          btnOkOnPress: () {
            Navigator.pushReplacementNamed(context, '/home');
          },
          btnOkColor: Colors.green[600],
          btnOkText: 'เรียบร้อย',
        ).show();
      } else {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.rightSlide,
          title: '❌ เกิดข้อผิดพลาด',
          desc: result['message'] ?? 'ไม่สามารถส่งเอกสารได้',
          btnOkOnPress: () {},
          btnOkColor: Colors.red[600],
          btnOkText: 'ลองใหม่',
        ).show();
      }
    } catch (e) {
      print('❌ Submit error: $e');
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.rightSlide,
        title: '❌ เกิดข้อผิดพลาด',
        desc:
            'ไม่สามารถส่งเอกสารได้ในขณะนี้\nกรุณาตรวจสอบการเชื่อมต่อและลองใหม่',
        btnOkOnPress: () {},
        btnOkColor: Colors.red[600],
        btnOkText: 'ลองใหม่',
      ).show();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC), // เปลี่ยนเป็นสีขาวอมเทา
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Enhanced App Bar
              Container(
                // scale: _bounceAnimation,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.green[500]!, Colors.green[700]!],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ยืนยันตัวตนไรเดอร์',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'อัปโหลดเอกสารเพื่อเริ่มต้นการทำงาน',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.shield_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Main content area
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ListView(
                      padding: const EdgeInsets.only(top: 24),
                      children: [
                        // แสดงข้อมูลผู้ใช้จากหน้าสมัครสมาชิก
                        if (widget.userData != null) ...[
                          Container(
                            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Colors.blue[50]!, Colors.indigo[50]!],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.blue[200]!,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      color: Colors.blue[600],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'ข้อมูลส่วนตัว',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue[800],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'ชื่อ: ${widget.userData!['name'] ?? 'ไม่ระบุ'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  'อีเมล: ${widget.userData!['email'] ?? 'ไม่ระบุ'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  'เบอร์โทร: ${widget.userData!['phone'] ?? 'ไม่ระบุ'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                if (widget.userData!['province'] != null)
                                  Text(
                                    'ที่อยู่: ${widget.userData!['province']}, ${widget.userData!['amphure']}, ${widget.userData!['tambon']}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],

                        // Info card
                        _buildInfoCard(),

                        // Progress section
                        _buildProgressSection(),

                        // Document sections
                        _buildStepHeader(
                          '1',
                          'เอกสารประจำตัว',
                          'ยืนยันตัวตนและที่อยู่',
                        ),

                        _buildDocumentUploader(
                          title: 'ถ่ายรูปคู่บัตร',
                          description: 'ถือบัตรประชาชนพร้อมใบหน้าให้ชัดเจน',
                          icon: Icons.person_pin_circle_rounded,
                          file: _selfieWithId,
                          isRequired: true,
                          primaryColor: Colors.purple[500]!,
                          secondaryColor: Colors.purple[700]!,
                          onPickCamera: () => _pickImage(
                            ImageSource.camera,
                            (f) => setState(() => _selfieWithId = f),
                          ),
                          onPickGallery: () => _pickImage(
                            ImageSource.gallery,
                            (f) => setState(() => _selfieWithId = f),
                          ),
                        ),

                        _buildDocumentUploader(
                          title: 'บัตรประชาชน',
                          description: 'สำเนาหรือรูปถ่ายบัตรประชาชน (ถ้ามี)',
                          icon: Icons.badge_rounded,
                          file: _idCard,
                          primaryColor: Colors.indigo[500]!,
                          secondaryColor: Colors.indigo[700]!,
                          onPickCamera: () => _pickImage(
                            ImageSource.camera,
                            (f) => setState(() => _idCard = f),
                          ),
                          onPickGallery: () => _pickImage(
                            ImageSource.gallery,
                            (f) => setState(() => _idCard = f),
                          ),
                        ),

                        // เพิ่มการกรอกเลขบัตรประชาชน
                        _buildFormField(
                          title: 'เลขบัตรประชาชน',
                          hint: 'กรอกเลขบัตรประชาชน 13 หลัก',
                          icon: Icons.credit_card,
                          controller: _idCardNumberController,
                          primaryColor: Colors.indigo[500]!,
                          keyboardType: TextInputType.number,
                          maxLength: 13,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณากรอกเลขบัตรประชาชน';
                            }
                            if (value.length != 13) {
                              return 'เลขบัตรประชาชนต้องมี 13 หลัก';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),
                        _buildStepHeader(
                          '2',
                          'เอกสารการขับขี่',
                          'ใบอนุญาตขับขี่ที่ถูกต้อง',
                        ),

                        _buildDocumentUploader(
                          title: 'ใบขับขี่',
                          description: 'ใบอนุญาตขับขี่ที่ยังไม่หมดอายุ',
                          icon: Icons.drive_eta_rounded,
                          file: _driverLicense,
                          isRequired: true,
                          primaryColor: Colors.orange[500]!,
                          secondaryColor: Colors.orange[700]!,
                          onPickCamera: () => _pickImage(
                            ImageSource.camera,
                            (f) => setState(() => _driverLicense = f),
                          ),
                          onPickGallery: () => _pickImage(
                            ImageSource.gallery,
                            (f) => setState(() => _driverLicense = f),
                          ),
                        ),

                        // เพิ่มการกรอกเลขใบขับขี่
                        _buildFormField(
                          title: 'เลขใบขับขี่',
                          hint: 'กรอกเลขอนุญาตขับขี่',
                          icon: Icons.confirmation_number,
                          controller: _driverLicenseNumberController,
                          primaryColor: Colors.orange[500]!,
                          keyboardType: TextInputType.text,
                          maxLength: 20,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณากรอกเลขใบขับขี่';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),
                        _buildStepHeader(
                          '3',
                          'ข้อมูลยานพาหนะ',
                          'รูปและเอกสารรถที่ใช้งาน',
                        ),

                        _buildDocumentUploader(
                          title: 'รูปรถ',
                          description: 'รูปถ่ายรถที่ใช้สำหรับส่งอาหาร',
                          icon: Icons.two_wheeler_rounded,
                          file: _vehiclePhoto,
                          primaryColor: Colors.teal[500]!,
                          secondaryColor: Colors.teal[700]!,
                          onPickCamera: () => _pickImage(
                            ImageSource.camera,
                            (f) => setState(() => _vehiclePhoto = f),
                          ),
                          onPickGallery: () => _pickImage(
                            ImageSource.gallery,
                            (f) => setState(() => _vehiclePhoto = f),
                          ),
                        ),

                        _buildDocumentUploader(
                          title: 'ทะเบียนรถ',
                          description: 'สำเนาทะเบียนรถหรือคู่มือจดทะเบียน',
                          icon: Icons.description_rounded,
                          file: _vehicleRegistration,
                          isRequired: true,
                          primaryColor: Colors.red[500]!,
                          secondaryColor: Colors.red[700]!,
                          onPickCamera: () => _pickImage(
                            ImageSource.camera,
                            (f) => setState(() => _vehicleRegistration = f),
                          ),
                          onPickGallery: () => _pickImage(
                            ImageSource.gallery,
                            (f) => setState(() => _vehicleRegistration = f),
                          ),
                        ),

                        // เพิ่มข้อมูลยานพาหนะ
                        Container(
                          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: Text(
                            'ข้อมูลยานพาหนะ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),

                        _buildDropdownField(
                          title: 'ประเภทรถ',
                          hint: 'เลือกประเภทยานพาหนะ',
                          icon: Icons.directions_car,
                          value: _selectedVehicleType,
                          items: _vehicleTypes,
                          onChanged: (value) =>
                              setState(() => _selectedVehicleType = value),
                          primaryColor: Colors.blue[600]!,
                        ),

                        _buildFormField(
                          title: 'เลขทะเบียนรถ',
                          hint: 'เช่น 1กก 1234',
                          icon: Icons.confirmation_number,
                          controller: _vehiclePlateController,
                          primaryColor: Colors.orange[500]!,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณากรอกเลขทะเบียนรถ';
                            }
                            return null;
                          },
                        ),

                        // จังหวัดที่อยู่ในทะเบียนรถ
                        _buildFormField(
                          title: 'จังหวัดในทะเบียนรถ',
                          hint: 'เช่น กรุงเทพมหานคร',
                          icon: Icons.location_on,
                          controller: _vehicleProvinceController,
                          primaryColor: Colors.green[500]!,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณากรอกจังหวัด';
                            }
                            return null;
                          },
                        ),

                        _buildFormField(
                          title: 'ยี่ห้อ/รุ่น',
                          hint: 'เช่น Honda Click, Toyota Vios',
                          icon: Icons.branding_watermark,
                          controller: _vehicleBrandController,
                          primaryColor: Colors.purple[500]!,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณากรอกยี่ห้อ/รุ่นรถ';
                            }
                            return null;
                          },
                        ),

                        _buildFormField(
                          title: 'สีรถ',
                          hint: 'เช่น ขาว, แดง, ดำ',
                          icon: Icons.palette,
                          controller: _vehicleColorController,
                          primaryColor: Colors.pink[500]!,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณากรอกสีรถ';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 32),

                        // Security notice
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.lock_rounded,
                                  color: Colors.green[700],
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ความปลอดภัยของข้อมูล',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'เอกสารของคุณจะถูกเข้ารหัสและใช้เพื่อการยืนยันตัวตนเท่านั้น',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),

              // Enhanced submit button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(15, 15, 15, 20),
                child: Column(
                  children: [
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSubmitting
                              ? Colors.grey[400]
                              : Colors.green[600],
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          elevation: _isSubmitting ? 0 : 8,
                          shadowColor: Colors.green[600]!.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _isSubmitting
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Text(
                                    'กำลังส่งเอกสาร...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.rocket_launch_rounded,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'ส่งเอกสารเพื่อยืนยันตัวตน',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Helper text
                    Text(
                      'การส่งเอกสารหมายถึงคุณยอมรับเงื่อนไขการใช้งาน',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
