import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io' show Platform;

class MapNavigationPage extends StatefulWidget {
  const MapNavigationPage({Key? key}) : super(key: key);

  @override
  State<MapNavigationPage> createState() => _MapNavigationPageState();
}

class _MapNavigationPageState extends State<MapNavigationPage>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  LatLng? _destinationPosition;
  String? _destinationName;
  String? _destinationAddress;

  // ===== Smooth Movement Animation =====
  late AnimationController _markerAnimationController;
  Animation<double>? _markerAnimation;
  LatLng? _animationStartPos;
  LatLng? _animationEndPos;

  // ===== Follow/lock like Google Maps =====
  Timer? _autoRecenterTimer;
  bool _followLock =
      true; // โหมดล็อคติดตาม: เลื่อนแผนที่พักหนึ่งแล้วจะเด้งกลับมาตามอัตโนมัติ

  // ETA helper
  int _remainingMinutesNumeric() {
    if (_duration == null) return 0;
    if (_navigationStartTime != null && _currentSpeed > 0) {
      final remainingKm = (_distance ?? 0) - (_traveledDistance / 1000);
      final kmph = _currentSpeed.clamp(1, 150);
      final hours = remainingKm / kmph;
      return (hours * 60).clamp(0, 24 * 60).round();
    }
    return _duration!.round();
  }

  // Map & route data
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  final Set<Polyline> _progressPolylines = {}; // เส้น “ที่ขับมา”
  final List<LatLng> _polylineCoordinates = [];
  late final PolylinePoints _polylinePoints;

  double? _distance;
  double? _duration;
  bool _isLoading = true;
  StreamSubscription<Position>? _positionSubscription;

  // Navigation mode
  bool _isNavigating = false;
  double _currentBearing = 0.0;
  double _lastBearing = 0.0;
  String _navigationInstruction = 'เริ่มต้นการนำทาง';
  double? _nextTurnDistance;
  String _nextStreetName = '';
  int _currentStep = 0;
  final List<NavigationStep> _navigationSteps = [];

  // Animations
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Travel data
  DateTime? _navigationStartTime;
  double _traveledDistance = 0.0;
  LatLng? _lastPosition;
  double _currentSpeed = 0.0;

  // Custom markers
  BitmapDescriptor? _motorcycleIcon;
  BitmapDescriptor? _destinationIcon;

  // Camera control
  bool _followUser = true;
  bool _isUserGesture = false;
  double _currentZoom = 18.0;
  Timer? _camThrottle;
  Duration _camInterval = const Duration(milliseconds: 330);
  double _targetTilt = 45;
  double _targetZoom = 18;

  // Voice
  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;

  // Off-route detect
  int _offRouteStrikes = 0;
  final int _offRouteStrikeLimit = 3;
  double _offRouteThresholdM = 35;

  // Voice stage per step
  final Set<int> _spokenStageForStep = {};

  // Google Maps API Key
  final String _googleApiKey =
      ''; // **สำคัญ:** ควรจัดเก็บ API Key อย่างปลอดภัย

  @override
  void initState() {
    super.initState();
    _polylinePoints = PolylinePoints(apiKey: _googleApiKey);
    _initializeAnimations();
    _loadCustomMarkers();
    _initTts();
    _initializeLocation();
    _markerAnimationController = AnimationController(
      duration: const Duration(
        milliseconds: 800,
      ), // ระยะเวลาในการเคลื่อนที่จากจุด A ไป B
      vsync: this,
    );
  }

  // -------------------- Init helpers --------------------
  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadCustomMarkers() async {
    _motorcycleIcon = await _createMotorcycleMarker();
    _destinationIcon = await _createPinMarker(Colors.red, 48);
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage("th-TH");
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      _ttsReady = true;
    } catch (_) {
      _ttsReady = false;
    }
  }

  Future<void> _speak(String text) async {
    if (!_ttsReady) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  // -------------------- Custom markers --------------------
  Future<BitmapDescriptor> _createMotorcycleMarker() async {
    // 💡 1. เพิ่มขนาดให้ใหญ่และเด่นชัดขึ้น
    const double size = 128.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 💡 2. สร้าง Paint สำหรับแต่ละส่วนประกอบ
    // Paint สำหรับเงา
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 10);

    // Paint สำหรับเส้นขอบ
    final strokePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // Paint สำหรับตัวลูกศรหลัก (ใช้ Gradient)
    final gradientPaint = Paint()
      ..shader = ui.Gradient.linear(const Offset(0, 0), Offset(0, size), [
        Colors.lightBlue.shade300,
        Colors.blue.shade800,
      ]);

    // 💡 3. วาดรูปทรงลูกศรแบบใหม่ (ทรง Kite)
    final path = Path()
      ..moveTo(size / 2, 0) // ยอดบนสุด
      ..quadraticBezierTo(
        size * 0.55,
        size * 0.4,
        size * 0.75,
        size * 0.65,
      ) // โค้งขวาบน
      ..quadraticBezierTo(size / 2, size * 0.8, size / 2, size) // โค้งลงล่าง
      ..quadraticBezierTo(
        size / 2,
        size * 0.8,
        size * 0.25,
        size * 0.65,
      ) // โค้งซ้ายล่าง
      ..quadraticBezierTo(
        size * 0.45,
        size * 0.4,
        size / 2,
        0,
      ) // โค้งกลับไปที่ยอด
      ..close();

    // 💡 4. วาดส่วนประกอบต่างๆ ลงบน Canvas (จากหลังมาหน้า)
    // วาดเงาก่อน (อยู่ชั้นล่างสุด)
    canvas.drawPath(path.shift(const Offset(0, 4)), shadowPaint);

    // วาดตัวลูกศรที่ไล่ระดับสี
    canvas.drawPath(path, gradientPaint);

    // วาดเส้นขอบสีขาวทับ (อยู่ชั้นบนสุด)
    canvas.drawPath(path, strokePaint);

    // แปลง Canvas เป็น BitmapDescriptor
    final pic = recorder.endRecording();
    final img = await pic.toImage(size.toInt(), size.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  Future<BitmapDescriptor> _createPinMarker(Color color, double size) async {
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

  // -------------------- Route args --------------------
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      final lat = args['destinationLat'] as double?;
      final lng = args['destinationLng'] as double?;
      if (lat != null && lng != null) {
        _destinationPosition = LatLng(lat, lng);
        _destinationName = args['destinationName'] as String?;
        _destinationAddress = args['destinationAddress'] as String?;
        if (_currentPosition != null) _getDirections();
      }
    }
  }

  // -------------------- Location --------------------
  Future<void> _initializeLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoading = false);
        _showLocationServiceDialog();
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
          _showPermissionDeniedDialog();
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        _showPermissionDeniedForeverDialog();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      if (_currentPosition == null) {
        _currentPosition = LatLng(pos.latitude, pos.longitude);
        _lastPosition = _currentPosition;
        _currentBearing = pos.heading;
        _lastBearing = pos.heading;
      }
      _isLoading = false;
      _addMarkers(); // ✅ ทำแค่ครั้งแรก
      _startLocationTracking(); // ✅ ให้ตัวนี้อัปเดตจริงจาก GPS
      if (_destinationPosition != null)
        _getDirections(); // ✅ โหลดเส้นทางครั้งแรกเท่านั้น
      setState(() {});

      _addMarkers();
      if (_destinationPosition != null) _getDirections();
      _startLocationTracking();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('เกิดข้อผิดพลาดในการเข้าถึงตำแหน่ง');
    }
  }

  void _startLocationTracking() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: settings).listen((
          position,
        ) {
          final newPos = LatLng(position.latitude, position.longitude);

          final newBearing = position.heading;
          _smoothBearingUpdate(newBearing);

          _animationStartPos = _currentPosition;
          _animationEndPos = newPos;

          if (_animationStartPos == null) {
            setState(() {
              _currentPosition = newPos;
            });
            return;
          }

          _markerAnimation =
              Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _markerAnimationController,
                  curve: Curves.linear,
                ),
              )..addListener(() {
                if (_animationStartPos != null && _animationEndPos != null) {
                  final lat = ui.lerpDouble(
                    _animationStartPos!.latitude,
                    _animationEndPos!.latitude,
                    _markerAnimation!.value,
                  );
                  final lng = ui.lerpDouble(
                    _animationStartPos!.longitude,
                    _animationEndPos!.longitude,
                    _markerAnimation!.value,
                  );

                  setState(() {
                    _currentPosition = LatLng(lat!, lng!);
                    _updateCurrentLocationMarker(_currentPosition!);

                    // ✅ update UI แบบเบา ๆ ด้วย WidgetsBinding
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_isNavigating && _followUser) {
                        _mapController?.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(
                              target: _currentPosition!,
                              zoom: _targetZoom,
                              tilt: _targetTilt,
                              bearing: _currentBearing,
                            ),
                          ),
                        );
                      }
                    });

                    if (_isNavigating) {
                      _updateProgressPolyline(); // ✅ อัปเดตเส้นทางที่วิ่งมาแล้ว
                      _updateNavigationInstructions(); // ✅ อัปเดตข้อความนำทาง
                      _maybeSpeakForStep(); // ✅ สั่งเสียงเตือนระยะเลี้ยว
                      _checkForNextStep(); // ✅ เปลี่ยน step เมื่อถึงจุดเลี้ยว
                      _recalcIfOffRoute(); // ✅ ตรวจหลุดเส้นทางแล้วคำนวณใหม่
                      if (_isNearDestination()) {
                        // ✅ ถึงปลายทาง
                        _showArrivalNotification();
                        _stopNavigation();
                      }
                    }
                  });

                  // ✅ กล้องตามแบบ realtime ทุกเฟรม
                  if (_isNavigating && _followUser) {
                    _mapController?.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: _currentPosition!,
                          zoom: _targetZoom,
                          tilt: _targetTilt,
                          bearing:
                              _currentBearing, // ✅ ใช้ bearing ที่อัปเดตใหม่
                        ),
                      ),
                    );
                  }
                }
              });

          _markerAnimationController.forward(from: 0.0);
        });
  }

  // -------------------- Helpers --------------------
  int _findNearestPointOnRoute(LatLng p) {
    double minD = double.infinity;
    int idx = 0;
    for (int i = 0; i < _polylineCoordinates.length; i++) {
      final d = Geolocator.distanceBetween(
        p.latitude,
        p.longitude,
        _polylineCoordinates[i].latitude,
        _polylineCoordinates[i].longitude,
      );
      if (d < minD) {
        minD = d;
        idx = i;
      }
    }
    return idx;
  }

  void _smoothBearingUpdate(double newBearing) {
    double diff = newBearing - _lastBearing;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;

    if (diff.abs() < 45) {
      _currentBearing = _lastBearing + diff * 0.3;
    } else {
      _currentBearing = newBearing;
    }
    _lastBearing = _normalizeBearing(_currentBearing);
  }

  void _smoothCameraUpdate() {
    _camThrottle?.cancel();
    _camThrottle = Timer(_camInterval, () async {
      if (_mapController == null || _currentPosition == null) return;
      if (!_followUser || _isUserGesture) return;

      double bearing = _currentBearing;
      if (_navigationSteps.isNotEmpty &&
          _currentStep < _navigationSteps.length) {
        final step = _navigationSteps[_currentStep];
        bearing = _calculateBearing(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          step.position.latitude,
          step.position.longitude,
        );
        final delta = _shortestBearingDelta(_lastBearing, bearing);
        if (delta.abs() < 8)
          bearing = _lastBearing;
        else
          bearing = _normalizeBearing(_lastBearing + delta * 0.35);
      }
      _lastBearing = bearing;

      _targetZoom = _zoomBySpeedAndTurn();
      _targetTilt = _tiltByContext();

      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentPosition!,
            zoom: _targetZoom,
            tilt: _targetTilt,
            bearing: bearing,
          ),
        ),
      );
    });
  }

  double _zoomBySpeedAndTurn() {
    double z;
    if (_currentSpeed >= 60)
      z = 16.0;
    else if (_currentSpeed >= 40)
      z = 17.0;
    else if (_currentSpeed >= 20)
      z = 18.0;
    else
      z = 19.0;

    if (_navigationSteps.isNotEmpty && _currentStep < _navigationSteps.length) {
      final step = _navigationSteps[_currentStep];
      final d = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        step.position.latitude,
        step.position.longitude,
      );
      if (d < 120) z = math.max(z, 18.5);
    }
    return z.clamp(14.0, 20.5);
  }

  double _tiltByContext() {
    if (_currentSpeed >= 50) return 55;
    if (_currentSpeed >= 25) return 50;
    if (_navigationSteps.isNotEmpty && _currentStep < _navigationSteps.length) {
      final step = _navigationSteps[_currentStep];
      final d = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        step.position.latitude,
        step.position.longitude,
      );
      if (d < 60) return 42;
    }
    return 45;
  }

  double _shortestBearingDelta(double from, double to) {
    double diff = (to - from);
    while (diff > 180) diff -= 360;
    while (diff < -180) diff += 360;
    return diff;
  }

  double _normalizeBearing(double b) {
    while (b < 0) b += 360;
    while (b >= 360) b -= 360;
    return b;
  }

  // -------------------- Steps / Voice --------------------
  void _maybeSpeakForStep() {
    if (!_isNavigating || _currentPosition == null || _navigationSteps.isEmpty)
      return;
    if (_currentStep >= _navigationSteps.length) return;

    final step = _navigationSteps[_currentStep];
    final d = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      step.position.latitude,
      step.position.longitude,
    );

    final sid = _currentStep * 100000;
    if (d > 280 && d <= 450 && !_spokenStageForStep.contains(sid + 400)) {
      _spokenStageForStep.add(sid + 400);
      _speak('${step.instruction} อีกสี่ร้อยเมตร');
    } else if (d > 120 &&
        d <= 220 &&
        !_spokenStageForStep.contains(sid + 200)) {
      _spokenStageForStep.add(sid + 200);
      _speak('${step.instruction} อีกสองร้อยเมตร');
    } else if (d > 40 && d <= 90 && !_spokenStageForStep.contains(sid + 80)) {
      _spokenStageForStep.add(sid + 80);
      _speak('${step.instruction} อีกแปดสิบเมตร');
    } else if (d <= 25 && !_spokenStageForStep.contains(sid + 0)) {
      _spokenStageForStep.add(sid + 0);
      _speak('ถึงจุดเลี้ยว ${step.instruction} ตอนนี้');
    }
  }

  void _checkForNextStep() {
    if (_navigationSteps.isEmpty || _currentPosition == null) return;
    if (_currentStep < _navigationSteps.length) {
      final step = _navigationSteps[_currentStep];
      final d = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        step.position.latitude,
        step.position.longitude,
      );
      if (d < 30 && _currentStep < _navigationSteps.length - 1) {
        setState(() {
          _currentStep++;
          _spokenStageForStep.clear();
          HapticFeedback.mediumImpact();
        });
        if (_currentStep < _navigationSteps.length) {
          _speak('จากนั้น ${_navigationSteps[_currentStep].instruction}');
        }
      }
    }
  }

  // -------------------- Markers / Polylines --------------------
  void _updateCurrentLocationMarker(LatLng position) {
    final currentMarker = Marker(
      markerId: const MarkerId('current'),
      position: position,
      icon:
          _motorcycleIcon ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      anchor: const Offset(0.5, 0.5),
      rotation: _currentBearing,
      flat: true,
      infoWindow: const InfoWindow(title: 'ตำแหน่งของคุณ'),
    );

    // ✅ ไม่ใช้ setState แต่ปรับค่าโดยตรง แล้วให้ GoogleMap อ่านค่าใหม่เอง
    final newMarkers = Set<Marker>.from(_markers)
      ..removeWhere((m) => m.markerId.value == 'current')
      ..add(currentMarker);
    _markers = newMarkers;
  }

  void _addMarkers() {
    _markers.clear();
    if (_currentPosition != null) {
      _updateCurrentLocationMarker(_currentPosition!);
    }
    if (_destinationPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destinationPosition!,
          icon:
              _destinationIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: _destinationName ?? 'ปลายทาง',
            snippet: _destinationAddress,
          ),
        ),
      );
    }
    setState(() {});
  }

  Future<void> _getDirections() async {
    if (_currentPosition == null || _destinationPosition == null) return;

    _polylineCoordinates.clear();
    _polylines.clear();
    _navigationSteps.clear();
    _progressPolylines.clear();

    try {
      final result = await _polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          destination: PointLatLng(
            _destinationPosition!.latitude,
            _destinationPosition!.longitude,
          ),
          mode: TravelMode.driving,
          optimizeWaypoints: true,
        ),
      );

      if (result.points.isNotEmpty) {
        double total = 0;
        for (int i = 0; i < result.points.length - 1; i++) {
          final a = result.points[i], b = result.points[i + 1];
          total += Geolocator.distanceBetween(
            a.latitude,
            a.longitude,
            b.latitude,
            b.longitude,
          );
          _polylineCoordinates.add(LatLng(a.latitude, a.longitude));
        }
        _polylineCoordinates.add(
          LatLng(result.points.last.latitude, result.points.last.longitude),
        );

        setState(() {
          _distance = total / 1000;
          _duration = (_distance! / 40) * 60;
        });

        _createNavigationSteps();
        _drawPolylines();
        if (!_isNavigating) _fitMapBounds();
      }
    } catch (e) {
      _showErrorSnackBar('ไม่สามารถโหลดเส้นทางได้');
    }
  }

  void _drawPolylines() {
    setState(() {
      _polylines.clear();

      // เงา/พื้นหลัง
      if (_isNavigating) {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route_shadow'),
            color: Colors.blue.withOpacity(0.25),
            width: 12,
            points: _polylineCoordinates,
            geodesic: true,
          ),
        );
      }

      // เส้น "ที่ยังเหลือ" (หลัก)
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          color: _isNavigating ? Colors.blue : Colors.blue.shade600,
          width: _isNavigating ? 7 : 6,
          points: _polylineCoordinates,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
          geodesic: true,
        ),
      );

      // เส้น "ที่ขับมาแล้ว" (ทับด้านบนให้เห็นชัด)
      _polylines.addAll(_progressPolylines);
    });
  }

  void _createNavigationSteps() {
    if (_polylineCoordinates.isEmpty) return;
    _navigationSteps.clear();

    for (int i = 0; i < _polylineCoordinates.length; i += 30) {
      String instruction = 'ตรงไป';
      if (i > 0 && i < _polylineCoordinates.length - 1) {
        final b = _calculateBearing(
          _polylineCoordinates[i - 1].latitude,
          _polylineCoordinates[i - 1].longitude,
          _polylineCoordinates[i + 1].latitude,
          _polylineCoordinates[i + 1].longitude,
        );
        instruction = _getDirectionFromBearing(b);
      }
      _navigationSteps.add(
        NavigationStep(
          instruction: instruction,
          position: _polylineCoordinates[i],
          distance: 0,
        ),
      );
    }
  }

  // -------------------- Nav text --------------------
  void _updateNavigationInstructions() {
    if (_currentPosition == null || _navigationSteps.isEmpty) return;
    if (_currentStep < _navigationSteps.length) {
      final step = _navigationSteps[_currentStep];
      final d = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        step.position.latitude,
        step.position.longitude,
      );
      setState(() {
        _nextTurnDistance = d;
        _navigationInstruction = _getNavigationText(step.instruction, d);
      });
    }
  }

  String _getNavigationText(String direction, double distance) {
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

  String _getDirectionFromBearing(double bearing) {
    if (bearing >= 337.5 || bearing < 22.5) return 'ตรงไป';
    if (bearing >= 22.5 && bearing < 67.5) return 'เบี่ยงขวา';
    if (bearing >= 67.5 && bearing < 112.5) return 'เลี้ยวขวา';
    if (bearing >= 112.5 && bearing < 157.5) return 'เลี้ยวขวาอ้อม';
    if (bearing >= 157.5 && bearing < 202.5) return 'กลับรถ';
    if (bearing >= 202.5 && bearing < 247.5) return 'เลี้ยวซ้ายอ้อม';
    if (bearing >= 247.5 && bearing < 292.5) return 'เลี้ยวซ้าย';
    return 'เบี่ยงซ้าย';
  }

  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
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

  // -------------------- Start/Stop --------------------
  void _startNavigation() {
    setState(() {
      _isNavigating = true;
      _navigationStartTime = DateTime.now();
      _traveledDistance = 0.0;
      _currentStep = 0;
      _followUser = true;
      _currentZoom = 18.0;
    });
    HapticFeedback.mediumImpact();
    _smoothCameraUpdate();
    _showSuccessSnackBar('เริ่มการนำทาง');
  }

  void _stopNavigation() {
    setState(() {
      _isNavigating = false;
      _navigationInstruction = 'เริ่มต้นการนำทาง';
      _navigationStartTime = null;
      _currentStep = 0;
      _currentZoom = 15.0;
    });
    _fitMapBounds();
    _getDirections();
  }

  // -------------------- Off-route & progress --------------------
  void _recalcIfOffRoute() {
    if (_polylineCoordinates.isEmpty || _currentPosition == null) return;
    final d = _distanceToPolylineMeters(
      _currentPosition!,
      _polylineCoordinates,
    );
    if (d > _offRouteThresholdM)
      _offRouteStrikes++;
    else
      _offRouteStrikes = 0;
    if (_offRouteStrikes >= _offRouteStrikeLimit) {
      _offRouteStrikes = 0;
      _getDirections();
      _speak('กำลังคำนวณเส้นทางใหม่');
    }
  }

  void _updateProgressPolyline() {
    if (_polylineCoordinates.isEmpty || _currentPosition == null) return;
    final i = _findNearestPointOnRoute(_currentPosition!);
    final done = _polylineCoordinates.sublist(0, math.max(i, 1));

    _progressPolylines.clear();
    _progressPolylines.add(
      Polyline(
        polylineId: const PolylineId('progress'),
        color: Colors.grey.shade600, // ✅ วิ่งมาแล้ว = เทาเข้ม
        width: 8,
        points: done,
      ),
    );

    _polylines.removeWhere((p) => p.polylineId.value == 'progress');
    _polylines.addAll(_progressPolylines);
    setState(() {});
  }

  double _distanceToPolylineMeters(LatLng p, List<LatLng> line) {
    double minD = double.infinity;
    for (int i = 0; i < line.length - 1; i++) {
      minD = math.min(minD, _distancePointToSegment(p, line[i], line[i + 1]));
    }
    return minD;
  }

  double _distancePointToSegment(LatLng p, LatLng a, LatLng b) {
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

  // -------------------- Misc UI helpers --------------------
  void _fitMapBounds() {
    if (_mapController == null ||
        _currentPosition == null ||
        _destinationPosition == null)
      return;
    final minLat = math.min(
      _currentPosition!.latitude,
      _destinationPosition!.latitude,
    );
    final maxLat = math.max(
      _currentPosition!.latitude,
      _destinationPosition!.latitude,
    );
    final minLng = math.min(
      _currentPosition!.longitude,
      _destinationPosition!.longitude,
    );
    final maxLng = math.max(
      _currentPosition!.longitude,
      _destinationPosition!.longitude,
    );

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  void _recenterMap() {
    if (_mapController == null || _currentPosition == null) return;
    setState(() {
      _followUser = true;
      _isUserGesture = false;
    });
    _smoothCameraUpdate();
  }

  bool _isNearDestination() {
    if (_currentPosition == null || _destinationPosition == null) return false;
    final d = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _destinationPosition!.latitude,
      _destinationPosition!.longitude,
    );
    return d <= 50;
  }

  void _openGoogleMaps() async {
    if (_destinationPosition == null) return;

    final o = _currentPosition;
    final d = _destinationPosition!;

    // iOS: comgooglemaps:// (ถ้ามีแอป Google Maps), macOS/iOS fallback: web
    final iosGoogle = Uri.parse(
      'comgooglemaps://?saddr=${o?.latitude},${o?.longitude}&daddr=${d.latitude},${d.longitude}&directionsmode=driving',
    );

    // Android: Intent แบบ navigation
    final androidIntent = Uri.parse(
      'google.navigation:q=${d.latitude},${d.longitude}&mode=l',
    );

    // Fallback (ทุกแพลตฟอร์ม): web URL พร้อม origin/destination
    final webUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${o?.latitude},${o?.longitude}'
      '&destination=${d.latitude},${d.longitude}'
      '&travelmode=driving',
    );

    try {
      if (Platform.isAndroid) {
        if (await canLaunchUrl(androidIntent)) {
          await launchUrl(androidIntent, mode: LaunchMode.externalApplication);
          return;
        }
      } else if (Platform.isIOS) {
        if (await canLaunchUrl(iosGoogle)) {
          await launchUrl(iosGoogle, mode: LaunchMode.externalApplication);
          return;
        }
      }
    } catch (_) {}

    // สุดท้ายลองเปิด web
    await launchUrl(webUrl, mode: LaunchMode.externalApplication);
  }

  // -------------------- UI: dialogs/snackbars --------------------
  void _showArrivalNotification() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('ถึงจุดหมายแล้ว! 🎉'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'คุณมาถึง ${_destinationName ?? "ปลายทาง"} เรียบร้อยแล้ว',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildStatRow(Icons.timer, 'เวลาเดินทาง', _getElapsedTime()),
                  const Divider(height: 16),
                  _buildStatRow(
                    Icons.route,
                    'ระยะทาง',
                    '${(_traveledDistance / 1000).toStringAsFixed(2)} กม.',
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('เสร็จสิ้น', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[600])),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _getElapsedTime() {
    if (_navigationStartTime == null) return '0 นาที';
    final elapsed = DateTime.now().difference(_navigationStartTime!);
    final hours = elapsed.inHours;
    final mins = elapsed.inMinutes % 60;

    // แสดงแบบกระชับ เหมาะกับ UI
    if (hours > 0 && mins > 0) return '$hours ชม. $mins นาที';
    if (hours > 0) return '$hours ชม.';
    if (mins > 0) return '$mins นาที';
    return '${elapsed.inSeconds} วินาที';
  }

  String _getRemainingTime() {
    if (_duration == null) return '';
    if (_navigationStartTime != null && _currentSpeed > 0) {
      final remainingKm = (_distance ?? 0) - (_traveledDistance / 1000);
      final remainingHours =
          remainingKm / (_currentSpeed.clamp(1, 150)); // กันหารศูนย์
      var remainingMinutes = remainingHours * 60;
      if (remainingMinutes < 0) remainingMinutes = 0;
      if (remainingMinutes > 60) {
        final h = (remainingMinutes / 60).floor();
        final m = (remainingMinutes % 60).round();
        return '$h ชม. $m นาที';
      } else {
        return '${remainingMinutes.round()} นาที';
      }
    }
    if (_duration! > 60) {
      final h = (_duration! / 60).floor();
      final m = (_duration! % 60).round();
      return '$h ชม. $m นาที';
    } else {
      return '${_duration!.round()} นาที';
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('เปิดใช้งาน Location'),
        content: const Text(
          'กรุณาเปิดใช้งาน Location Service เพื่อใช้งานแผนที่นำทาง',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('เปิดการตั้งค่า'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ต้องการสิทธิ์เข้าถึงตำแหน่ง'),
        content: const Text(
          'แอปต้องการสิทธิ์เข้าถึงตำแหน่งเพื่อแสดงแผนที่นำทาง',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedForeverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ไม่สามารถเข้าถึงตำแหน่งได้'),
        content: const Text(
          'กรุณาเปิดสิทธิ์การเข้าถึงตำแหน่งในการตั้งค่าของแอป',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('เปิดการตั้งค่า'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('เกิดข้อผิดพลาด'),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  // -------------------- Lifecycle --------------------
  @override
  void dispose() {
    _positionSubscription?.cancel();
    _camThrottle?.cancel();
    _autoRecenterTimer?.cancel(); // ⬅️ เพิ่ม
    _mapController?.dispose();
    _pulseController.dispose();
    _markerAnimationController.dispose();
    _tts.stop();
    super.dispose();
  }

  // -------------------- UI --------------------
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'กำลังค้นหาตำแหน่งของคุณ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  'โปรดรอสักครู่...',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_currentPosition == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('แผนที่นำทาง'),
          backgroundColor: Colors.green,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_off,
                  size: 60,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'ไม่สามารถเข้าถึงตำแหน่งได้',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                'กรุณาเปิดใช้งาน GPS และอนุญาตการเข้าถึงตำแหน่ง',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _initializeLocation,
                icon: const Icon(Icons.refresh),
                label: const Text('ลองใหม่'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition!,
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
            compassEnabled: false,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: _isNavigating,
            trafficEnabled: _isNavigating,
            buildingsEnabled: true,

            // ✅ แตะค้างเพื่อตั้ง "ปลายทาง"
            onLongPress: _setDestinationFromTap,

            onMapCreated: (controller) {
              _mapController = controller;
              if (_destinationPosition != null && !_isNavigating)
                _fitMapBounds();
            },

            // ✅ ถ้าเลื่อนแผนที่ขณะนำทาง ให้หลุด follow ชั่วคราว และตั้งเวลาคืนค่าอัตโนมัติ
            onCameraMoveStarted: () {
              if (_isNavigating) {
                _isUserGesture = true;
                _followUser = false;
                _scheduleAutoRecenter();
              }
            },
            onCameraMove: (_) {},
            onCameraIdle: () {},
          ),
          if (_destinationPosition != null) _buildEtaChip(),

          // ===== Header (Nav / Normal) =====
          if (_isNavigating)
            _buildNavHeader()
          else if (_destinationPosition != null)
            _buildNormalHeader(),

          // ===== Right Controls =====
          Positioned(
            right: 16,
            bottom: _isNavigating
                ? 120
                : (_destinationPosition != null ? 240 : 100),
            child: Column(
              children: [
                // Zoom +/-
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        onPressed: () {
                          _currentZoom = math.min(_currentZoom + 1, 21);
                          _mapController?.animateCamera(CameraUpdate.zoomIn());
                        },
                        icon: const Icon(Icons.add),
                        padding: const EdgeInsets.all(8),
                      ),
                      Container(height: 0.5, color: Colors.grey[300]),
                      IconButton(
                        onPressed: () {
                          _currentZoom = math.max(_currentZoom - 1, 3);
                          _mapController?.animateCamera(CameraUpdate.zoomOut());
                        },
                        icon: const Icon(Icons.remove),
                        padding: const EdgeInsets.all(8),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // My location (recenter) — กด = กลับไปติดตาม, กดค้าง = เปิด/ปิดโหมดล็อคติดตาม
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onLongPress: () {
                      setState(() => _followLock = !_followLock);
                      _showSuccessSnackBar(
                        _followLock
                            ? 'ล็อคติดตามเหมือน Google Maps'
                            : 'ปลดล็อคการติดตาม',
                      );
                    },
                    child: IconButton(
                      icon: Icon(
                        _followLock ? Icons.gps_fixed : Icons.gps_not_fixed,
                        color: Colors.blue,
                      ),
                      onPressed: _recenterMap,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Toggle 2D/3D tilt
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.threed_rotation),
                    onPressed: () {
                      setState(() {
                        if (_targetTilt > 0)
                          _targetTilt = 0;
                        else
                          _targetTilt = 45;
                        _followUser = true;
                        _isUserGesture = false;
                      });
                      _smoothCameraUpdate();
                    },
                  ),
                ),
              ],
            ),
          ),

          // ===== Bottom card (Normal mode) =====
          if (!_isNavigating && _destinationPosition != null)
            _buildBottomCard(),
        ],
      ),
    );
  }

  Widget _buildEtaChip() {
    // คำนวณข้อความ
    final etaMin = _remainingMinutesNumeric();
    final etaStr =
        _getRemainingTime(); // ใช้ตัวเดิมของคุณเพื่อแสดงสวยๆ (เช่น "15 นาที" / "1 ชม. 5 นาที")
    final kmLeft = ((_distance ?? 0) - _traveledDistance / 1000)
        .clamp(0, 9999)
        .toStringAsFixed(1);
    final arrival = DateTime.now().add(Duration(minutes: etaMin));
    final hh = arrival.hour.toString().padLeft(2, '0');
    final mm = arrival.minute.toString().padLeft(2, '0');
    if (_isNavigating) return const SizedBox.shrink(); // ✅ ซ่อนเมื่อเริ่มนำทาง

    return Positioned(
      top: _isNavigating ? 120 : 120, // ⬅️ เดิม 86 / 76
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.72),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                etaStr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 16, color: Colors.white24),
              const SizedBox(width: 12),
              const Icon(Icons.directions_car, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Text('$kmLeft กม.', style: const TextStyle(color: Colors.white)),
              const SizedBox(width: 12),
              Container(width: 1, height: 16, color: Colors.white24),
              const SizedBox(width: 12),
              const Icon(Icons.schedule, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Text('ถึง $hh:$mm', style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  void _setDestinationFromTap(LatLng p) async {
    HapticFeedback.selectionClick(); // ⬅️ เพิ่ม
    setState(() {
      _destinationPosition = p;
      _destinationName = 'ปลายทางใหม่';
      _destinationAddress = null;
    });
    _addMarkers();
    await _getDirections();
    _showSuccessSnackBar('ตั้งปลายทางใหม่แล้ว');
  }

  void _scheduleAutoRecenter() {
    _autoRecenterTimer?.cancel();
    // ถ้าล็อค follow อยู่ จะเด้งกลับมาตามเองภายใน 6 วินาที
    if (_followLock && _isNavigating) {
      _autoRecenterTimer = Timer(const Duration(seconds: 6), () {
        if (!_isUserGesture) return;
        setState(() {
          _followUser = true;
          _isUserGesture = false;
        });
        _smoothCameraUpdate();
      });
    }
  }

  // -------------------- Small UI parts --------------------
  Widget _buildNavHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade700, Colors.green.shade600],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildCircularButton(
                      Icons.close,
                      _stopNavigation,
                      Colors.white.withOpacity(0.2),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _navigationInstruction,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (_nextStreetName.isNotEmpty)
                            Text(
                              _nextStreetName,
                              style: const TextStyle(
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Colors.black.withOpacity(0.2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavigationInfo(
                      Icons.speed,
                      '${_currentSpeed.toStringAsFixed(0)} กม./ชม.',
                    ),
                    _buildNavigationInfo(Icons.timer, _getRemainingTime()),
                    _buildNavigationInfo(
                      Icons.route,
                      '${((_distance ?? 0) - _traveledDistance / 1000).toStringAsFixed(1)} กม.',
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

  Widget _buildNormalHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _destinationName ?? 'ปลายทาง',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_distance != null)
                        Text(
                          '${_distance!.toStringAsFixed(1)} กม. • ${_getRemainingTime()}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
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
    );
  }

  Widget _buildBottomCard() {
    return DraggableScrollableSheet(
      initialChildSize: 0.25, // 🔰 เริ่มต้น 25% ของหน้าจอ
      minChildSize: 0.15, // 📉 สไลด์ลงได้ต่ำสุด 15%
      maxChildSize: 0.6, // 📈 สไลด์ขึ้นได้สูงสุด 60%
      snap: true, // ✅ ให้มัน snap เมื่อหยุดสไลด์
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController, // ✅ รองรับการเลื่อนภายใน
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ แถบจับด้านบน
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // 📍 ข้อมูลร้าน / ปลายทาง
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.place,
                          color: Colors.green,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _destinationName ?? 'ปลายทาง',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_destinationAddress != null)
                              Text(
                                _destinationAddress!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 📍 ปุ่มเริ่มนำทาง + เปิด Google Maps
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _destinationPosition != null
                              ? _startNavigation
                              : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade400,
                                  Colors.green.shade600,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.navigation_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'เริ่มการนำทาง',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: _openGoogleMaps,
                          icon: const Icon(
                            Icons.map_outlined,
                            color: Colors.blue,
                            size: 26,
                          ),
                          padding: const EdgeInsets.all(14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCircularButton(IconData icon, VoidCallback onTap, Color bg) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildNavigationInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ---- Model ----
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
