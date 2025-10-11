// pages/rider_chat_page.dart (Final Fixed Version)
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:rider_delivery/APIs/ChatSocket/ChatControllerSK.dart';
import 'dart:io';
import 'dart:async';
import 'package:rider_delivery/pages/Chats/models/ChatMessage.dart';
import 'package:rider_delivery/pages/Chats/widgets/loading_widget.dart';
import 'package:rider_delivery/services/ChatService.dart';

class RiderChatPage extends StatefulWidget {
  const RiderChatPage({super.key});

  @override
  State<RiderChatPage> createState() => _RiderChatPageState();
}

class _RiderChatPageState extends State<RiderChatPage> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  // Get arguments from navigation
  Map<String, dynamic>? args;
  int? roomId;
  int? orderId;
  String? partnerName;
  String? partnerPhoto;
  String? partnerPhone;
  String? userType;

  // ✅ แยก ID ให้ชัดเจน
  int? userId; // สำหรับเปรียบเทียบข้อความ (rider_id สำหรับ rider)
  int? riderId; // สำหรับ business logic (rider_id เดียวกับ userId สำหรับ rider)

  // Chat service and controller
  RiderChatController? _chatController;
  RiderChatService? _chatService;

  // UI states
  File? _pendingImage;
  bool _isLoading = false;
  bool _isConnected = false;
  bool _isPartnerTyping = false;
  Timer? _typingTimer;
  bool _isUploadingImage = false;
  bool _isInitialized = false;

  // Stream subscriptions
  StreamSubscription<ChatMessage>? _messageSubscription;
  StreamSubscription<Map<String, dynamic>>? _typingSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  @override
  void initState() {
    super.initState();
    // Don't initialize arguments here - wait for didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeArguments();
      _initializeServices();
      _loadInitialMessages();
      _isInitialized = true;
    }
  }

  void _initializeArguments() {
    args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    roomId = args!['roomId'];
    orderId = args!['orderId'];
    partnerName = args!['partnerName'];
    partnerPhoto = args!['partnerPhoto'];
    partnerPhone = args!['partnerPhone'];
    userType = args!['userType'];

    // ✅ เปลี่ยนตรงนี้
    final chatController = Provider.of<RiderChatController>(
      context,
      listen: false,
    );
    userId = chatController.userId; // ✅ user_id จาก token (ใช้เทียบข้อความ)
    riderId = chatController.riderId; // ✅ rider_id สำหรับ business logic

    print('🔍 Chat Page Arguments:');
    print('   roomId: $roomId');
    print('   orderId: $orderId');
    print('   userType: $userType');
    print('   userId: $userId (for message comparison)');
    print('   riderId: $riderId (for business logic)');
  }

  void _initializeServices() async {
    _chatController = Provider.of<RiderChatController>(context, listen: false);
    _chatService = RiderChatService();

    // ✅ เชื่อมต่อ socket ด้วย riderId และ userId ที่ถูกต้อง
    if (_chatController!.riderId != null && _chatController!.userId != null) {
      await _chatService!.connectSocket(
        _chatController!.riderId!, // rider_id สำหรับ business logic
        _chatController!
            .userId!, // user_id สำหรับ authentication (จาก users table)
      );
    }

    // รอให้ socket connect ก่อน join room
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (_chatService!.isConnected && roomId != null) {
        await _chatService!.joinRoom(roomId!);
        print('✅ Joined room $roomId after socket connect');
      } else {
        print('⚠️ Socket not connected within 500ms or roomId is null');
      }
    });

    // Setup stream listeners
    _messageSubscription = _chatService!.messageStream.listen(_onNewMessage);
    _typingSubscription = _chatService!.typingStream.listen(_onUserTyping);
    _connectionSubscription = _chatService!.connectionStream.listen(
      _onConnectionChanged,
    );

    if (mounted) {
      setState(() => _isConnected = _chatService!.isConnected);
    }

    _markAsRead();
  }

  Future<void> _loadInitialMessages() async {
    if (!mounted || roomId == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await _chatService!.getChatMessages(roomId!);

      print('🔍 Response type: ${response.runtimeType}');
      print('🔍 Response: $response');

      List<ChatMessage> messages = [];

      if (response is Map) {
        print('✅ Success: ${response['success']}');
        print('📩 Messages field type: ${response['messages'].runtimeType}');

        final rawMessages = response['messages'];
        if (rawMessages is List) {
          for (var messageData in rawMessages) {
            try {
              final message = _parseMessage(messageData);
              messages.add(message);
            } catch (e) {
              print('⚠️ Parse error: $e');
              print('📦 Raw message: $messageData');
            }
          }
        }
      }

      print('📊 Loaded messages count: ${messages.length}');

      if (mounted) {
        setState(() {
          _messages
            ..clear()
            ..addAll(messages);
          _isLoading = false;

          // ✅ ถ้า partnerPhoto ยังไม่มี ให้ใช้จากข้อความฝั่งลูกค้า
          if (partnerPhoto == null || partnerPhoto!.isEmpty) {
            try {
              // หา message แรกที่ไม่ใช่ของเรา (คือของลูกค้า)
              final otherMsg = messages.firstWhere(
                (m) => !_isMyMessage(m) && (m.senderPhoto?.isNotEmpty ?? false),
              );
              partnerPhoto = otherMsg.senderPhoto;
              print('✅ ตั้ง partnerPhoto จากข้อความของลูกค้า: $partnerPhoto');
            } catch (e) {
              print('⚠️ ไม่มีข้อความของลูกค้าให้ใช้เป็นรูป');
            }
          }
        });
      }

      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      print('❌ Error loading messages: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// ✅ แปลง messageData ทุกแบบให้เป็น Map<String, dynamic>
  ChatMessage _parseMessage(dynamic messageData) {
    try {
      if (messageData is Map) {
        return ChatMessage.fromJson(
          Map<String, dynamic>.from(
            messageData.map((k, v) => MapEntry(k.toString(), v)),
          ),
        );
      } else if (messageData is String) {
        final decoded = jsonDecode(messageData);
        return ChatMessage.fromJson(
          Map<String, dynamic>.from(
            decoded.map((k, v) => MapEntry(k.toString(), v)),
          ),
        );
      } else {
        throw Exception('Invalid message format: ${messageData.runtimeType}');
      }
    } catch (e) {
      print('⚠️ Error parsing message: $e');
      rethrow;
    }
  }

  void _onNewMessage(ChatMessage message) {
    if (mounted) {
      // ✅ ป้องกัน duplicate messages
      final isDuplicate = _messages.any((existingMessage) {
        // ตรวจสอบ message_id ก่อน
        if (existingMessage.messageId == message.messageId &&
            existingMessage.messageId != null &&
            message.messageId != null) {
          return true;
        }

        // ถ้าไม่มี message_id ให้ตรวจสอบเนื้อหาและเวลา
        return existingMessage.messageText == message.messageText &&
            existingMessage.senderId == message.senderId &&
            existingMessage.senderType == message.senderType &&
            _isMessageTimeSimilar(existingMessage.createdAt, message.createdAt);
      });

      if (!isDuplicate) {
        setState(() {
          _messages.add(message);
        });

        // Scroll to bottom for new messages
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        // Mark as read if message is not from current user
        if (!_isMyMessage(message)) {
          _markAsRead();
        }

        print('✅ New message added to UI');
      } else {
        print('🔄 Duplicate message ignored');
      }
    }
  }

  void _onUserTyping(Map<String, dynamic> data) {
    if (mounted && data['userId'] != userId) {
      setState(() {
        _isPartnerTyping = data['isTyping'] ?? false;
      });
    }
  }

  void _onConnectionChanged(bool connected) async {
    if (mounted) {
      setState(() {
        _isConnected = connected;
      });
    }

    if (!connected) {
      print('⚠️ Socket disconnected. Retrying in 3 seconds...');
      Future.delayed(const Duration(seconds: 3), () async {
        if (!_isConnected) {
          print('🔌 Attempting to reconnect socket...');
          await _chatService?.connectSocket(riderId!, userId!);

          if (roomId != null) {
            await _chatService?.joinRoom(roomId!);
            print('✅ Re-joined room after reconnect');
            await _loadInitialMessages();
          }
        }
      });
    }

    if (connected) {
      print('🔌 Socket reconnected! Re-joining room...');
      if (roomId != null) {
        await _chatService?.joinRoom(roomId!);
        print('✅ Re-joined room $roomId');
      }
      await _loadInitialMessages();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _markAsRead() {
    _chatService?.markAsRead();
  }

  // ✅ Helper function สำหรับเปรียบเทียบเวลาข้อความ
  bool _isMessageTimeSimilar(DateTime? time1, DateTime? time2) {
    if (time1 == null || time2 == null) return false;
    return (time1.difference(time2).abs().inSeconds < 5);
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _pendingImage == null) return;

    try {
      String? imageUrl;

      // Upload image if there's one
      if (_pendingImage != null) {
        setState(() {
          _isUploadingImage = true;
        });

        try {
          imageUrl = await _chatService!.uploadImage(_pendingImage!.path);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('ไม่สามารถอัพโลดรูปภาพได้: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            _isUploadingImage = false;
          });
          return;
        }

        setState(() {
          _isUploadingImage = false;
        });
      }

      final request = SendMessageRequest(
        roomId: roomId!,
        messageText: text.isEmpty ? null : text,
        messageType: _pendingImage != null ? 'image' : 'text',
        imageUrl: imageUrl,
      );

      await _chatService!.sendMessage(request);

      _controller.clear();
      setState(() {
        _pendingImage = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ส่งข้อความไม่สำเร็จ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (pickedFile != null) {
      setState(() {
        _pendingImage = File(pickedFile.path);
      });
    }
  }

  void _onTextChanged(String text) {
    if (text.isNotEmpty) {
      _chatService?.startTyping();

      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        _chatService?.stopTyping();
      });
    }
  }

  // ✅ ปรับปรุงการตรวจสอบข้อความของตัวเอง
  bool _isMyMessage(ChatMessage msg) {
    final senderType = (msg.senderType ?? '').toLowerCase();
    final senderId = msg.senderId?.toString();
    final myRiderId = riderId?.toString();
    final myUserId = userId?.toString();

    // Debug log
    print(
      "🧩 _isMyMessage check: senderType=$senderType, senderId=$senderId, riderId=$myRiderId, userId=$myUserId",
    );

    // ✅ ถ้าเราเป็นไรเดอร์
    if (userType == 'rider') {
      return senderType == 'rider' &&
          (senderId == myRiderId || senderId == myUserId);
    }

    // ✅ ถ้าเราเป็นลูกค้า (member หรือ customer)
    if (userType == 'customer' || userType == 'member') {
      return (senderType == 'customer' || senderType == 'member') &&
          (senderId == myUserId);
    }

    return false;
  }

  Widget _buildMessage(ChatMessage message) {
    final isOwnMessage = _isMyMessage(message);

    print('📨 Building message:');
    print(
      '   senderId: ${message.senderId}, senderType: ${message.senderType}',
    );
    print('   isOwnMessage: $isOwnMessage');

    final alignment = isOwnMessage
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final color = isOwnMessage ? Colors.green[300] : Colors.grey[300];
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(12),
      topRight: const Radius.circular(12),
      bottomLeft: isOwnMessage
          ? const Radius.circular(12)
          : const Radius.circular(0),
      bottomRight: isOwnMessage
          ? const Radius.circular(0)
          : const Radius.circular(12),
    );

    return Align(
      alignment: alignment,
      child: Row(
        mainAxisAlignment: isOwnMessage
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOwnMessage)
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 4),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[300],
                backgroundImage:
                    message.senderPhoto != null &&
                        message.senderPhoto!.isNotEmpty
                    ? NetworkImage(message.senderPhoto!)
                    : null,
                child:
                    (message.senderPhoto == null ||
                        message.senderPhoto!.isEmpty)
                    ? const Icon(Icons.person, size: 16, color: Colors.grey)
                    : null,
              ),
            ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
              minWidth: 48,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: EdgeInsets.only(
                left: isOwnMessage ? 40 : 2,
                right: isOwnMessage ? 2 : 40,
                top: 4,
                bottom: 4,
              ),
              decoration: BoxDecoration(
                color: color,
                borderRadius: borderRadius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.messageType == 'image' &&
                      message.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: message.imageUrl!.startsWith('http')
                          ? Image.network(
                              message.imageUrl!,
                              width: 180,
                              height: 180,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: 180,
                                      height: 180,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 180,
                                  height: 180,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.broken_image),
                                );
                              },
                            )
                          : Image.file(
                              File(message.imageUrl!),
                              width: 180,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                    ),
                  if (message.messageText?.isNotEmpty == true)
                    Padding(
                      padding: EdgeInsets.only(
                        top: message.messageType == 'image' ? 4 : 0,
                      ),
                      child: Text(
                        message.messageText!,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _formatMessageTime(message.createdAt),
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isOwnMessage) const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildTypingIndicator() {
    if (!_isPartnerTyping) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[300],
            backgroundImage: partnerPhoto != null
                ? NetworkImage(partnerPhoto!)
                : null,
            child: partnerPhoto == null
                ? const Icon(Icons.person, size: 16, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$partnerName กำลังพิมพ์',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 20,
                  height: 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(3, (index) {
                      return Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading until initialization is complete
    if (!_isInitialized || roomId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[300],
              backgroundImage: partnerPhoto != null
                  ? NetworkImage(partnerPhoto!)
                  : null,
              child: partnerPhoto == null
                  ? const Icon(Icons.person, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    partnerName ?? 'Unknown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'ออเดอร์ #$orderId',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isConnected)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () => _chatController?.makePhoneCall(partnerPhone),
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection status
          if (!_isConnected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.orange,
              child: const Text(
                'กำลังเชื่อมต่อ...',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),

          // Messages
          Expanded(
            child: _isLoading
                ? const LoadingWidget(message: 'กำลังโหลดข้อความ...')
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessage(_messages[index]);
                    },
                  ),
          ),

          // Input area
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.white,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Camera buttons
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.photo_camera,
                            color: Colors.green,
                          ),
                          onPressed: _isUploadingImage
                              ? null
                              : () => _pickImage(ImageSource.camera),
                        ),
                        IconButton(
                          icon: const Icon(Icons.photo, color: Colors.green),
                          onPressed: _isUploadingImage
                              ? null
                              : () => _pickImage(ImageSource.gallery),
                        ),
                      ],
                    ),
                  ),

                  // Text input with pending image
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_isUploadingImage)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'กำลังอัพโลดรูปภาพ...',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        if (_pendingImage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Center(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _pendingImage!,
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _pendingImage = null;
                                      });
                                    },
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        TextField(
                          controller: _controller,
                          onChanged: _onTextChanged,
                          decoration: InputDecoration(
                            hintText: 'พิมพ์ข้อความ...',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: Colors.green),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: Colors.green,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            isDense: true,
                          ),
                          maxLines: null,
                          enabled: !_isUploadingImage,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send button
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _isUploadingImage ? null : _sendMessage,
                      icon: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _connectionSubscription?.cancel();
    _chatService?.leaveRoom();
    super.dispose();
  }
}
