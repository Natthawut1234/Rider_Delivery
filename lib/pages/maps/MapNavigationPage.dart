// lib/map_navigation_page.dart
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rider_delivery/APIs/baseAPI_URL/baseURL.dart';

import 'map_utils.dart';

class MapNavigationPage extends StatefulWidget {
  const MapNavigationPage({Key? key}) : super(key: key);
  @override
  State<MapNavigationPage> createState() => _MapNavigationPageState();
}

class _MapNavigationPageState extends State<MapNavigationPage>
    with TickerProviderStateMixin {
  // Map + state
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  LatLng? _destinationPosition;
  String? _destinationName;
  String? _destinationAddress;
  StreamSubscription<Position>? _posSub;
  bool _is3DMode = false;

  // Animations
  late AnimationController _markerAnimationController;
  Animation<double>? _markerAnimation;
  LatLng? _animationStartPos;
  LatLng? _animationEndPos;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Route
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  final Set<Polyline> _progressPolylines = {};
  final List<LatLng> _polylineCoordinates = [];
  final List<NavigationStep> _navigationSteps = [];
  int _currentStep = 0;

  // UI / navigation
  bool _isLoading = true;
  bool _isNavigating = false;
  bool _followUser = true;
  bool _isUserGesture = false;
  Timer? _autoRecenterTimer;
  bool _followLock = true;

  // Camera
  double _currentBearing = 0.0;
  double _lastBearing = 0.0;
  double _currentZoom = 18.0;
  Timer? _camThrottle;
  final Duration _camInterval = const Duration(milliseconds: 200); // ✅ ลดจาก 330 → 200ms
  double _targetTilt = 45;
  double _targetZoom = 18;
  double _currentTilt = 45; // ✅ เพิ่มตัวแปรเก็บ tilt ปัจจุบัน

  // Trip stats
  double? _distanceKm;
  double? _durationMin;
  DateTime? _navigationStartTime;
  double _traveledDistanceM = 0.0;
  LatLng? _lastPosition;
  double _currentSpeedKmh = 0.0;

  // Voice
  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;
  String _navigationInstruction = 'เริ่มต้นการนำทาง';
  double? _nextTurnDistance;
  String _nextStreetName = '';
  final Set<int> _spokenStageForStep = {};

  // Icons
  BitmapDescriptor? _motorcycleIcon;
  BitmapDescriptor? _destinationIcon;

  // Off-route
  int _offRouteStrikes = 0;
  final int _offRouteStrikeLimit = 3;
  final double _offRouteThresholdM = 35;

  // Google Maps API Key
  final String _googleApiKey = BaseAPI_URL.GoogleMapAPI;

  // ✅ GPS Filter variables
  LatLng? _filteredPosition;
  double _positionUncertainty = 50.0;

  @override
  void initState() {
    super.initState();
    _initAnims();
    _initTts();
    _initMarkers();
    _initLocation();
  }

  void _initAnims() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _markerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _markerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _markerAnimationController,
        curve: Curves.linear,
      ),
    )..addListener(() {
        if (!mounted ||
            _animationStartPos == null ||
            _animationEndPos == null) return;
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
        _currentPosition = LatLng(lat!, lng!);
        _updateCurrentMarker();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      });
  }

  Future<void> _initMarkers() async {
    _motorcycleIcon = await MapUtils.createMotorcycleMarker(
      startColor: Colors.redAccent,
      endColor: Colors.red.shade800,
    );
    _destinationIcon = await MapUtils.createPinMarker(Colors.red, 48);
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage("th-TH");
      await _tts.awaitSpeakCompletion(true);
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      _ttsReady = true;
    } catch (_) {
      _ttsReady = false;
    }
  }

  Future<void> _initLocation() async {
    try {
      await MapUtils.ensureLocationServiceAndPermission();
      final pos = await MapUtils.getCurrentPosition();
      if (_currentPosition == null) {
        _currentPosition = LatLng(pos.latitude, pos.longitude);
        _filteredPosition = _currentPosition;
        _lastPosition = _currentPosition;
        _currentBearing = pos.heading;
        _lastBearing = pos.heading;
      }
      setState(() => _isLoading = false);
      _addMarkers();
      if (_destinationPosition != null) await _loadDirections();
      _startTracking();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorDialog('เกิดข้อผิดพลาดในการเข้าถึงตำแหน่ง');
    }
  }

  // ✅ GPS Tracking แบบ Google Maps: อัปเดตเร็วและลื่น
  void _startTracking() {
    _posSub?.cancel();

    _posSub = MapUtils.positionStream().listen((position) {
      if (!mounted) return;

      LatLng rawPos = LatLng(position.latitude, position.longitude);
      _currentSpeedKmh = (position.speed * 3.6).clamp(0, 150);

      // ✅ 1. กรอง GPS แบบ Ultra-Smooth (ลดค่า alpha ให้กรองนุ่มขึ้น)
      _filteredPosition = _applyAdaptiveFilter(
        rawPos,
        position.accuracy,
        _currentSpeedKmh,
      );

      // ✅ 2. Snap-to-route ถ้ากำลังนำทาง
      if (_isNavigating && _polylineCoordinates.isNotEmpty) {
        final snapped = MapUtils.snapToRoute(
          _filteredPosition!,
          _polylineCoordinates,
          maxSnapDistMeters: 30, // เพิ่มจาก 25 → 30 เมตร
        );
        if (snapped != null) {
          _filteredPosition = snapped;
        }
      }

      _currentPosition = _filteredPosition;

      // ✅ 3. คำนวณ bearing แบบนุ่มมาก
      _updateBearing(position);

      // ✅ 4. อัปเดตระยะทาง
      if (_lastPosition != null) {
        final dist = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        // ✅ กรองระยะทางด้วย เพื่อไม่ให้เพิ่มจาก GPS noise
        if (dist > 1) { // เพิ่มเฉพาะถ้าขยับจริงๆ มากกว่า 1 เมตร
          _traveledDistanceM += dist;
        }
      }
      _lastPosition = _currentPosition;

      _updateCurrentMarker();
      if (mounted) setState(() {});

      _smoothCameraUpdate(); // อัปเดตกล้อง

      if (_isNavigating) {
        _updateProgressPolyline();
        _updateNavText();
        _maybeSpeakForStep();
        _checkNextStep();
        _recalcIfOffRoute();
        if (_isNearDestination()) {
          _showArrivalNotification();
          _stopNavigation();
        }
      }
    });
  }

  // ✅ Ultra-Smooth Filter: กรองแบบนุ่มมากเพื่อไม่ให้กระตุก
  LatLng _applyAdaptiveFilter(LatLng raw, double accuracy, double speedKmh) {
    if (_filteredPosition == null) {
      _positionUncertainty = accuracy;
      return raw;
    }

    final dist = Geolocator.distanceBetween(
      _filteredPosition!.latitude,
      _filteredPosition!.longitude,
      raw.latitude,
      raw.longitude,
    );

    // ✅ ละทิ้ง GPS noise ที่ชัดเจน
    if (dist < 2 && accuracy > 25) {
      return _filteredPosition!; // เก็บค่าเดิม
    }

    // ✅ ปรับ alpha ให้นุ่มขึ้น (ลดค่าลง = กรองมากขึ้น)
    double alpha;
    if (accuracy < 8) {
      // GPS แม่นมาก
      alpha = speedKmh >= 80 ? 0.55 : speedKmh >= 40 ? 0.40 : 0.30;
    } else if (accuracy < 15) {
      // GPS แม่นปานกลาง
      alpha = speedKmh >= 80 ? 0.45 : speedKmh >= 40 ? 0.32 : 0.22;
    } else {
      // GPS แม่นยำต่ำ
      alpha = speedKmh >= 80 ? 0.35 : speedKmh >= 40 ? 0.25 : 0.15;
    }

    // ✅ ถ้าความเร็วต่ำมาก → กรองหนักสุด
    if (speedKmh < 3) {
      alpha *= 0.4; // กรองหนัก 60%
    } else if (speedKmh < 10) {
      alpha *= 0.6; // กรองปานกลาง 40%
    }

    // คำนวณตำแหน่งใหม่แบบ smooth
    final lat = _filteredPosition!.latitude +
        (raw.latitude - _filteredPosition!.latitude) * alpha;
    final lng = _filteredPosition!.longitude +
        (raw.longitude - _filteredPosition!.longitude) * alpha;

    _positionUncertainty =
        accuracy * (1 - alpha) + _positionUncertainty * alpha;

    return LatLng(lat, lng);
  }

  // ✅ อัปเดต bearing แบบนุ่มมาก (เพิ่มการกรอง)
  void _updateBearing(Position position) {
    final speedMs = position.speed;
    final headingFromSensor = position.heading;

    bool useSensor = speedMs >= 1.2 && // ลดจาก 1.5 → 1.2
        !headingFromSensor.isNaN &&
        headingFromSensor > 0;

    double newBearing;
    if (useSensor) {
      newBearing = headingFromSensor;
    } else if (_lastPosition != null && _currentPosition != null) {
      newBearing = MapUtils.calculateBearing(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
    } else {
      newBearing = _lastBearing;
    }

    double diff = MapUtils.shortestBearingDelta(_lastBearing, newBearing);

    // ✅ ปรับ alpha ให้นุ่มขึ้น (ลดค่าลง = หมุนช้าลง = ไม่กระตุก)
    double bearingAlpha;
    if (_currentSpeedKmh >= 60) {
      bearingAlpha = 0.12; // เร็วมาก: หมุนเร็วหนอย
    } else if (_currentSpeedKmh >= 30) {
      bearingAlpha = 0.08; // ปานกลาง: หมุนช้า
    } else if (_currentSpeedKmh >= 10) {
      bearingAlpha = 0.05; // ช้า: หมุนช้ามาก
    } else {
      bearingAlpha = 0.03; // หยุด: แทบไม่หมุน
    }

    _currentBearing =
        MapUtils.normalizeBearing(_lastBearing + diff * bearingAlpha);
    _lastBearing = _currentBearing;
  }

  // -------------------- Directions --------------------
  Future<void> _loadDirections() async {
    if (_currentPosition == null || _destinationPosition == null) return;
    _polylineCoordinates.clear();
    _polylines.clear();
    _navigationSteps.clear();
    _progressPolylines.clear();

    try {
      final result = await MapUtils.fetchDirections(
        apiKey: _googleApiKey,
        origin: _currentPosition!,
        destination: _destinationPosition!,
      );

      _polylineCoordinates.addAll(result.routePoints);
      _navigationSteps.addAll(result.steps);
      setState(() {
        _distanceKm = result.distanceKm;
        _durationMin = result.durationMin;
      });

      _drawPolylines();
      if (!_isNavigating) _fitBounds();
    } catch (_) {
      _showErrorSnackBar('ไม่สามารถโหลดเส้นทางได้');
    }
  }

  void _drawPolylines() {
    setState(() {
      _polylines.clear();
      if (_isNavigating) {
        _polylines.add(MapUtils.buildRouteShadow(points: _polylineCoordinates));
      }
      _polylines.add(
        MapUtils.buildRoutePolyline(
          id: 'route',
          points: _polylineCoordinates,
          navigating: _isNavigating,
        ),
      );
      _polylines.addAll(_progressPolylines);
    });
  }

  void _updateCurrentMarker() {
    if (_currentPosition == null) return;
    final m = MapUtils.buildCurrentMarker(
      position: _currentPosition!,
      rotation: _currentBearing,
      icon: _motorcycleIcon,
    );
    final newMarkers = Set<Marker>.from(_markers)
      ..removeWhere((x) => x.markerId.value == 'current')
      ..add(m);
    _markers = newMarkers;
  }

  void _addMarkers() {
    _markers.clear();
    if (_currentPosition != null) {
      _updateCurrentMarker();
    }
    if (_destinationPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destinationPosition!,
          icon: _destinationIcon ??
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

  // -------------------- Navigation loop helpers --------------------
  void _updateProgressPolyline() {
    if (_polylineCoordinates.isEmpty || _currentPosition == null) return;
    final i = MapUtils.findNearestPointOnRoute(
      _currentPosition!,
      _polylineCoordinates,
    );
    final done = _polylineCoordinates.sublist(0, math.max(i, 1));
    _progressPolylines.clear();
    _progressPolylines.add(
      Polyline(
        polylineId: const PolylineId('progress'),
        color: Colors.grey.shade600,
        width: 8,
        points: done,
      ),
    );
    _polylines.removeWhere((p) => p.polylineId.value == 'progress');
    _polylines.addAll(_progressPolylines);
    setState(() {});
  }

  void _updateNavText() {
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
        _navigationInstruction = MapUtils.navText(step.instruction, d);
      });
    }
  }

  void _maybeSpeakForStep() {
    if (!_isNavigating ||
        _currentPosition == null ||
        _navigationSteps.isEmpty ||
        !_ttsReady) return;
    if (_currentStep >= _navigationSteps.length) return;

    final step = _navigationSteps[_currentStep];
    final d = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      step.position.latitude,
      step.position.longitude,
    );

    Future<void> speak(String t) async {
      try {
        await _tts.stop();
        await _tts.speak(t);
      } catch (e) {
        debugPrint('TTS error: $e');
      }
    }

    final sid = _currentStep * 100000;

    if (d > 350 && d <= 550 && !_spokenStageForStep.contains(sid + 500)) {
      _spokenStageForStep.add(sid + 500);
      speak('${step.instruction} อีกห้าร้อยเมตร');
    } else if (d > 180 &&
        d <= 300 &&
        !_spokenStageForStep.contains(sid + 300)) {
      _spokenStageForStep.add(sid + 300);
      speak('${step.instruction} อีกสามร้อยเมตร');
    } else if (d > 70 && d <= 150 && !_spokenStageForStep.contains(sid + 150)) {
      _spokenStageForStep.add(sid + 150);
      speak('${step.instruction} อีกหนึ่งร้อยห้าสิบเมตร');
    } else if (d <= 40 && !_spokenStageForStep.contains(sid + 40)) {
      _spokenStageForStep.add(sid + 40);
      speak('เตรียม ${step.instruction} ตอนนี้');
    } else if (d <= 20 && !_spokenStageForStep.contains(sid + 10)) {
      _spokenStageForStep.add(sid + 10);
      speak('เลี้ยว ${step.instruction} เดี๋ยวนี้');
    }
  }

  void _checkNextStep() {
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
          MapUtils.bump();
        });
        if (_currentStep < _navigationSteps.length) {
          if (_ttsReady)
            _tts.speak('จากนั้น ${_navigationSteps[_currentStep].instruction}');
        }
      }
    }
  }

  void _recalcIfOffRoute() {
    if (_polylineCoordinates.isEmpty || _currentPosition == null) return;
    final d = MapUtils.distanceToPolylineMeters(
      _currentPosition!,
      _polylineCoordinates,
    );
    if (d > _offRouteThresholdM)
      _offRouteStrikes++;
    else
      _offRouteStrikes = 0;
    if (_offRouteStrikes >= _offRouteStrikeLimit) {
      _offRouteStrikes = 0;
      _loadDirections();
      if (_ttsReady) _tts.speak('กำลังคำนวณเส้นทางใหม่');
    }
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

  // -------------------- Camera --------------------
  void _smoothCameraUpdate() async {
    _camThrottle?.cancel();
    _camThrottle = Timer(_camInterval, () async {
      if (_mapController == null || _currentPosition == null) return;
      if (!_followUser || _isUserGesture) return;

      // ✅ ลด threshold ลง: อัปเดตกล้องแม้ความเร็วต่ำ
      if (_currentSpeedKmh < 1) return; // ลดจาก 3 → 1 km/h

      double bearing = _currentBearing;
      if (_navigationSteps.isNotEmpty &&
          _currentStep < _navigationSteps.length) {
        final step = _navigationSteps[_currentStep];
        bearing = MapUtils.calculateBearing(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          step.position.latitude,
          step.position.longitude,
        );

        final delta = MapUtils.shortestBearingDelta(_lastBearing, bearing);
        // ✅ ลด threshold การหมุนกล้อง
        bearing = delta.abs() < 5 // ลดจาก 8 → 5 องศา
            ? _lastBearing
            : MapUtils.normalizeBearing(_lastBearing + delta * 0.10); // ลดจาก 0.12 → 0.10
      }
      _lastBearing = bearing;

      _targetZoom = MapUtils.zoomBySpeedAndTurn(
        kmh: _currentSpeedKmh,
        current: _currentPosition,
        steps: _navigationSteps,
        currentStep: _currentStep,
      );
      _targetTilt = MapUtils.tiltByContext(
        kmh: _currentSpeedKmh,
        current: _currentPosition,
        steps: _navigationSteps,
        currentStep: _currentStep,
      );
      _targetTilt = math.min(_targetTilt + 25, 75);

      // ✅ เก็บค่า zoom และ tilt ที่ใช้จริง
      _currentZoom = (_targetZoom - 0.3).clamp(14.0, 19.5);
      _currentTilt = _targetTilt;

      try {
        final projection = await _mapController!.getScreenCoordinate(
          _currentPosition!,
        );
        final screenSize = MediaQuery.of(context).size;
        final double yOffset = screenSize.height * 0.35;

        final LatLng newTarget = await _mapController!.getLatLng(
          ScreenCoordinate(
            x: projection.x,
            y: (projection.y - yOffset).round(),
          ),
        );

        await MapUtils.smoothCameraTo(
          controller: _mapController!,
          target: newTarget,
          zoom: _currentZoom,
          tilt: _currentTilt,
          bearing: _followLock ? bearing : _lastBearing,
          durationMs: 800, // ลดจาก 900 → 800ms เพื่อให้เร็วขึ้น
        );
      } catch (e) {
        await MapUtils.animateFollowCamera(
          controller: _mapController!,
          target: _currentPosition!,
          zoom: _currentZoom,
          tilt: _currentTilt,
          bearing: _followLock ? bearing : _lastBearing,
        );
      }
    });
  }

  void _fitBounds() {
    if (_mapController == null ||
        _currentPosition == null ||
        _destinationPosition == null) return;
    final bounds = MapUtils.boundsFromLatLngList([
      _currentPosition!,
      _destinationPosition!,
    ]);
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

  void _scheduleAutoRecenter() {
    _autoRecenterTimer?.cancel();
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

  // -------------------- Start/Stop --------------------
  void _startNavigation() {
    setState(() {
      _targetTilt = 55;
      _followUser = true;
      _isNavigating = true;
      _navigationStartTime = DateTime.now();
      _traveledDistanceM = 0.0;
      _currentStep = 0;
      _currentZoom = 18.0;
    });
    MapUtils.bump();
    _smoothCameraUpdate();
    _showSuccessSnackBar('เริ่มการนำทาง');
    if (_ttsReady)
      _tts.speak('เริ่มการนำทางไปยัง ${_destinationName ?? "ปลายทาง"}');

    if (_mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentPosition!,
            zoom: 18.5,
            tilt: 65,
            bearing: _lastBearing,
          ),
        ),
      );
    }
  }

  void _stopNavigation() {
    setState(() {
      _isNavigating = false;
      _navigationInstruction = 'เริ่มต้นการนำทาง';
      _navigationStartTime = null;
      _currentStep = 0;
      _currentZoom = 15.0;
    });
    _fitBounds();
    _loadDirections();
  }

  // -------------------- UI --------------------
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
        if (_currentPosition != null) _loadDirections();
      }
    }
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _camThrottle?.cancel();
    _autoRecenterTimer?.cancel();
    _mapController?.dispose();
    _pulseController.dispose();
    _markerAnimationController.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    if (_currentPosition == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('แผนที่นำทาง'),
          backgroundColor: Colors.green,
        ),
        body: Center(
          child: ElevatedButton.icon(
            onPressed: _initLocation,
            icon: const Icon(Icons.refresh),
            label: const Text('ลองใหม่'),
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
            rotateGesturesEnabled: !_followLock,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            zoomGesturesEnabled: true,
            trafficEnabled: _isNavigating,
            buildingsEnabled: true,
            onLongPress: _onLongPressSetDestination,
            onMapCreated: (c) {
              _mapController = c;
              if (_destinationPosition != null && !_isNavigating) _fitBounds();
            },
            onCameraMoveStarted: () {
              if (_isNavigating) {
                _isUserGesture = true;
                _followUser = false;
                _scheduleAutoRecenter();
              }
            },
          ),
          if (_destinationPosition != null) _buildEtaChip(),
          if (_isNavigating)
            _buildNavHeader()
          else if (_destinationPosition != null)
            _buildNormalHeader(),
          Positioned(
            right: 16,
            bottom: _isNavigating
                ? 120
                : (_destinationPosition != null ? 240 : 100),
            child: Column(
              children: [
                _myLocationButton(),
                const SizedBox(height: 12),
                _tiltToggle(),
                const SizedBox(height: 12),
                _lockToggleButton(),
              ],
            ),
          ),
          if (!_isNavigating && _destinationPosition != null)
            _buildBottomCard(),
        ],
      ),
    );
  }

  Widget _buildEtaChip() {
    final etaMin = MapUtils.remainingMinutesNumeric(
      durationMin: _durationMin,
      navStartTime: _navigationStartTime,
      currentKmh: _currentSpeedKmh,
      totalKm: _distanceKm,
      traveledMeters: _traveledDistanceM,
    );
    final etaStr = MapUtils.humanRemainingTime(etaMin);
    final kmLeft = ((_distanceKm ?? 0) - _traveledDistanceM / 1000)
        .clamp(0, 9999)
        .toStringAsFixed(1);
    final arrival = DateTime.now().add(Duration(minutes: etaMin));
    final hh = arrival.hour.toString().padLeft(2, '0');
    final mm = arrival.minute.toString().padLeft(2, '0');
    if (_isNavigating) return const SizedBox.shrink();

    return Positioned(
      top: 120,
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

  Widget _buildNavHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade700, Colors.green.shade600],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
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
                    _circularButton(
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
                    _navInfo(
                      Icons.speed,
                      '${_currentSpeedKmh.toStringAsFixed(0)} กม./ชม.',
                    ),
                    _navInfo(
                      Icons.timer,
                      MapUtils.humanRemainingTime(
                        MapUtils.remainingMinutesNumeric(
                          durationMin: _durationMin,
                          navStartTime: _navigationStartTime,
                          currentKmh: _currentSpeedKmh,
                          totalKm: _distanceKm,
                          traveledMeters: _traveledDistanceM,
                        ),
                      ),
                    ),
                    _navInfo(
                      Icons.route,
                      '${((_distanceKm ?? 0) - _traveledDistanceM / 1000).toStringAsFixed(1)} กม.',
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
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 5,
              offset: Offset(0, 2),
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
                      if (_distanceKm != null)
                        Text(
                          '${_distanceKm!.toStringAsFixed(1)} กม. • ${MapUtils.humanRemainingTime((_durationMin ?? 0).round())}',
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
    return Positioned.fill(
      child: DraggableScrollableSheet(
        initialChildSize: 0.25,
        minChildSize: 0.15,
        maxChildSize: 0.6,
        snap: true,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            onPressed: () {
                              if (_currentPosition != null &&
                                  _destinationPosition != null) {
                                MapUtils.openGoogleMapsAppOrWeb(
                                  origin: _currentPosition!,
                                  destination: _destinationPosition!,
                                );
                              }
                            },
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
      ),
    );
  }

  Widget _myLocationButton() {
    return Container(
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
        icon: const Icon(Icons.my_location, color: Colors.blue),
        onPressed: () async {
          if (_mapController == null) return;

          try {
            final pos = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.bestForNavigation,
              ),
            );

            final LatLng current = LatLng(pos.latitude, pos.longitude);

            setState(() {
              _currentPosition = current;
              _filteredPosition = current;
              _currentBearing = pos.heading;
              _followUser = true;
              _isUserGesture = false;
            });
            _updateCurrentMarker();

            // ✅ ใช้ค่า zoom และ tilt ปัจจุบันที่เก็บไว้แทน
            await _mapController!.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: current,
                  zoom: _currentZoom,
                  tilt: _targetTilt,
                  bearing: _currentBearing,
                ),
              ),
            );

            _showSuccessSnackBar("📍 ไปยังตำแหน่งของคุณแล้ว");
          } catch (e) {
            _showErrorSnackBar("❌ ไม่สามารถหาตำแหน่งปัจจุบันได้");
          }
        },
      ),
    );
  }

  Widget _lockToggleButton() {
    return Container(
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
        icon: Icon(
          _followLock ? Icons.lock : Icons.lock_open,
          color: _followLock ? Colors.green : Colors.grey,
        ),
        onPressed: () {
          setState(() => _followLock = !_followLock);
          _showSuccessSnackBar(
            _followLock ? '🔒 ล็อกกล้องตามทิศนำทาง' : '🔓 ปลดล็อกหมุนแผนที่ได้',
          );
        },
      ),
    );
  }

  Widget _tiltToggle() {
    return Container(
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
        icon: Icon(
          _is3DMode ? Icons.threed_rotation : Icons.map_outlined,
          color: _is3DMode ? Colors.blue : Colors.black,
        ),
        tooltip: _is3DMode ? 'โหมด 3D' : 'โหมด 2D',
        onPressed: () async {
          if (_mapController == null || _currentPosition == null) return;

          setState(() {
            _is3DMode = !_is3DMode;
            _targetTilt = _is3DMode ? 60 : 0;
            _currentTilt = _targetTilt; // ✅ อัปเดตค่า current tilt
            _followUser = true;
            _isUserGesture = false;
          });

          await _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: _currentPosition!,
                zoom: _currentZoom, // ✅ ใช้ zoom ปัจจุบัน
                tilt: _currentTilt,
                bearing: _lastBearing,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _circularButton(IconData icon, VoidCallback onTap, Color bgColor) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white30, width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _navInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _onLongPressSetDestination(LatLng p) async {
    HapticFeedback.selectionClick();
    setState(() {
      _destinationPosition = p;
      _destinationName = 'ปลายทางใหม่';
      _destinationAddress = null;
    });
    _addMarkers();
    await _loadDirections();
    _showSuccessSnackBar('ตั้งปลายทางใหม่แล้ว');
  }

  void _showArrivalNotification() {
    MapUtils.boom();
    if (_ttsReady) _tts.speak('ถึง ${_destinationName ?? "ปลายทาง"} แล้วครับ');
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
                  _statRow(Icons.timer, 'เวลาเดินทาง', _elapsedTimeText()),
                  const Divider(height: 16),
                  _statRow(
                    Icons.route,
                    'ระยะทาง',
                    '${(_traveledDistanceM / 1000).toStringAsFixed(2)} กม.',
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

  Widget _statRow(IconData icon, String label, String value) {
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

  String _elapsedTimeText() {
    if (_navigationStartTime == null) return '0 นาที';
    final elapsed = DateTime.now().difference(_navigationStartTime!);
    final hours = elapsed.inHours;
    final mins = elapsed.inMinutes % 60;
    if (hours > 0 && mins > 0) return '$hours ชม. $mins นาที';
    if (hours > 0) return '$hours ชม.';
    if (mins > 0) return '$mins นาที';
    return '${elapsed.inSeconds} วินาที';
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
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }
}