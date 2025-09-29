// widgets/empty_state_widget.dart
import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final Color? iconColor;
  final double iconSize;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
    this.iconColor,
    this.iconSize = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  actionText!,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Specific empty states for chat
class ChatEmptyStateWidget extends StatelessWidget {
  final VoidCallback? onRefresh;

  const ChatEmptyStateWidget({
    super.key,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.chat_bubble_outline,
      title: 'ยังไม่มีแชท',
      message: 'เมื่อมีออเดอร์ใหม่ คุณจะสามารถแชทกับลูกค้าได้ที่นี่',
      actionText: 'รีเฟรช',
      onAction: onRefresh,
      iconColor: Colors.green,
    );
  }
}

class MessagesEmptyStateWidget extends StatelessWidget {
  final String partnerName;

  const MessagesEmptyStateWidget({
    super.key,
    required this.partnerName,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.message,
      title: 'เริ่มต้นการสนทนา',
      message: 'ส่งข้อความแรกให้กับ $partnerName',
      iconColor: Colors.blue,
      iconSize: 48,
    );
  }
}

class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorWidget({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.wifi_off,
      title: 'ไม่สามารถเชื่อมต่อได้',
      message: 'กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ตของคุณ',
      actionText: 'ลองใหม่',
      onAction: onRetry,
      iconColor: Colors.red,
    );
  }
}