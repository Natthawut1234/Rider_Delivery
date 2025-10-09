import 'package:flutter/material.dart';

/// Widget ปุ่มสำหรับเปิดแผนที่นำทาง
class MapNavigationButton extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final String? address;
  final VoidCallback? onPressed;

  const MapNavigationButton({
    Key? key,
    this.latitude,
    this.longitude,
    this.locationName,
    this.address,
    this.onPressed,
  }) : super(key: key);

  bool get hasValidCoordinates =>
      latitude != null && longitude != null;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: hasValidCoordinates
          ? () {
              if (onPressed != null) {
                onPressed!();
              } else {
                _navigateToMap(context);
              }
            }
          : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: hasValidCoordinates
                ? [Colors.green[100]!, Colors.blue[50]!]
                : [Colors.grey[200]!, Colors.grey[100]!],
          ),
          border: Border.all(
            color: hasValidCoordinates
                ? Colors.green.withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned.fill(
              child: CustomPaint(
                painter: _MapPatternPainter(
                  isEnabled: hasValidCoordinates,
                ),
              ),
            ),

            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: hasValidCoordinates
                          ? Colors.green
                          : Colors.grey[400],
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (hasValidCoordinates
                                  ? Colors.green
                                  : Colors.grey)
                              .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.map,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasValidCoordinates ? 'แตะเพื่อดูแผนที่' : 'ไม่มีพิกัด',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: hasValidCoordinates
                          ? Colors.green[800]
                          : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (hasValidCoordinates)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.navigation,
                          size: 14,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'นำทางด้วย Google Maps',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Overlay effect
            if (!hasValidCoordinates)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToMap(BuildContext context) {
    if (!hasValidCoordinates) return;

    Navigator.pushNamed(
      context,
      '/mapNavigation',
      arguments: {
        'destinationLat': latitude,
        'destinationLng': longitude,
        'destinationName': locationName,
        'destinationAddress': address,
      },
    );
  }
}

/// Custom Painter สำหรับวาดลวดลายแผนที่พื้นหลัง
class _MapPatternPainter extends CustomPainter {
  final bool isEnabled;

  _MapPatternPainter({required this.isEnabled});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isEnabled ? Colors.green : Colors.grey)
          .withOpacity(0.1)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // วาดเส้นกริด
    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }

    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }

    // วาดจุดพิกัด
    final dotPaint = Paint()
      ..color = (isEnabled ? Colors.green : Colors.grey)
          .withOpacity(0.2)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.4),
      4,
      dotPaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.6),
      4,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Widget ปุ่มขนาดเล็กสำหรับเปิดแผนที่
class CompactMapButton extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final String? address;
  final VoidCallback? onPressed;

  const CompactMapButton({
    Key? key,
    this.latitude,
    this.longitude,
    this.locationName,
    this.address,
    this.onPressed,
  }) : super(key: key);

  bool get hasValidCoordinates =>
      latitude != null && longitude != null;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: hasValidCoordinates
          ? () {
              if (onPressed != null) {
                onPressed!();
              } else {
                _navigateToMap(context);
              }
            }
          : null,
      icon: const Icon(Icons.map, size: 20),
      label: const Text(
        'ดูแผนที่',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey[300],
        disabledForegroundColor: Colors.grey[600],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
      ),
    );
  }

  void _navigateToMap(BuildContext context) {
    if (!hasValidCoordinates) return;

    Navigator.pushNamed(
      context,
      '/mapNavigation',
      arguments: {
        'destinationLat': latitude,
        'destinationLng': longitude,
        'destinationName': locationName,
        'destinationAddress': address,
      },
    );
  }
}

/// Widget แสดงข้อมูลตำแหน่งพร้อมปุ่มเปิดแผนที่
class LocationInfoCard extends StatelessWidget {
  final String title;
  final String? name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? phoneNumber;
  final IconData icon;
  final Color color;

  const LocationInfoCard({
    Key? key,
    required this.title,
    this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.phoneNumber,
    this.icon = Icons.location_on,
    this.color = Colors.green,
  }) : super(key: key);

  bool get hasValidCoordinates =>
      latitude != null && longitude != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
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
                        color: Colors.grey[600],
                      ),
                    ),
                    if (name != null)
                      Text(
                        name!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (address != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CompactMapButton(
                  latitude: latitude,
                  longitude: longitude,
                  locationName: name,
                  address: address,
                ),
              ),
              if (phoneNumber != null && phoneNumber!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () => _makePhoneCall(phoneNumber!),
                    icon: const Icon(Icons.phone, color: Colors.white),
                    tooltip: 'โทรออก',
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _makePhoneCall(String phone) async {
    final url = 'tel:$phone';
    // Note: url_launcher package required
    // if (await canLaunch(url)) {
    //   await launch(url);
    // }
  }
}