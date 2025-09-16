import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:promptpay_qrcode_generate/promptpay_qrcode_generate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import '../../../APIs/middleware/topupGP.dart';
import 'image_saver.dart';

class CreditDialogs {
  static void showTopUpDialog(
    BuildContext context,
    Function(double) onConfirm,
  ) {
    final GlobalKey qrKey = GlobalKey();
    final TextEditingController amountController = TextEditingController();
    double selectedAmount = 0;
    bool showQR = false;
    bool hasUploadedSlip = false;
    bool isLoading = false;
    bool isSavingQR = false;
    File? selectedImage;

    // ฟิกเบอร์ เพื่อให้QR Code ไม่ซ้ำกันและถูกเจนตามเบอร์โทรและจำนวนเงิน
    String fixedPhoneNumber =
        "0123456789"; // เปลี่ยนเป็นเบอร์โทรของผู้ใช้จริง ทำให้รองรับเบอร์ที่มาจากฐานข้อมูลAPI

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final double dialogMaxWidth = showQR
                ? MediaQuery.of(context).size.width * 0.95
                : 420; // ขยายความกว้างเมื่อ showQR = true

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: dialogMaxWidth),
                child: WillPopScope(
                  onWillPop: () async => false,
                  child: AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 10,
                    title: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green[600]!, Colors.green[400]!],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.add_circle_outline,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'เติมเครดิต',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    content: ConstrainedBox(
                      // ให้ dialog เลื่อนขึ้นลงได้เมื่อมีเนื้อหามาก (เช่น เมื่อแสดง QR + รูปสลิป)
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.85,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!showQR) ...[
                              const Text(
                                'เลือกจำนวนเงินที่ต้องการเติม',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 12),

                              // Amount Selection Chips
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [100, 200, 300, 500, 1000, 2000].map((
                                  amount,
                                ) {
                                  return _buildAmountChip(
                                    amount: amount.toDouble(),
                                    selectedAmount: selectedAmount,
                                    onSelected: (value) {
                                      setState(() {
                                        selectedAmount = value;
                                        amountController.text = value
                                            .toInt()
                                            .toString();
                                      });
                                    },
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: 16),
                              const Text('หรือกรอกจำนวนเงินเอง'),
                              const SizedBox(height: 8),

                              // Custom Amount Input
                              TextField(
                                controller: amountController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  labelText: 'จำนวนเงิน',
                                  hintText: 'ขั้นต่ำ 100 บาท',
                                  prefixText: '฿ ',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        amountController.clear();
                                        selectedAmount = 0;
                                      });
                                    },
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    if (value.isNotEmpty) {
                                      selectedAmount =
                                          double.tryParse(value) ?? 0;
                                    } else {
                                      selectedAmount = 0;
                                    }
                                  });
                                },
                              ),

                              if (selectedAmount >= 100) ...[
                                const SizedBox(height: 20),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blue[600]!,
                                        Colors.blue[400]!,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.qr_code,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'PromptPay',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'จำนวน ฿ ${selectedAmount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],

                            if (showQR) ...[
                              // QR Code Display
                              Center(
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.blue[600]!,
                                            Colors.blue[400]!,
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.08,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(10),
                                        child: GestureDetector(
                                          onLongPress: () async {
                                            setState(() {
                                              isSavingQR = true;
                                            });

                                            try {
                                              await _saveQrToGallery(qrKey);
                                            } catch (e) {
                                              // Error is handled in _saveQrToGallery
                                            } finally {
                                              setState(() {
                                                isSavingQR = false;
                                              });
                                            }
                                          },
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              RepaintBoundary(
                                                key: qrKey,
                                                child: QRCodeGenerate(
                                                  promptPayId: fixedPhoneNumber,
                                                  amount: selectedAmount,
                                                  width: 200,
                                                  height: 200,
                                                ),
                                              ),
                                              if (isSavingQR)
                                                Container(
                                                  width: 200,
                                                  height: 200,
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withOpacity(0.6),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: const Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      CircularProgressIndicator(
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                              Color
                                                            >(Colors.white),
                                                      ),
                                                      SizedBox(height: 8),
                                                      Text(
                                                        'กำลังบันทึก...',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Helper text for long press
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.amber[200]!,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.touch_app,
                                            size: 16,
                                            color: Colors.amber[700],
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'กดค้าง QR Code เพื่อบันทึกรูป',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.amber[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.green[50]!,
                                            Colors.blue[50]!,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.blue[200]!,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            'จำนวนเงิน: ฿ ${selectedAmount.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blue[800],
                                            ),
                                          ),
                                          Text(
                                            'สแกน QR Code เพื่อชำระเงิน',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue[600],
                                            ),
                                          ),
                                          Text(
                                            'เบอร์โทร: $fixedPhoneNumber',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.blue[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 20),
                                    const Text(
                                      'อัพโหลดสลิปการโอนเงิน',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Upload Slip Button with Image Picker
                                    GestureDetector(
                                      onTap: () async {
                                        final ImagePicker picker =
                                            ImagePicker();
                                        showModalBottomSheet(
                                          context: context,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(20),
                                            ),
                                          ),
                                          builder: (ctx) => Container(
                                            padding: const EdgeInsets.all(20),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 50,
                                                  height: 5,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[300],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                const Text(
                                                  'เลือกรูปสลิป',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          gradient: LinearGradient(
                                                            colors: [
                                                              Colors.blue[600]!,
                                                              Colors.blue[400]!,
                                                            ],
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                        child: ElevatedButton.icon(
                                                          onPressed: () async {
                                                            Navigator.pop(ctx);
                                                            final XFile?
                                                            image = await picker
                                                                .pickImage(
                                                                  source:
                                                                      ImageSource
                                                                          .camera,
                                                                );
                                                            if (image != null) {
                                                              setState(() {
                                                                selectedImage =
                                                                    File(
                                                                      image
                                                                          .path,
                                                                    );
                                                                hasUploadedSlip =
                                                                    true;
                                                              });
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                const SnackBar(
                                                                  content: Text(
                                                                    '📷 ถ่ายรูปสลิปเรียบร้อย',
                                                                  ),
                                                                  backgroundColor:
                                                                      Colors
                                                                          .green,
                                                                ),
                                                              );
                                                            }
                                                          },
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                Colors
                                                                    .transparent,
                                                            shadowColor: Colors
                                                                .transparent,
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  vertical: 15,
                                                                ),
                                                          ),
                                                          icon: const Icon(
                                                            Icons.camera_alt,
                                                            color: Colors.white,
                                                          ),
                                                          label: const Text(
                                                            'ถ่ายรูป',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          gradient: LinearGradient(
                                                            colors: [
                                                              Colors
                                                                  .green[600]!,
                                                              Colors
                                                                  .green[400]!,
                                                            ],
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                        child: ElevatedButton.icon(
                                                          onPressed: () async {
                                                            Navigator.pop(ctx);
                                                            final XFile?
                                                            image = await picker
                                                                .pickImage(
                                                                  source:
                                                                      ImageSource
                                                                          .gallery,
                                                                );
                                                            if (image != null) {
                                                              setState(() {
                                                                selectedImage =
                                                                    File(
                                                                      image
                                                                          .path,
                                                                    );
                                                                hasUploadedSlip =
                                                                    true;
                                                              });
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                const SnackBar(
                                                                  content: Text(
                                                                    '🖼️ เลือกรูปสลิปเรียบร้อย',
                                                                  ),
                                                                  backgroundColor:
                                                                      Colors
                                                                          .green,
                                                                ),
                                                              );
                                                            }
                                                          },
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                Colors
                                                                    .transparent,
                                                            shadowColor: Colors
                                                                .transparent,
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  vertical: 15,
                                                                ),
                                                          ),
                                                          icon: const Icon(
                                                            Icons.photo_library,
                                                            color: Colors.white,
                                                          ),
                                                          label: const Text(
                                                            'เลือกจากเครื่อง',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 20),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        // ขยายความสูงเมื่อมีรูป ให้เห็นชัดขึ้นใน dialog
                                        height: selectedImage != null
                                            ? 300
                                            : 120,
                                        decoration: BoxDecoration(
                                          color: hasUploadedSlip
                                              ? Colors.green[50]
                                              : Colors.grey[100],
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: hasUploadedSlip
                                                ? Colors.green[300]!
                                                : Colors.grey[300]!,
                                            style: BorderStyle.solid,
                                          ),
                                        ),
                                        child: selectedImage != null
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(11),
                                                child: Stack(
                                                  fit: StackFit.expand,
                                                  children: [
                                                    // แตะรูปเพื่อขยายเต็มหน้าจอ
                                                    InkWell(
                                                      onTap: () {
                                                        if (selectedImage ==
                                                            null)
                                                          return;
                                                        showDialog(
                                                          context: context,
                                                          builder: (_) {
                                                            return GestureDetector(
                                                              onTap: () =>
                                                                  Navigator.of(
                                                                    context,
                                                                  ).pop(),
                                                              child: Container(
                                                                color: Colors
                                                                    .black,
                                                                child: SafeArea(
                                                                  child: Stack(
                                                                    children: [
                                                                      Center(
                                                                        child: InteractiveViewer(
                                                                          panEnabled:
                                                                              true,
                                                                          minScale:
                                                                              1,
                                                                          maxScale:
                                                                              4,
                                                                          child: Image.file(
                                                                            selectedImage!,
                                                                            fit:
                                                                                BoxFit.contain,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      Positioned(
                                                                        top: 16,
                                                                        right:
                                                                            16,
                                                                        child: IconButton(
                                                                          icon: const Icon(
                                                                            Icons.close,
                                                                            color:
                                                                                Colors.white,
                                                                          ),
                                                                          onPressed: () => Navigator.of(
                                                                            context,
                                                                          ).pop(),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        );
                                                      },
                                                      child: Image.file(
                                                        selectedImage!,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: 8,
                                                      right: 8,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              6,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.green,
                                                          shape:
                                                              BoxShape.circle,
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                    0.3,
                                                                  ),
                                                              blurRadius: 4,
                                                            ),
                                                          ],
                                                        ),
                                                        child: const Icon(
                                                          Icons.check,
                                                          color: Colors.white,
                                                          size: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    hasUploadedSlip
                                                        ? Icons.check_circle
                                                        : Icons
                                                              .add_photo_alternate,
                                                    size: 40,
                                                    color: hasUploadedSlip
                                                        ? Colors.green[600]
                                                        : Colors.grey[600],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    hasUploadedSlip
                                                        ? 'อัพโหลดสลิปแล้ว'
                                                        : 'แตะเพื่อเลือกรูปสลิป',
                                                    style: TextStyle(
                                                      color: hasUploadedSlip
                                                          ? Colors.green[700]
                                                          : Colors.grey[700],
                                                      fontWeight:
                                                          hasUploadedSlip
                                                          ? FontWeight.w600
                                                          : FontWeight.normal,
                                                    ),
                                                  ),
                                                  if (!hasUploadedSlip)
                                                    Text(
                                                      'รองรับไฟล์ JPG, PNG',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[500],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
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
                        child: const Text(
                          'ยกเลิก',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!showQR)
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue[600]!, Colors.blue[400]!],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: selectedAmount >= 100
                                ? () {
                                    setState(() {
                                      showQR = true;
                                    });
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'สร้าง QR Code',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (showQR)
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green[600]!, Colors.green[400]!],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: (hasUploadedSlip && !isLoading)
                                ? () async {
                                    setState(() {
                                      isLoading = true;
                                    });

                                    try {
                                      // เรียก API TopupGP
                                      final topupAPI = TopupGP();
                                      final result = await topupAPI.topupGP(
                                        amount: selectedAmount,
                                        slipFile: selectedImage,
                                      );

                                      setState(() {
                                        isLoading = false;
                                      });

                                      if (result['success']) {
                                        Navigator.pop(context);
                                        onConfirm(selectedAmount);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              result['message'] ??
                                                  'ส่งคำขอเติมเงินสำเร็จ รอการอนุมัติจากแอดมิน',
                                            ),
                                            backgroundColor: Colors.green,
                                            duration: const Duration(
                                              seconds: 4,
                                            ),
                                          ),
                                        );
                                      } else {
                                        // แสดง error
                                        final errorMessage =
                                            result['error']?['error'] ??
                                            result['message'] ??
                                            'เกิดข้อผิดพลาดในการเติมเงิน';
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(errorMessage),
                                            backgroundColor: Colors.red,
                                            duration: const Duration(
                                              seconds: 4,
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setState(() {
                                        isLoading = false;
                                      });

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'เกิดข้อผิดพลาด: ${e.toString()}',
                                          ),
                                          backgroundColor: Colors.red,
                                          duration: const Duration(seconds: 4),
                                        ),
                                      );
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'กำลังส่งข้อมูล...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'ยืนยันการเติม',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static void showWithdrawDialog(
    BuildContext context,
    double currentCredit,
    Function(double) onConfirm,
  ) {
    final TextEditingController amountController = TextEditingController();
    double selectedAmount = 0;
    String selectedPaymentMethod = '';
    final double fee = 10.0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            double totalDeduction =
                selectedAmount + (selectedAmount >= 50 ? fee : 0);
            bool canWithdraw =
                selectedAmount >= 50 && totalDeduction <= currentCredit;

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
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ยอดเครดิตปัจจุบัน: ฿ ${currentCredit.toStringAsFixed(2)}',
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      'เลือกจำนวนเงินที่ต้องการถอน',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),

                    // Amount Selection Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [100, 200, 300, 500, 1000].map((amount) {
                        double amountDouble = amount.toDouble();
                        bool isEnabled = (amountDouble + fee) <= currentCredit;
                        return _buildAmountChip(
                          amount: amountDouble,
                          selectedAmount: selectedAmount,
                          isEnabled: isEnabled,
                          onSelected: isEnabled
                              ? (value) {
                                  setState(() {
                                    selectedAmount = value;
                                    amountController.text = value
                                        .toInt()
                                        .toString();
                                  });
                                }
                              : null,
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),
                    const Text('หรือกรอกจำนวนเงินเอง'),
                    const SizedBox(height: 8),

                    // Custom Amount Input
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'จำนวนเงิน',
                        hintText: 'ขั้นต่ำ 50 บาท',
                        prefixText: '฿ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              amountController.clear();
                              selectedAmount = 0;
                            });
                          },
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          if (value.isNotEmpty) {
                            selectedAmount = double.tryParse(value) ?? 0;
                          } else {
                            selectedAmount = 0;
                          }
                        });
                      },
                    ),

                    // Fee Information
                    if (selectedAmount >= 50) ...[
                      Container(
                        margin: const EdgeInsets.only(top: 12),
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
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('จำนวนเงินที่ถอน:'),
                                Text('฿ ${selectedAmount.toStringAsFixed(2)}'),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('ค่าธรรมเนียม:'),
                                Text('฿ ${fee.toStringAsFixed(2)}'),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'รวมที่จะหัก:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '฿ ${totalDeduction.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Text(
                      'ปลายทางการโอน',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),

                    // Payment Methods
                    _buildPaymentMethodTile(
                      title: 'บัญชีธนาคารที่ลงทะเบียน',
                      icon: Icons.account_balance,
                      isSelected: selectedPaymentMethod == 'bank',
                      onTap: () {
                        setState(() {
                          selectedPaymentMethod = 'bank';
                        });
                      },
                    ),
                    _buildPaymentMethodTile(
                      title: 'PromptPay',
                      icon: Icons.qr_code,
                      isSelected: selectedPaymentMethod == 'promptpay',
                      onTap: () {
                        setState(() {
                          selectedPaymentMethod = 'promptpay';
                        });
                      },
                    ),

                    // Warning for insufficient balance
                    if (selectedAmount >= 50 && !canWithdraw) ...[
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_outlined,
                              color: Colors.red[600],
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'เครดิตไม่เพียงพอสำหรับการถอนจำนวนนี้',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // actions: [
              //   TextButton(
              //     onPressed: () => Navigator.pop(context),
              //     child: const Text('ยกเลิก'),
              //   ),
              //   ElevatedButton(
              //     onPressed: (canWithdraw && selectedPaymentMethod.isNotEmpty)
              //         ? () async {
              //             Navigator.pop(context);

              //             // แสดง loading
              //             ScaffoldMessenger.of(context).showSnackBar(
              //               const SnackBar(
              //                 content: Row(
              //                   children: [
              //                     CircularProgressIndicator(
              //                       valueColor: AlwaysStoppedAnimation<Color>(
              //                         Colors.white,
              //                       ),
              //                     ),
              //                     SizedBox(width: 16),
              //                     Text('กำลังส่งคำขอถอนเงิน...'),
              //                   ],
              //                 ),
              //                 backgroundColor: Colors.orange,
              //                 duration: Duration(seconds: 10),
              //               ),
              //             );

              // try {
              //   // เรียก API ถอนเงิน
              //   final result = await withdrawCredit(
              //     amount: selectedAmount,
              //     bankAccount: selectedPaymentMethod,
              //     bankName: selectedPaymentMethod.contains('ธนาคาร')
              //         ? selectedPaymentMethod
              //         : 'ธนาคารที่เลือก',
              //     note: 'ถอนเงินผ่านแอปพลิเคชัน',
              //   );

              //   // ซ่อน loading snackbar
              //   ScaffoldMessenger.of(context).hideCurrentSnackBar();

              //   if (result['success']) {
              //     // แสดงผลสำเร็จ
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       SnackBar(
              //         content: Text(
              //           result['message'] ?? 'ส่งคำขอถอนเงินสำเร็จ',
              //         ),
              //         backgroundColor: Colors.green,
              //       ),
              //     );

              //     // เรียก callback เพื่ออัพเดท UI
              //     onConfirm(totalDeduction);
              //   } else {
              //     // แสดง error
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       SnackBar(
              //         content: Text(
              //           result['message'] ?? 'ไม่สามารถถอนเงินได้',
              //         ),
              //         backgroundColor: Colors.red,
              //       ),
              //     );
              //   }
              // } catch (e) {
              //   // ซ่อน loading snackbar
              //   ScaffoldMessenger.of(context).hideCurrentSnackBar();

              //   // แสดง error
              //   ScaffoldMessenger.of(context).showSnackBar(
              //     SnackBar(
              //       content: Text(
              //         'เกิดข้อผิดพลาด: ${e.toString()}',
              //       ),
              //       backgroundColor: Colors.red,
              //     ),
              //   );
              // }
              //           }
              //         : null,
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: Colors.orange[600],
              //       foregroundColor: Colors.white,
              //     ),
              //     child: const Text('ยืนยันการถอน'),
              //   ),
              // ],
            );
          },
        );
      },
    );
  }

  static Widget _buildAmountChip({
    required double amount,
    required double selectedAmount,
    bool isEnabled = true,
    Function(double)? onSelected,
  }) {
    bool isSelected = selectedAmount == amount;

    return FilterChip(
      label: Text('฿ ${amount.toInt()}'),
      selected: isSelected,
      onSelected: isEnabled
          ? (selected) {
              if (selected && onSelected != null) {
                onSelected(amount);
              }
            }
          : null,
      backgroundColor: isEnabled ? Colors.grey[100] : Colors.grey[300],
      selectedColor: Colors.green[100],
      checkmarkColor: Colors.green[600],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: TextStyle(
        color: isEnabled
            ? (isSelected ? Colors.green[700] : Colors.black87)
            : Colors.grey[600],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  static Widget _buildPaymentMethodTile({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Icon(
          icon,
          size: 20,
          color: isSelected ? Colors.blue[600] : Colors.grey[600],
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.blue[700] : Colors.black87,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: Colors.blue[600], size: 20)
            : Icon(Icons.circle_outlined, color: Colors.grey[400], size: 20),
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? Colors.blue[300]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        tileColor: isSelected ? Colors.blue[50] : Colors.white,
        onTap: onTap,
      ),
    );
  }

  // Helper method to save QR code to gallery
  static Future<void> _saveQrToGallery(GlobalKey key) async {
    try {
      if (key.currentContext == null) {
        throw Exception('QR Code ไม่พบ');
      }

      RenderRepaintBoundary boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        Uint8List pngBytes = byteData.buffer.asUint8List();
        await ImageSaver.saveImage(
          pngBytes,
          name: "qr_promptpay_${DateTime.now().millisecondsSinceEpoch}",
        );
      } else {
        throw Exception('ไม่สามารถแปลง QR Code เป็นรูปภาพได้');
      }
    } catch (e) {
      // Error will be shown via ImageSaver's toast
      rethrow;
    }
  }
}
