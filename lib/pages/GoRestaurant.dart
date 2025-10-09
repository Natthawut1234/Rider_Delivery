import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:rider_delivery/APIs/Orders/OrdersSocket.dart';
import 'package:rider_delivery/APIs/Orders/models/Order_items.dart';
import 'package:rider_delivery/pages/maps/map_button_widget.dart';

class GoRestaurant extends StatefulWidget {
  const GoRestaurant({super.key});

  @override
  _GoRestaurantState createState() => _GoRestaurantState();
}

class _GoRestaurantState extends State<GoRestaurant> {
  int? orderId;
  int? userId;
  int? riderId;
  Order? currentOrder;
  RiderControllerSocket? _orderController;
  bool arrivedAtRestaurant = false;
  bool confirmedArrival = false;
  bool foodReceived = false;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (orderId == null) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        orderId = args['orderId'];
        riderId = args['riderId'];
        userId = args['userId'];
        print(
          'GoRestaurant: Received orderId: $orderId, riderId: $riderId, userId: $userId',
        );
        _initializeData();
      } else {
        print('GoRestaurant: No arguments received');
        setState(() => _isLoading = false);
      }
    } else {
      _loadOrderData();
    }
  }

  void _initializeData() {
    _orderController = Provider.of<RiderControllerSocket>(
      context,
      listen: false,
    );
    print('GoRestaurant: Controller initialized');
    _loadOrderData();
  }

  void _loadOrderData() async {
    if (orderId == null || _orderController == null) {
      print('GoRestaurant: orderId or controller is null');
      setState(() => _isLoading = false);
      return;
    }
    print(
      'GoRestaurant: Looking for order $orderId in ${_orderController!.orders.length} orders',
    );

    for (var order in _orderController!.orders) {
      print(
        'Available order: ${order.orderId} - Status: ${order.status} - Rider: ${order.riderId}',
      );
    }

    Order? order;
    try {
      order = _orderController!.orders
          .where((o) => o.orderId == orderId)
          .firstOrNull;
    } catch (e) {
      print('Error finding order: $e');
    }

    if (order == null) {
      print(
        'GoRestaurant: Order not found in current list, fetching fresh data...',
      );
      try {
        await _orderController!.fetchOrdersByRider(riderId: riderId!);
        order = _orderController!.orders
            .where((o) => o.orderId == orderId)
            .firstOrNull;
      } catch (e) {
        print('Error fetching orders: $e');
      }
    }

    setState(() {
      currentOrder = order;
      _isLoading = false;
    });

    if (order != null) {
      print('GoRestaurant: Order found - ${order.shopName}');
      _orderController!.watchOrder(orderId!);
    } else {
      print('GoRestaurant: Order still not found after fetch');
    }
  }

  // Getter functions
  String get restaurantName => currentOrder?.shopName ?? 'ร้านอาหาร';
  String get restaurantAddress =>
      currentOrder?.marketLocation?['address'] ?? 'ไม่ระบุที่อยู่ร้าน';

  String get customerName {
    final nameInLocation = currentOrder?.customerLocation?['name']?.toString();
    final directClientName = currentOrder?.clientName;
    if (nameInLocation != null && nameInLocation.isNotEmpty)
      return nameInLocation;
    if (directClientName != null && directClientName.isNotEmpty)
      return directClientName;
    return 'สมุย';
  }

  String get customerPhone => currentOrder?.customerLocation?['phone'] ?? '';
  String get customerAddress =>
      currentOrder?.customerLocation?['address'] ??
      currentOrder?.address ??
      'ไม่ระบุที่อยู่';
  String get paymentMethod => currentOrder?.paymentMethod ?? 'เงินสด';
  double get totalPrice => currentOrder?.totalPrice ?? 0.0;
  double get deliveryFee => currentOrder?.deliveryFee ?? 0.0;
  double get shopPayAmount => currentOrder?.originalTotalPrice ?? 0.0;
  String get deliveryType =>
      currentOrder?.deliveryType ?? 'ไม่ระบุประเภทการจัดส่ง';
  String get note => currentOrder?.note ?? 'เพิ่มเติม: -';
  double get distance => currentOrder?.distanceKm ?? 0.0;
  List<OrderItem> get orderItems => currentOrder?.items ?? [];
  String get orderNumberDisplay => currentOrder?.orderId.toString() ?? '';
  int get earn => currentOrder != null ? deliveryFee.toInt() : 0;
  double get bonus => currentOrder?.bonus ?? 0.0;

  void _showOrderDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // หัวข้อ dialog
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'ดูรายละเอียดการสั่งซื้อ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ข้อมูลร้านอาหาร
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.restaurant,
                          color: Colors.grey[700],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          restaurantName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'หมายเลขออเดอร์: $orderNumberDisplay',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),

              // รายการอาหาร
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView(
                  padding: const EdgeInsets.all(0),
                  shrinkWrap: true,
                  children: orderItems.map((item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.foodName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (item.selectedOptions.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: item.selectedOptions.map((
                                          option,
                                        ) {
                                          final label =
                                              option['label']?.toString() ?? '';
                                          final extraPrice =
                                              option['extraPrice']
                                                  ?.toString() ??
                                              '0';
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.green.withOpacity(
                                                  0.2,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              '$label (+฿$extraPrice)',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.green[800],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'x${item.quantity}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Text(
                                    '${item.subtotal.toStringAsFixed(0)} บาท',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              // ส่วนล่าง - ราคารวม
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ค่าอาหาร',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          '${(totalPrice - deliveryFee).toStringAsFixed(0)} บาท',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ค่าส่ง (รายได้)',
                          style: TextStyle(fontSize: 16, color: Colors.green),
                        ),
                        Text(
                          '${deliveryFee.toStringAsFixed(0)} บาท',
                          style: TextStyle(fontSize: 16, color: Colors.green),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'รวมทั้งหมด',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          '${totalPrice.toStringAsFixed(0)} บาท',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'จ่ายให้ร้าน',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          '${shopPayAmount.toStringAsFixed(0)} บาท',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
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

  void _showConfirmationDialog(BuildContext context) {
    if (!_canGoToShop()) {
      final marketLocation = currentOrder!.marketLocation;
      final isAdminShop = marketLocation?['owner_id'] == null;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAdminShop
                ? 'ไม่สามารถเดินทางได้ในขณะนี้'
                : 'รอร้านยืนยันออเดอร์ก่อน',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_bike, color: Colors.green, size: 28),
            SizedBox(height: 8),
            Text('ยืนยันการเดินทาง'),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            'คุณต้องการเดินทางไปยังร้านอาหารใช่หรือไม่?',
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            isDefaultAction: false,
            child: Text('ยกเลิก'),
            textStyle: TextStyle(color: Colors.black),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _updateOrderStatus('going_to_shop');
            },
            isDefaultAction: true,
            child: Text('ยืนยัน'),
            textStyle: TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }

  void _showConfirmArrivalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant, color: Colors.green, size: 28),
            SizedBox(height: 6),
            Text('ยืนยันถึงร้านอาหาร'),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            'คุณได้มาถึงร้านอาหารแล้วใช่หรือไม่?',
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            isDefaultAction: false,
            child: Text('ยกเลิก'),
            textStyle: TextStyle(color: Colors.black),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                confirmedArrival = true;
              });
              _updateOrderStatus('arrived_at_shop');
            },
            isDefaultAction: true,
            child: Text('ยืนยัน'),
            textStyle: TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }

  void _showConfirmPickupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(height: 6),
            Text('ยืนยันรับอาหาร'),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            'โปรดตรวจสอบรายการอาหาร\nคุณได้รับอาหารเรียบร้อยแล้วใช่หรือไม่?',
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            isDefaultAction: false,
            child: Text('ยกเลิก'),
            textStyle: TextStyle(color: Colors.black),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                foodReceived = true;
              });
              _updateOrderStatus('picked_up');
            },
            isDefaultAction: true,
            child: Text('ยืนยัน'),
            textStyle: TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }

  void _showConfirmDeliveryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delivery_dining, color: Colors.orange, size: 28),
            SizedBox(height: 6),
            Text('เดินทางไปจุดจัดส่ง'),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            'คุณพร้อมเดินทางไปส่งอาหารให้ลูกค้าใช่หรือไม่?',
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            isDefaultAction: false,
            child: Text('ยกเลิก'),
            textStyle: TextStyle(color: Colors.black),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _updateOrderStatus('delivering');
              Navigator.pushReplacementNamed(
                context,
                '/goCustomer',
                arguments: {
                  'orderId': orderId,
                  'userId': userId,
                  'riderId': riderId,
                  'orderNumber': orderNumberDisplay,
                  'restaurantName': restaurantName,
                  'restaurantAddress': restaurantAddress,
                  'customerName': customerName,
                  'titleCustomerAddress': 'ส่งถึง',
                  'customerAddress': customerAddress,
                  'deliveryType': deliveryType,
                  'note': note,
                  'earn': earn.toDouble(),
                  'payAtShop': shopPayAmount,
                  'bonus': bonus.toDouble(),
                  'totalReceived': (earn + shopPayAmount + bonus).toDouble(),
                  'payType': paymentMethod,
                  'distance': '${distance.toStringAsFixed(1)} กม.',
                  'totalPrice': totalPrice,
                  'deliveryFee': deliveryFee,
                  'customerLat':
                      currentOrder?.customerLocation?['latitude']?.toDouble() ??
                      0.0,
                  'customerLng':
                      currentOrder?.customerLocation?['longitude']
                          ?.toDouble() ??
                      0.0,

                  'orderItems': orderItems
                      .map(
                        (item) => {
                          'orderNumber': orderNumberDisplay,
                          'foodName': item.foodName,
                          'quantity': item.quantity,
                          'selectedOptions': item.selectedOptions,
                          'subtotal': item.subtotal,
                          'additionalNotes': item.additionalNotes,
                        },
                      )
                      .toList(),
                },
              );
            },
            isDefaultAction: true,
            child: Text('ยืนยัน'),
            textStyle: TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(String status) async {
    if (currentOrder == null || _orderController == null) return;

    try {
      final result = await _orderController!.updateOrderStatus(
        currentOrder!.orderId,
        status,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('อัปเดตสถานะสำเร็จ')));
        _loadOrderData();
      } else {
        final errorMessage = result['error'] ?? 'เกิดข้อผิดพลาด';
        final hint = result['hint'] ?? '';

        String displayMessage = errorMessage;
        if (hint.isNotEmpty) {
          displayMessage = hint;
        } else if (errorMessage ==
            'Shop must confirm order before rider can go to shop') {
          displayMessage = 'รอร้านยืนยันออเดอร์ก่อน';
        } else if (errorMessage == 'Shop is not ready for pickup yet') {
          displayMessage = 'รอร้านเตรียมอาหารเสร็จก่อน';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayMessage),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'waiting':
        return 'รอไรเดอร์รับ';
      case 'rider_assigned':
        return 'รับงานแล้ว(รอร้านยืนยัน)';
      case 'confirmed':
        return 'ร้านยืนยันออเดอร์';
      case 'going_to_shop':
        return 'ไรเดอร์กำลังไปร้าน';
      case 'arrived_at_shop':
        return 'ไรเดอร์มาถึงร้านแล้ว';
      case 'picked_up':
        return 'ไรเดอร์ของรับแล้ว';
      case 'delivering':
        return 'กำลังจัดส่ง';
      case 'arrived_at_customer':
        return 'ไรเดอร์มาถึงลูกค้าแล้ว';
      case 'completed':
        return 'จัดส่งเสร็จสิ้น';
      case 'cancelled':
        return 'ยกเลิกแล้ว';
      default:
        return status;
    }
  }

  String _getShopStatusText(String? shopStatus) {
    if (shopStatus == null || shopStatus.isEmpty) return '';
    switch (shopStatus) {
      case 'preparing':
        return 'ร้านกำลังเตรียมอาหาร';
      case 'ready_for_pickup':
        return 'ร้านเตรียมเสร็จแล้ว';
      default:
        return shopStatus;
    }
  }

  String _getCombinedStatusText() {
    if (currentOrder == null) return '';

    final orderStatusText = _getStatusText(currentOrder!.status);
    final shopStatusText = _getShopStatusText(currentOrder!.shopStatus);

    if (shopStatusText.isNotEmpty) {
      return '$orderStatusText • $shopStatusText';
    }
    return orderStatusText;
  }

  bool _canGoToShop() {
    if (currentOrder == null) return false;

    if (currentOrder!.status != 'rider_assigned') {
      return [
        'confirmed',
        'going_to_shop',
        'arrived_at_shop',
        'picked_up',
      ].contains(currentOrder!.status);
    }

    final marketLocation = currentOrder!.marketLocation;
    final isAdminShop = marketLocation?['owner_id'] == null;

    if (isAdminShop) return true;

    return currentOrder!.status == 'confirmed';
  }

  String _getButtonText() {
    final status = currentOrder?.status ?? '';
    switch (status) {
      case 'rider_assigned':
      case 'confirmed':
        return 'เดินทางไปร้านอาหาร';
      case 'going_to_shop':
        return 'ยืนยันถึงร้านอาหาร';
      case 'arrived_at_shop':
        return 'ยืนยันรับอาหาร';
      case 'picked_up':
        return 'เดินทางไปที่จุดจัดส่ง';
      default:
        return 'ดำเนินการต่อ';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 📍 ดึงพิกัดลูกค้าสำหรับแมพ
    final double? customerLat = currentOrder?.customerLocation?['latitude']
        ?.toDouble();
    final double? customerLng = currentOrder?.customerLocation?['longitude']
        ?.toDouble();

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    if (currentOrder == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('รายละเอียดงาน')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text('ไม่พบข้อมูลออเดอร์ #${orderId ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text(
                'Rider ID: ${riderId ?? 'N/A'}',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      setState(() => _isLoading = true);
                      _loadOrderData();
                    },
                    child: const Text('ลองใหม่'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    child: const Text('กลับ'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // ดึงข้อมูล lat/lng สำหรับแมพ
    final marketLocation = currentOrder?.marketLocation;
    final double? latitude = marketLocation?['latitude']?.toDouble();
    final double? longitude = marketLocation?['longitude']?.toDouble();
    final String? phone = marketLocation?['phone']?.toString();

    return Consumer<RiderControllerSocket>(
      builder: (context, controller, _) {
        final updatedOrder = controller.orders
            .where((o) => o.orderId == orderId)
            .firstOrNull;

        if (updatedOrder != null) {
          currentOrder = updatedOrder;
        }

        return WillPopScope(
          onWillPop: () async {
            _loadOrderData();
            Navigator.pop(context, {'refreshData': true});
            return false;
          },
          child: Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Color(0xFF4CAF50),
              elevation: 0,
              leadingWidth: 140,
              toolbarHeight: 40,
              leading: Padding(
                padding: const EdgeInsets.only(left: 20, right: 8),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: Color(0xFFE0E0E0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Text(
                    'ยกเลิกออเดอร์',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton(
                    onPressed: () async {
                      final result = await _orderController!.updateOrderStatus(
                        currentOrder!.orderId,
                        'shop_closed',
                      );
                      if (result['success'] == true) {
                        Navigator.pop(context);
                      }
                    },
                    style: TextButton.styleFrom(
                      side: BorderSide(color: Colors.red, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      minimumSize: Size(0, 36),
                    ),
                    child: Text(
                      'แจ้งร้านปิด',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(12),
                child: SizedBox(height: 12),
              ),
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  // Status Section
                  Container(
                    color: Color(0xFF4CAF50),
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                arrivedAtRestaurant
                                    ? (foodReceived
                                          ? '1. รับอาหารแล้ว ✓'
                                          : (confirmedArrival
                                                ? '1. รับอาหาร'
                                                : '1. ถึงร้านอาหาร'))
                                    : '1. ไปร้าน',
                                style: TextStyle(
                                  color: arrivedAtRestaurant
                                      ? (foodReceived
                                            ? Colors.white
                                            : Colors.green[900])
                                      : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                restaurantName,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(height: 40, width: 2, color: Colors.white30),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '2. ส่งให้ลูกค้า',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                customerName,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status display section
                  const SizedBox(height: 16),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    padding: EdgeInsets.all(6),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.info_outline,
                            color: Colors.green[700],
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(
                                _getCombinedStatusText(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Contact Section
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.restaurant,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ร้านอาหาร',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  restaurantName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Spacer(),
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.facebook,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.phone,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ลูกค้า',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  customerName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Spacer(),
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.phone,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/chat');
                              },
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green[300],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.message,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  // Order Details Button when arrived but not confirmed
                  if (arrivedAtRestaurant && !confirmedArrival)
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => _showOrderDetailsDialog(context),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, color: Colors.grey[700]),
                            SizedBox(width: 8),
                            Text(
                              'ดูรายละเอียด',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.grey[700]),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(height: 16),

                  // Header Section Divider
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: Colors.grey.shade300,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'รายละเอียดออเดอร์',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Order Items Display
                  if (!(arrivedAtRestaurant && !confirmedArrival))
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'หมายเลขออเดอร์: $orderNumberDisplay',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'รายการอาหาร',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${orderItems.length} รายการ',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          ...orderItems.map(
                            (item) => Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.foodName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'x${item.quantity}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                          Text(
                                            '${item.subtotal.toStringAsFixed(0)} บาท',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  if (item.selectedOptions.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.green.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.add_circle_outline,
                                                color: Colors.green[700],
                                                size: 16,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'ตัวเลือกเพิ่มเติม:',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: item.selectedOptions.map((
                                              option,
                                            ) {
                                              final label =
                                                  option['label']?.toString() ??
                                                  '';
                                              final extraPrice =
                                                  option['extraPrice']
                                                      ?.toString() ??
                                                  '0';
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: Colors.green
                                                        .withOpacity(0.4),
                                                    width: 1,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.green
                                                          .withOpacity(0.1),
                                                      blurRadius: 2,
                                                      offset: const Offset(
                                                        0,
                                                        1,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: Text(
                                                  '$label (+฿$extraPrice)',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.green[800],
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  if (item.additionalNotes.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.orange.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.note_alt_outlined,
                                                color: Colors.orange[700],
                                                size: 16,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'หมายเหตุเพิ่มเติม:',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.orange[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            item.additionalNotes,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.orange[800],
                                              height: 1.3,
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
                          SizedBox(height: 8),
                          Divider(),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ค่าอาหาร',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '${(totalPrice - deliveryFee).toStringAsFixed(0)} บาท',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ค่าส่ง (รายได้)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green[600],
                                ),
                              ),
                              Text(
                                '${deliveryFee.toStringAsFixed(0)} บาท',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green[600],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'รวมทั้งหมด',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${totalPrice.toStringAsFixed(0)} บาท',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 20),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.grey.shade300,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  // Restaurant Map Section - แสดงเฉพาะเมื่อยังไม่รับอาหาร
                  if (!foodReceived)
                  
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 24),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            confirmedArrival
                                ? 'รอรับอาหารจากร้าน'
                                : 'ไปร้านอาหาร',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: confirmedArrival
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                          ),
                        ),
                        SizedBox(height: 12),

                        // ✅ ใช้ MapNavigationButton แทน placeholder map
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 16),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                restaurantName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                restaurantAddress,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 12),
                              MapNavigationButton(
                                latitude: latitude,
                                longitude: longitude,
                                locationName: restaurantName,
                                address: restaurantAddress,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                      ],
                    ),

                  // Recommendation Section - แสดงเฉพาะเมื่อยังไม่รับอาหาร
                  if (!foodReceived) ...[
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.grey.shade300,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'ข้อมูลการเดินทาง',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                  ],

                  SizedBox(height: 16),

                  // Customer Map Section - แสดงเฉพาะเมื่อรับอาหารแล้ว
                  if (foodReceived)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'ไปส่งให้ลูกค้า',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 16),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customerName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                customerAddress,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 12),
                              // ✅ ใช้ MapNavigationButton ไปยังลูกค้า
                                MapNavigationButton(
                                  latitude: customerLat,
                                  longitude: customerLng,
                                  locationName: customerName,
                                  address: customerAddress,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  SizedBox(height: 16),
                  SizedBox(height: 80), // Space for bottom navigation
                ],
              ),
            ),

            // Bottom Navigation Bar
            bottomNavigationBar: SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, -2),
                    ),
                  ],
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      padding: EdgeInsets.all(6),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.info_outline,
                              color: Colors.green[700],
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text(
                                  _getCombinedStatusText(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'จ่ายให้ร้าน',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          '${shopPayAmount.toStringAsFixed(0)} บาท',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          final status = currentOrder?.status ?? '';
                          switch (status) {
                            case 'rider_assigned':
                            case 'confirmed':
                              _showConfirmationDialog(context);
                              break;
                            case 'going_to_shop':
                              _showConfirmArrivalDialog(context);
                              break;
                            case 'arrived_at_shop':
                              _showConfirmPickupDialog(context);
                              break;
                            case 'picked_up':
                              _showConfirmDeliveryDialog(context);
                              break;
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          _getButtonText(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ), // ปิด WillPopScope
        );
      },
    );
  }
}

class OrderItemWidget extends StatelessWidget {
  final String name;
  final String option;
  final String description;
  final String quantity;
  final String? price;

  const OrderItemWidget({
    Key? key,
    required this.name,
    required this.option,
    required this.description,
    required this.quantity,
    this.price,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  if (option.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  if (description.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.green.shade200,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        "เพิ่มเติม: " + description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  quantity,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                if (price != null) ...[
                  SizedBox(height: 2),
                  Text(
                    price!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// Extension for firstOrNull (if not available in your Dart version)
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) return null;
    return first;
  }
}
