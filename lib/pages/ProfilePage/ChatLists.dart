// pages/rider_chat_list_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider_delivery/APIs/ChatSocket/ChatControllerSK.dart';
import 'package:rider_delivery/pages/Chats/models/ChatMessage.dart';
import 'package:rider_delivery/pages/Chats/widgets/empty_state_widget.dart';
import 'package:rider_delivery/pages/Chats/widgets/loading_widget.dart';
import 'package:rider_delivery/pages/Chats/Chat.dart';

class RiderChatListPage extends StatefulWidget {
  const RiderChatListPage({super.key});

  @override
  State<RiderChatListPage> createState() => _RiderChatListPageState();
}

class _RiderChatListPageState extends State<RiderChatListPage> {
  @override
  void initState() {
    super.initState();
    print('🚀 RiderChatListPage initState called');
    // Initialize chat controller and load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChatController();
    });
  }

  Future<void> _initializeChatController() async {
    try {
      print('🔄 Initializing chat controller...');
      final chatController = context.read<RiderChatController>();

      // Make sure rider info is loaded first
      await chatController.connectToChat();
      await chatController.loadChatRooms();

      print('✅ Chat controller initialized successfully');
    } catch (e) {
      print('❌ Error initializing chat controller: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RiderChatController>(
      builder: (context, chatController, child) {
        print(
          '🎯 Building RiderChatListPage with ${chatController.chatRooms.length} rooms',
        );

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Row(
              children: [
                const Text(
                  'แชทกับลูกค้า',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                if (chatController.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      chatController.unreadCount > 99
                          ? '99+'
                          : chatController.unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            backgroundColor: Colors.green,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 1,
            actions: [
              Icon(
                chatController.isConnected ? Icons.wifi : Icons.wifi_off,
                color: chatController.isConnected
                    ? Colors.white
                    : Colors.red[300],
                size: 20,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => chatController.refreshChatRooms(),
              ),
            ],
          ),
          body: _buildBody(chatController),
        );
      },
    );
  }

  Widget _buildBody(RiderChatController chatController) {
    print(
      '🏗️ Building body - loading: ${chatController.isLoading}, rooms: ${chatController.chatRooms.length}',
    );

    if (chatController.isLoading && chatController.chatRooms.isEmpty) {
      return const LoadingWidget(message: 'กำลังโหลดรายการแชท...');
    }

    if (chatController.chatRooms.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.chat_bubble_outline,
        title: 'ยังไม่มีแชท',
        message: 'เมื่อมีออเดอร์ใหม่ คุณจะสามารถแชทกับลูกค้าได้ที่นี่',
        actionText: 'รีเฟรช',
        onAction: () => chatController.refreshChatRooms(),
      );
    }

    return RefreshIndicator(
      onRefresh: chatController.refreshChatRooms,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: chatController.chatRooms.length,
        itemBuilder: (context, index) {
          final room = chatController.chatRooms[index];
          return _buildChatRoomCard(context, chatController, room);
        },
      ),
    );
  }

  Widget _buildChatRoomCard(
    BuildContext context,
    RiderChatController controller,
    ChatRoom room,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          print('📱 Opening chat for room ${room.roomId}');

          if (room.roomId != null) {
            controller.markRoomAsEntered(room.roomId!);
          }
          if (controller.userId == null) {
            await controller.initializeRiderInfoIfNeeded();
          }
          // Navigate to chat page
          Navigator.pushNamed(
            context,
            '/rider-chat',
            arguments: {
              'roomId': room.roomId,
              'orderId': room.orderId,
              'partnerName': room.customerName ?? 'ลูกค้า',
              'partnerPhoto': room.customerPhoto,
              'partnerPhone': room.customerPhone,
              'userType': 'rider',
              'userId': controller.userId,
              'riderId': controller.riderId,
              'userName': controller.riderName,
              'userPhoto': controller.riderPhoto,
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // --- Avatar ---
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: room.customerPhoto != null
                        ? NetworkImage(room.customerPhoto!)
                        : null,
                    child: room.customerPhoto == null
                        ? const Icon(Icons.person, color: Colors.grey, size: 28)
                        : null,
                  ),
                  if (room.unreadCount != null && room.unreadCount! > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          room.unreadCount! > 9
                              ? '9+'
                              : room.unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              // --- Chat Info ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // name + orderId
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            room.customerName ?? 'ลูกค้า',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '#${room.orderId}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // order status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: controller
                            .getOrderStatusColor(room.orderStatus)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        controller.getOrderStatusText(room.orderStatus),
                        style: TextStyle(
                          color: controller.getOrderStatusColor(
                            room.orderStatus,
                          ),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // last message
                    Text(
                      controller.formatLastMessage(
                        room.lastMessage,
                        room.messageType,
                      ),
                      style: TextStyle(
                        color: (room.unreadCount ?? 0) > 0
                            ? Colors.black87
                            : Colors.grey[600],
                        fontSize: 14,
                        fontWeight: (room.unreadCount ?? 0) > 0
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // delivery address
                    if (room.deliveryAddress != null)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              room.deliveryAddress!,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // --- Right Info ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    controller.formatLastMessageTime(room.lastMessageTime),
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  if (room.totalAmount != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '฿${room.totalAmount!.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (room.customerPhone != null)
                    InkWell(
                      onTap: () => controller.makePhoneCall(room.customerPhone),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.phone,
                          size: 16,
                          color: Colors.green,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
