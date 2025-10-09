import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;

class MapUtils {
  /// คำนวณระยะทางระหว่าง 2 จุด (Haversine formula)
  static double calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371; // กิโลเมตร
    
    double lat1Rad = start.latitude * math.pi / 180;
    double lat2Rad = end.latitude * math.pi / 180;
    double dLat = (end.latitude - start.latitude) * math.pi / 180;
    double dLng = (end.longitude - start.longitude) * math.pi / 180;
    
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// ประมาณเวลาในการเดินทางด้วยมอเตอร์ไซค์ (นาที)
  /// avgSpeed: ความเร็วเฉลี่ย (km/h) - default 40 km/h
  static double estimateDuration(double distanceKm, {double avgSpeed = 40}) {
    return (distanceKm / avgSpeed) * 60;
  }

  /// สร้าง Custom Marker Icon
  static Future<BitmapDescriptor> createCustomMarker({
    required String assetPath,
    int width = 120,
  }) async {
    return await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(width.toDouble(), width.toDouble())),
      assetPath,
    );
  }

  /// เปิด Google Maps Navigation
  static Future<void> openGoogleMapsNavigation({
    required double lat,
    required double lng,
    String travelMode = 'driving', // driving, walking, bicycling, transit
  }) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=$travelMode';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'ไม่สามารถเปิด Google Maps ได้';
    }
  }

  /// เปิด Google Maps แสดงตำแหน่ง
  static Future<void> openGoogleMapsLocation({
    required double lat,
    required double lng,
    String? label,
  }) async {
    final url = label != null
        ? 'https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$label'
        : 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'ไม่สามารถเปิด Google Maps ได้';
    }
  }

  /// เปิดโทรศัพท์
  static Future<void> makePhoneCall(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'ไม่สามารถโทรออกได้';
    }
  }

  /// สร้าง LatLngBounds จาก List ของ LatLng
  static LatLngBounds boundsFromLatLngList(List<LatLng> list) {
    assert(list.isNotEmpty, 'List ต้องไม่ว่าง');
    double? x0, x1, y0, y1;
    
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    
    return LatLngBounds(
      northeast: LatLng(x1!, y1!),
      southwest: LatLng(x0!, y0!),
    );
  }

  /// แปลงเมตรเป็นข้อความที่อ่านง่าย
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} ม.';
    } else {
      return '${(meters / 1000).toStringAsFixed(2)} กม.';
    }
  }

  /// แปลงนาทีเป็นข้อความที่อ่านง่าย
  static String formatDuration(double minutes) {
    if (minutes < 60) {
      return '${minutes.toStringAsFixed(0)} นาที';
    } else {
      int hours = (minutes / 60).floor();
      int mins = (minutes % 60).round();
      return '$hours ชั่วโมง $mins นาที';
    }
  }

  /// ตรวจสอบว่าถึงปลายทางแล้วหรือยัง
  /// threshold: ระยะทางขั้นต่ำที่ถือว่าถึง (เมตร)
  static bool hasArrived(
    LatLng current,
    LatLng destination, {
    double threshold = 50,
  }) {
    double distance = calculateDistance(current, destination) * 1000; // แปลงเป็นเมตร
    return distance <= threshold;
  }

  /// สร้าง Polyline style สำหรับเส้นทาง
  static Polyline createRoutePolyline({
    required String id,
    required List<LatLng> points,
    int width = 5,
    bool isDashed = false,
  }) {
    return Polyline(
      polylineId: PolylineId(id),
      color: const Color(0xFF2196F3),
      width: width,
      points: points,
      patterns: isDashed
          ? [PatternItem.dash(20), PatternItem.gap(10)]
          : [],
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      jointType: JointType.round,
    );
  }

  /// สร้าง Circle สำหรับแสดงรัศมีรอบตำแหน่ง
  static Circle createRadiusCircle({
    required String id,
    required LatLng center,
    double radius = 100, // เมตร
  }) {
    return Circle(
      circleId: CircleId(id),
      center: center,
      radius: radius,
      fillColor: const Color(0xFF4CAF50).withOpacity(0.2),
      strokeColor: const Color(0xFF4CAF50),
      strokeWidth: 2,
    );
  }
}