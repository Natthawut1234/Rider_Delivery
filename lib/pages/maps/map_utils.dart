// lib/map_utils.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class NavigationStep {
  final String instruction;
  final LatLng position;
  final double distance;
  NavigationStep({
    required this.instruction,
    required this.position,
    required this.distance,
  });
}

class DirectionsResult {
  final List<LatLng> routePoints;
  final List<NavigationStep> steps;
  final double distanceKm;
  final double durationMin;
  DirectionsResult({
    required this.routePoints,
    required this.steps,
    required this.distanceKm,
    required this.durationMin,
  });
}

class MapUtils {
  // -------------------- Permissions / Location --------------------
  static Future<Position> getCurrentPosition() {
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  static Future<void> ensureLocationServiceAndPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('LOCATION_SERVICE_DISABLED');
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('LOCATION_PERMISSION_DENIED');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('LOCATION_PERMISSION_DENIED_FOREVER');
    }
  }

  // ✅ GPS Stream แบบ Google Maps: ใช้ทุกเซนเซอร์ + ความถี่สูง
  static Stream<Position> positionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation, // ใช้ GPS + Wi-Fi + Cell + Sensor
        distanceFilter: 0,           // อัปเดตทุกการเคลื่อนไหว (ไม่มี threshold)
        timeLimit: Duration(seconds: 30),
      ),
    );
  }

  // ✅ Snap-to-route แบบฉลาด: ดึงตำแหน่งกลับเข้าเส้นทางถ้าอยู่ใกล้
  static LatLng? snapToRoute(
    LatLng current,
    List<LatLng> route, {
    double maxSnapDistMeters = 25,
  }) {
    if (route.isEmpty) return null;

    LatLng? closest;
    double minDist = double.infinity;

    // หาจุดใกล้ที่สุดบนเส้นทาง
    for (int i = 0; i < route.length - 1; i++) {
      final projected = _projectPointOnSegment(current, route[i], route[i + 1]);
      final dist = Geolocator.distanceBetween(
        current.latitude,
        current.longitude,
        projected.latitude,
        projected.longitude,
      );

      if (dist < minDist) {
        minDist = dist;
        closest = projected;
      }
    }

    // ถ้าใกล้พอ (< maxSnapDistMeters) ให้ snap, ไม่งั้นใช้ตำแหน่งจริง
    if (closest != null && minDist <= maxSnapDistMeters) {
      return closest;
    }
    return null;
  }

  // ฉายจุดลงบนส่วนของเส้น (perpendicular projection)
  static LatLng _projectPointOnSegment(LatLng p, LatLng a, LatLng b) {
    final latAvg = (a.latitude + b.latitude) / 2.0;
    const mPerDegLat = 111132.92;
    final mPerDegLng = 111412.84 * math.cos(latAvg * math.pi / 180);

    final ax = a.longitude * mPerDegLng, ay = a.latitude * mPerDegLat;
    final bx = b.longitude * mPerDegLng, by = b.latitude * mPerDegLat;
    final px = p.longitude * mPerDegLng, py = p.latitude * mPerDegLat;

    final abx = bx - ax, aby = by - ay;
    final apx = px - ax, apy = py - ay;
    final ab2 = abx * abx + aby * aby;

    double t = ab2 == 0 ? 0 : (apx * abx + apy * aby) / ab2;
    t = t.clamp(0.0, 1.0);

    final projX = ax + abx * t;
    final projY = ay + aby * t;

    return LatLng(
      projY / mPerDegLat,
      projX / mPerDegLng,
    );
  }

  // ✅ Smooth Camera แบบ Google Maps: ขยับกล้องแบบ bezier curve
  static Future<void> smoothCameraTo({
    required GoogleMapController controller,
    required LatLng target,
    required double zoom,
    required double tilt,
    required double bearing,
    int durationMs = 900,
  }) async {
    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: target,
            zoom: zoom,
            tilt: tilt,
            bearing: bearing,
          ),
        ),
      );
    } catch (_) {
      // fallback: ถ้า animate ไม่ได้ ให้ move ทันที
      controller.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: target,
            zoom: zoom,
            tilt: tilt,
            bearing: bearing,
          ),
        ),
      );
    }
  }

  // -------------------- Directions API --------------------
  static Future<DirectionsResult> fetchDirections({
    required String apiKey,
    required LatLng origin,
    required LatLng destination,
    String mode = 'driving',
    String language = 'th',
  }) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&mode=$mode&language=$language&key=$apiKey',
    );

    final res = await http.get(url);
    final data = json.decode(res.body);
    if (data['status'] != 'OK') {
      throw Exception('Directions error: ${data['status']}');
    }

    final route = data['routes'][0];
    final leg = route['legs'][0];

    final polyline = route['overview_polyline']['points'];
    final decoded = PolylinePoints.decodePolyline(polyline);
    final routePoints = decoded
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList(growable: false);

    final steps = <NavigationStep>[];
    for (final step in leg['steps']) {
      final end = step['end_location'];
      steps.add(
        NavigationStep(
          instruction: stripHtml(step['html_instructions'] ?? ''),
          position: LatLng(end['lat'], end['lng']),
          distance: (step['distance']['value'] ?? 0).toDouble(),
        ),
      );
    }

    final distanceKm = (leg['distance']['value'] ?? 0) / 1000.0;
    final durationMin = (leg['duration']['value'] ?? 0) / 60.0;

    return DirectionsResult(
      routePoints: routePoints,
      steps: steps,
      distanceKm: distanceKm,
      durationMin: durationMin,
    );
  }

  static String stripHtml(String html) =>
      html.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ');

  // -------------------- Geometry / Bearing --------------------
  static double calculateBearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLon = (lon2 - lon1) * math.pi / 180;
    final lat1Rad = lat1 * math.pi / 180;
    final lat2Rad = lat2 * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2Rad);
    final x =
        math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(dLon);
    final b = math.atan2(y, x) * 180 / math.pi;
    return (b + 360) % 360;
  }

  static double shortestBearingDelta(double from, double to) {
    double diff = (to - from);
    while (diff > 180) diff -= 360;
    while (diff < -180) diff += 360;
    return diff;
  }

  static double normalizeBearing(double b) {
    while (b < 0) b += 360;
    while (b >= 360) b -= 360;
    return b;
  }

  static int findNearestPointOnRoute(LatLng p, List<LatLng> route) {
    double minD = double.infinity;
    int idx = 0;
    for (int i = 0; i < route.length; i++) {
      final d = Geolocator.distanceBetween(
        p.latitude,
        p.longitude,
        route[i].latitude,
        route[i].longitude,
      );
      if (d < minD) {
        minD = d;
        idx = i;
      }
    }
    return idx;
  }

  static double distancePointToSegment(LatLng p, LatLng a, LatLng b) {
    final latAvg = (a.latitude + b.latitude) / 2.0;
    const mPerDegLat = 111132.92;
    final mPerDegLng = 111412.84 * math.cos(latAvg * math.pi / 180);

    final ax = a.longitude * mPerDegLng, ay = a.latitude * mPerDegLat;
    final bx = b.longitude * mPerDegLng, by = b.latitude * mPerDegLat;
    final px = p.longitude * mPerDegLng, py = p.latitude * mPerDegLat;

    final abx = bx - ax, aby = by - ay;
    final apx = px - ax, apy = py - ay;
    final ab2 = abx * abx + aby * aby;
    double t = ab2 == 0 ? 0 : (apx * abx + apy * aby) / ab2;
    t = t.clamp(0, 1);
    final cx = ax + abx * t, cy = ay + aby * t;
    final dx = px - cx, dy = py - cy;
    return math.sqrt(dx * dx + dy * dy);
  }

  static double distanceToPolylineMeters(LatLng p, List<LatLng> line) {
    double minD = double.infinity;
    for (int i = 0; i < line.length - 1; i++) {
      minD = math.min(minD, distancePointToSegment(p, line[i], line[i + 1]));
    }
    return minD;
  }

  // -------------------- Camera helpers --------------------
  static Future<void> animateFollowCamera({
    required GoogleMapController controller,
    required LatLng target,
    required double zoom,
    required double tilt,
    required double bearing,
  }) {
    return controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: zoom,
          tilt: tilt,
          bearing: bearing,
        ),
      ),
    );
  }

  static LatLngBounds boundsFromLatLngList(List<LatLng> list) {
    assert(list.isNotEmpty, 'List must not be empty');
    double? x0, x1, y0, y1;
    for (final latLng in list) {
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

  // ✅ Adaptive Zoom: ปรับ zoom ตามความเร็วและทางโค้ง
  static double zoomBySpeedAndTurn({
    required double kmh,
    required LatLng? current,
    required List<NavigationStep> steps,
    required int currentStep,
  }) {
    // เริ่มจาก base zoom ตามความเร็ว
    double baseZoom;
    if (kmh >= 100) baseZoom = 15.5;      // ทางด่วน — zoom out เพื่อเห็นเส้นทางไกล
    else if (kmh >= 80) baseZoom = 16.0;
    else if (kmh >= 60) baseZoom = 16.5;
    else if (kmh >= 40) baseZoom = 17.5;
    else if (kmh >= 20) baseZoom = 18.0;
    else baseZoom = 18.5;                 // หยุดนิ่ง — zoom in ใกล้

    // ปรับเพิ่มถ้ากำลังจะเลี้ยว (เพื่อให้เห็นทางชัดขึ้น)
    if (current != null && steps.isNotEmpty && currentStep < steps.length) {
      final step = steps[currentStep];
      final dist = Geolocator.distanceBetween(
        current.latitude,
        current.longitude,
        step.position.latitude,
        step.position.longitude,
      );
      if (dist < 150) {
        baseZoom += 0.5; // ใกล้จุดเลี้ยว → zoom in เล็กน้อย
      }
    }

    return baseZoom.clamp(14.0, 19.5);
  }

  // ✅ Adaptive Tilt: ปรับมุมกล้องตามบริบท
  static double tiltByContext({
    required double kmh,
    required LatLng? current,
    required List<NavigationStep> steps,
    required int currentStep,
  }) {
    double tilt;
    if (kmh >= 80)
      tilt = 70;      // เร็วมาก — เงยสูงเพื่อเห็นไกล
    else if (kmh >= 60)
      tilt = 65;
    else if (kmh >= 40)
      tilt = 60;
    else if (kmh >= 20)
      tilt = 55;
    else
      tilt = 50;      // หยุด — เงยต่ำ

    // ใกล้จุดเลี้ยว → ลด tilt เพื่อเห็นแผนที่แนวนอนชัดขึ้น
    if (current != null && steps.isNotEmpty && currentStep < steps.length) {
      final step = steps[currentStep];
      final d = Geolocator.distanceBetween(
        current.latitude,
        current.longitude,
        step.position.latitude,
        step.position.longitude,
      );
      if (d < 120) {
        tilt -= 10; // ใกล้เลี้ยว → ลดมุมกล้อง
      }
    }

    return tilt.clamp(40.0, 75.0);
  }

  // -------------------- Markers / Polylines --------------------
  static Marker buildCurrentMarker({
    required LatLng position,
    required double rotation,
    BitmapDescriptor? icon,
  }) {
    return Marker(
      markerId: const MarkerId('current'),
      position: position,
      icon:
          icon ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      anchor: const Offset(0.5, 0.5),
      rotation: rotation,
      flat: true,
      infoWindow: const InfoWindow(title: 'ตำแหน่งของคุณ'),
    );
  }

  static Future<BitmapDescriptor> createMotorcycleMarker({
    Color startColor = const Color(0xFFFF8A80),
    Color endColor = const Color(0xFFD50000),
  }) async {
    const double size = 128.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 10);

    final strokePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final gradientPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, size),
        [startColor, endColor],
      );

    final path = Path()
      ..moveTo(size / 2, 0)
      ..quadraticBezierTo(size * 0.55, size * 0.4, size * 0.75, size * 0.65)
      ..quadraticBezierTo(size / 2, size * 0.8, size / 2, size)
      ..quadraticBezierTo(size / 2, size * 0.8, size * 0.25, size * 0.65)
      ..quadraticBezierTo(size * 0.45, size * 0.4, size / 2, 0)
      ..close();

    canvas.drawPath(path.shift(const Offset(0, 4)), shadowPaint);
    canvas.drawPath(path, gradientPaint);
    canvas.drawPath(path, strokePaint);

    final pic = recorder.endRecording();
    final img = await pic.toImage(size.toInt(), size.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  static Future<BitmapDescriptor> createPinMarker(
    Color color,
    double size,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size / 2, size)
      ..quadraticBezierTo(size * 0.2, size * 0.6, size * 0.2, size * 0.4)
      ..arcToPoint(
        Offset(size * 0.8, size * 0.4),
        radius: Radius.circular(size * 0.3),
      )
      ..quadraticBezierTo(size * 0.8, size * 0.6, size / 2, size)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawCircle(
      Offset(size / 2, size * 0.4),
      size * 0.2,
      Paint()..color = Colors.white,
    );

    final pic = recorder.endRecording();
    final img = await pic.toImage(size.toInt(), size.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  static Polyline buildRoutePolyline({
    required String id,
    required List<LatLng> points,
    required bool navigating,
  }) {
    return Polyline(
      polylineId: PolylineId(id),
      color: navigating ? Colors.blue : Colors.blue.shade600,
      width: navigating ? 7 : 6,
      points: points,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      jointType: JointType.round,
      geodesic: true,
    );
  }

  static Polyline buildRouteShadow({required List<LatLng> points}) {
    return Polyline(
      polylineId: const PolylineId('route_shadow'),
      color: Colors.blue.withOpacity(0.25),
      width: 12,
      points: points,
      geodesic: true,
    );
  }

  // -------------------- Text / Time helpers --------------------
  static int remainingMinutesNumeric({
    required double? durationMin,
    required DateTime? navStartTime,
    required double currentKmh,
    required double? totalKm,
    required double traveledMeters,
  }) {
    if (durationMin == null) return 0;
    if (navStartTime != null && currentKmh > 0) {
      final remainingKm = (totalKm ?? 0) - (traveledMeters / 1000);
      final kmph = currentKmh.clamp(1, 150);
      final hours = remainingKm / kmph;
      return (hours * 60).clamp(0, 24 * 60).round();
    }
    return durationMin.round();
  }

  static String humanRemainingTime(int minutes) {
    if (minutes > 60) {
      final h = (minutes / 60).floor();
      final m = minutes % 60;
      return '$h ชม. $m นาที';
    }
    return '$minutes นาที';
  }

  static String navText(String direction, double distance) {
    String t;
    if (distance < 50)
      t = 'เร็วๆ นี้';
    else if (distance < 200)
      t = 'อีก ${distance.toInt()} ม.';
    else if (distance < 1000)
      t = 'อีก ${(distance / 100).round() * 100} ม.';
    else
      t = 'อีก ${(distance / 1000).toStringAsFixed(1)} กม.';
    return '$direction $t';
  }

  // -------------------- External maps --------------------
  static Future<void> openGoogleMapsAppOrWeb({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final iosGoogle = Uri.parse(
      'comgooglemaps://?saddr=${origin.latitude},${origin.longitude}'
      '&daddr=${destination.latitude},${destination.longitude}&directionsmode=driving',
    );
    final androidIntent = Uri.parse(
      'google.navigation:q=${destination.latitude},${destination.longitude}&mode=l',
    );
    final webUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&travelmode=driving',
    );

    try {
      if (await canLaunchUrl(androidIntent)) {
        await launchUrl(androidIntent, mode: LaunchMode.externalApplication);
        return;
      }
      if (await canLaunchUrl(iosGoogle)) {
        await launchUrl(iosGoogle, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}
    await launchUrl(webUrl, mode: LaunchMode.externalApplication);
  }

  // -------------------- Haptics --------------------
  static void bump() => HapticFeedback.mediumImpact();
  static void boom() => HapticFeedback.heavyImpact();
}