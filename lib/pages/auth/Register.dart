import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rider_delivery/pages/LoadingOverlay/LoadingOverlay.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  int? _gender;
  bool _agree = false;
  DateTime? _selectedDate;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String? _selectedImage;
  File? _image;

  // ข้อมูลจังหวัด อำเภอ ตำบล
  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _amphures = [];
  List<Map<String, dynamic>> _tambons = [];

  String? _selectedProvince;
  String? _selectedAmphure;
  String? _selectedTambon;

  int? _selectedProvinceId;
  int? _selectedAmphureId;

  final List<String> _imageOptions = [
    'assets/avatars/avatar-1.png',
    'assets/avatars/avatar-2.png',
    'assets/avatars/avatar-3.png',
    'assets/avatars/avatar-4.png',
  ];

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  Future<void> _loadProvinces() async {
    try {
      final String data = await rootBundle.loadString(
        'assets/data/thai_provinces.json',
      );
      final List<dynamic> jsonData = json.decode(data);
      setState(() {
        _provinces = jsonData.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    } catch (e) {
      // ถ้าไม่มีไฟล์ JSON ใช้ข้อมูลตัวอย่าง
      setState(() {
        _provinces = [];
      });
      debugPrint("โหลดไฟล์จังหวัดไม่สำเร็จ: $e");
    }
  }

  Future<void> _loadAmphures(int provinceId) async {
    try {
      final String data = await rootBundle.loadString(
        'assets/data/thai_amphures.json',
      );
      final List<dynamic> jsonData = json.decode(data);
      setState(() {
        _amphures = jsonData
            .where((item) => item['province_id'] == provinceId)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _selectedAmphure = null;
        _selectedAmphureId = null;
        _tambons.clear();
        _selectedTambon = null;
      });
    } catch (e) {
      // ข้อมูลตัวอย่าง
      setState(() {
        _amphures = [
          {'id': 1, 'name_th': 'เขตพระนคร', 'province_id': provinceId},
          {'id': 2, 'name_th': 'เขตดุสิต', 'province_id': provinceId},
          {'id': 3, 'name_th': 'เขตหนองจอก', 'province_id': provinceId},
        ];
        _selectedAmphure = null;
        _selectedAmphureId = null;
        _tambons.clear();
        _selectedTambon = null;
      });
    }
  }

  Future<void> _loadTambons(int amphureId) async {
    try {
      final String data = await rootBundle.loadString(
        'assets/data/thai_tambons.json',
      );
      final List<dynamic> jsonData = json.decode(data);
      setState(() {
        _tambons = jsonData
            .where((item) => item['amphure_id'] == amphureId)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _selectedTambon = null;
      });
    } catch (e) {
      // ข้อมูลตัวอย่าง
      setState(() {
        _tambons = [
          {'id': 1, 'name_th': 'แขวงพระบรมมหาราชวัง', 'amphure_id': amphureId},
          {'id': 2, 'name_th': 'แขวงวัดราชบพิธ', 'amphure_id': amphureId},
          {'id': 3, 'name_th': 'แขวงสำราญราฐ', 'amphure_id': amphureId},
        ];
        _selectedTambon = null;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF34C759),
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _selectedImage = null;
      });
    }
  }

  Future<void> _handleRegisterUser() async {
    if (_nameController.text.isEmpty) {
      _showAwesomeDialog(
        'ข้อผิดพลาด',
        'กรุณากรอกชื่อ - นามสกุล',
        DialogType.warning,
      );
      return;
    }
    if (_emailController.text.isEmpty) {
      _showAwesomeDialog('ข้อผิดพลาด', 'กรุณากรอกอีเมล', DialogType.warning);
      return;
    }
    // email ไม่ถูกต้อง
    else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailController.text)) {
      _showAwesomeDialog(
        'ข้อผิดพลาด',
        'รูปแบบอีเมลไม่ถูกต้อง',
        DialogType.warning,
      );
      return;
    }
    if (_phoneController.text.isEmpty) {
      _showAwesomeDialog(
        'ข้อผิดพลาด',
        'กรุณากรอกเบอร์โทรศัพท์',
        DialogType.warning,
      );
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showAwesomeDialog('ข้อผิดพลาด', 'กรุณากรอกรหัสผ่าน', DialogType.warning);
      return;
    } else if (_passwordController.text != _confirmPasswordController.text) {
      _showAwesomeDialog('ข้อผิดพลาด', 'รหัสผ่านไม่ตรงกัน', DialogType.warning);
      return;
    } else if (_passwordController.text.length < 6) {
      _showAwesomeDialog(
        'ข้อผิดพลาด',
        'รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร',
        DialogType.warning,
      );
      return;
    } else if (!RegExp(
      r'^(?=.*[a-zA-Z])(?=.*[0-9])',
    ).hasMatch(_passwordController.text)) {
      _showAwesomeDialog(
        'ข้อผิดพลาด',
        'รหัสผ่านต้องประกอบด้วยตัวอักษรและตัวเลขอย่างน้อย 1 ตัว',
        DialogType.warning,
      );
      return;
    }
    if (_selectedDate == null) {
      _showAwesomeDialog('ข้อผิดพลาด', 'กรุณาเลือกวันเกิด', DialogType.warning);
      return;
    }
    if (_gender == null) {
      _showAwesomeDialog('ข้อผิดพลาด', 'กรุณาเลือกเพศ', DialogType.warning);
      return;
    }
    if (_selectedImage == null && _image == null) {
      _showAwesomeDialog(
        'ข้อผิดพลาด',
        'กรุณาเลือกรูปโปรไฟล์',
        DialogType.warning,
      );
      return;
    }
    if (_selectedProvince == null ||
        _selectedAmphure == null ||
        _selectedTambon == null) {
      _showAwesomeDialog(
        'ข้อผิดพลาด',
        'กรุณาเลือกที่อยู่ให้ครบถ้วน',
        DialogType.warning,
      );
      return;
    }
    if (!_agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'กรุณายินยอมเงื่อนไข',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // บันทึกข้อมูลผู้ใช้ไว้ (จำลอง - ในความเป็นจริงจะส่งไปยัง API)
    final userData = {
      'name': _nameController.text,
      'email': _emailController.text,
      'password': _passwordController.text,
      'phone': _phoneController.text,
      'gender': _gender,
      'birthdate': _selectedDate,
      'address': _addressController.text,
      'province': _selectedProvince,
      'amphure': _selectedAmphure,
      'tambon': _selectedTambon,
      'selectedImage': _selectedImage,
      'uploadedImage': _image,
    };

    // TODO: ส่งข้อมูลไปยัง API เพื่อสร้างบัญชีผู้ใช้
    print('User registration data: $userData');

    // จำลองการสมัครสำเร็จ
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      title: 'สมัครสมาชิกสำเร็จ',
      desc:
          'บัญชีของคุณถูกสร้างเรียบร้อยแล้ว\nกรุณาเข้าสู่ระบบเพื่อยืนยันตัวตน',
      btnOkOnPress: () {
        Navigator.pushReplacementNamed(context, '/login');
      },
      btnOkColor: const Color(0xFF34C759),
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: const Color(0xFF34C759),
          elevation: 0,
          title: const Text(
            'สมัครสมาชิก',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF34C759),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.person_add,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ข้อมูลส่วนตัว',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'กรุณากรอกข้อมูลให้ครบถ้วน',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),

              // Form Section
              Container(
                margin: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionCard(
                        title: 'รูปโปรไฟล์',
                        icon: Icons.account_circle,
                        child: _buildAvatarSelector(),
                      ),

                      const SizedBox(height: 20),

                      _buildSectionCard(
                        title: 'ข้อมูลพื้นฐาน',
                        icon: Icons.person,
                        child: Column(
                          children: [
                            _buildTextField(
                              _nameController,
                              'ชื่อ - นามสกุล',
                              Icons.person,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              _emailController,
                              'อีเมล',
                              Icons.email,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              _phoneController,
                              'เบอร์โทรศัพท์',
                              Icons.phone,
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildSectionCard(
                        title: 'รหัสผ่าน',
                        icon: Icons.lock,
                        child: Column(
                          children: [
                            _buildTextField(
                              _passwordController,
                              'รหัสผ่าน',
                              Icons.lock,
                              obscureText: true,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              _confirmPasswordController,
                              'ยืนยันรหัสผ่าน',
                              Icons.lock_outline,
                              obscureText: true,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildSectionCard(
                        title: 'ข้อมูลส่วนตัว',
                        icon: Icons.info,
                        child: Column(
                          children: [
                            _buildDateSelector(),
                            const SizedBox(height: 20),
                            _buildGenderSelector(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildSectionCard(
                        title: 'ที่อยู่',
                        icon: Icons.location_on,
                        child: Column(
                          children: [
                            _buildTextField(
                              _addressController,
                              'ที่อยู่',
                              Icons.home,
                            ),
                            const SizedBox(height: 16),
                            _buildAddressDropdowns(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildAgreementSection(),

                      const SizedBox(height: 30),

                      _buildSubmitButton(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF34C759).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF34C759)),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF34C759),
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF34C759)),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF34C759), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'กรุณากรอก $label';
        if (label == 'อีเมล' && !value.contains('@'))
          return 'รูปแบบอีเมลไม่ถูกต้อง';
        return null;
      },
    );
  }

  Widget _buildAvatarSelector() {
    return Column(
      children: [
        // Display current selected image
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF34C759), width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF34C759).withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: _image != null
              ? CircleAvatar(radius: 57, backgroundImage: FileImage(_image!))
              : _selectedImage != null
              ? CircleAvatar(
                  radius: 57,
                  backgroundImage: AssetImage(_selectedImage!),
                )
              : const CircleAvatar(
                  radius: 57,
                  backgroundColor: Color(0xFFF8F9FA),
                  child: Icon(Icons.person, size: 50, color: Colors.grey),
                ),
        ),

        const SizedBox(height: 20),

        // Preset avatars
        const Text(
          'เลือกรูปโปรไฟล์',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _imageOptions.length,
            itemBuilder: (context, index) {
              final imagePath = _imageOptions[index];
              final isSelected = _selectedImage == imagePath;

              return GestureDetector(
                onTap: () => setState(() {
                  _selectedImage = imagePath;
                  _image = null;
                }),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF34C759)
                          : Colors.grey.shade300,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundImage: AssetImage(imagePath),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        OutlinedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.upload_file),
          label: const Text("อัปโหลดรูปจากเครื่อง"),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF34C759),
            side: const BorderSide(color: Color(0xFF34C759)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Color(0xFF34C759)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedDate == null
                    ? 'เลือกวันเกิด'
                    : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                style: TextStyle(
                  color: _selectedDate == null ? Colors.grey : Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('เพศ', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildGenderOption(0, 'ชาย', Icons.male),
            const SizedBox(width: 16),
            _buildGenderOption(1, 'หญิง', Icons.female),
            const SizedBox(width: 16),
            _buildGenderOption(2, 'ไม่ระบุ', Icons.person),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(int value, String label, IconData icon) {
    final isSelected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF34C759)
                : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF34C759)
                  : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF34C759),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressDropdowns() {
    return Column(
      children: [
        _buildDropdown(
          'จังหวัด',
          _selectedProvince,
          _provinces.map((p) => p['name_th'] as String).toList(),
          (value) {
            final province = _provinces.firstWhere(
              (p) => p['name_th'] == value,
            );
            setState(() {
              _selectedProvince = value;
              _selectedProvinceId = province['id'];
              _selectedAmphure = null;
              _selectedAmphureId = null;
              _selectedTambon = null;
              _amphures.clear();
              _tambons.clear();
            });
            if (_selectedProvinceId != null) {
              _loadAmphures(_selectedProvinceId!);
            }
          },
          Icons.location_city,
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          'อำเภอ',
          _selectedAmphure,
          _amphures.map((a) => a['name_th'] as String).toList(),
          _selectedProvince == null
              ? null
              : (value) {
                  final amphure = _amphures.firstWhere(
                    (a) => a['name_th'] == value,
                  );
                  setState(() {
                    _selectedAmphure = value;
                    _selectedAmphureId = amphure['id'];
                    _selectedTambon = null;
                    _tambons.clear();
                  });
                  if (_selectedAmphureId != null) {
                    _loadTambons(_selectedAmphureId!);
                  }
                },
          Icons.location_on,
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          'ตำบล',
          _selectedTambon,
          _tambons.map((t) => t['name_th'] as String).toList(),
          _selectedAmphure == null
              ? null
              : (value) {
                  setState(() => _selectedTambon = value);
                },
          Icons.place,
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?>? onChanged,
    IconData icon,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF34C759)),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF34C759), width: 2),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'กรุณาเลือก $label' : null,
    );
  }

  Widget _buildAgreementSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _agree,
            activeColor: const Color(0xFF34C759),
            onChanged: (val) => setState(() => _agree = val ?? false),
          ),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 12.0),
              child: Text(
                'ข้าพเจ้ายินยอมให้เข้าถึงข้อมูลส่วนบุคคลและใช้บริการตามเงื่อนไขที่กำหนด',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF34C759),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 3,
        ),
        onPressed: _handleRegisterUser,
        child: const Text(
          'สมัครสมาชิก',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showAwesomeDialog(String title, String message, DialogType type) {
    AwesomeDialog(
      context: context,
      dialogType: type,
      animType: AnimType.scale,
      title: title,
      desc: message,
      btnOkOnPress: () {},
      btnOkColor: const Color(0xFF34C759),
    ).show();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
