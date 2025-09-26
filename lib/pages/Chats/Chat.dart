// pages/rider_chat_page.dart (Fixed Final Version)
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:rider_delivery/APIs/ChatSocket/ChatControllerSK.dart';
import 'dart:io';
import 'package:rider_delivery/pages/Chats/models/ChatMessage.dart';
import 'package:rider_delivery/pages/Chats/widgets/loading_widget.dart';
import 'package:rider_delivery/services/ChatService.dart';

class RiderChatPage extends StatefulWidget {
  const RiderChatPage({super.key});

  @override
  State<RiderChatPage> createState() => _RiderChatPageState();
}

class _RiderChatPageState extends State<RiderChatPage>
    with WidgetsBindingObserver {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  // Navigation arguments
  Map<String, dynamic>? args;
  int? roomId;
  int? orderId;
  String? partnerName;
  String? partnerPhoto;
  String? partnerPhone;
  String? userType;
  int? userId; // user_id for socket authentication
  int? riderId; // rider_id for business logic

  // Services
  RiderChatController? _chatController;
  RiderChatService? _chatService;

  // UI states
  File? _pendingImage;
  bool _isLoading = false;
  bool _isConnected = false;
  bool _isPartnerTyping = false;
  bool _isUploadingImage = false;
  bool _isInitialized = false;
  bool _isJoinedRoom = false;

  // Timers and subscriptions
  Timer? _typingTimer;
  StreamSubscription<ChatMessage>? _messageSubscription;
  StreamSubscription<Map<String, dynamic>>? _typingSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<Map<String, dynamic>>? _readStatusSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeArguments();
      _initializeServices();
      _isInitialized = true;
    }
  }

  void _initializeArguments() {
    try {
      args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args == null) {
        print('❌ No arguments provided to RiderChatPage');
        return;
      }

      roomId = args!['roomId'] as int?;
      orderId = args!['orderId'] as int?;
      partnerName = args!['partnerName'] as String?;
      partnerPhoto = args!['partnerPhoto'] as String?;
      partnerPhone = args!['partnerPhone'] as String?;
      userType = args!['userType'] as String? ?? 'rider';
      userId = args!['userId'] as int?; // user_id for socket auth
      riderId = args!['riderId'] as int?; // rider_id for business logic

      print('🔍 Chat page initialized with:');
      print('   roomId: $roomId');
      print('   orderId: $orderId');
      print('   userId: $userId');
      print('   riderId: $riderId');
      print('   userType: $userType');
      print('   partnerName: $partnerName');
    } catch (e) {
      print('❌ Error initializing arguments: $e');
    }
  }

  Future<void> _initializeServices() async {
    if (roomId == null || userId == null || riderId == null) {
      print('❌ Missing required parameters for chat initialization');
      return;
    }

    try {
      _chatController = Provider.of<RiderChatController>(
        context,
        listen: false,
      );

      // Ensure controller is initialized
      await _chatController!.initializeRiderInfoIfNeeded();

      // Create new chat service instance for this chat room
      _chatService = RiderChatService();

      // Connect socket using riderId
      print('🔌 Connecting socket for riderId: $riderId');
      await _chatService!.connectSocket(riderId!);

      // Wait for socket connection with timeout
      int attempts = 0;
      const maxAttempts = 15; // 7.5 seconds total
      while (!_chatService!.isConnected && attempts < maxAttempts) {
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
        print(
          '⏳ Waiting for socket connection... attempt $attempts/$maxAttempts',
        );
      }

      if (_chatService!.isConnected) {
        print('✅ Socket connected, joining room $roomId');
        await _chatService!.joinRoom(roomId!);
        _isJoinedRoom = true;

        // Setup event listeners after successful connection
        _setupRealtimeListeners();

        // Load initial messages
        await _loadInitialMessages();

        // Mark messages as read
        _markAsRead();
      } else {
        print('⚠️ Socket connection timeout');
      }

      if (mounted) {
        setState(() => _isConnected = _chatService!.isConnected);
      }
    } catch (e) {
      print('❌ Error initializing services: $e');
    }
  }

  void _setupRealtimeListeners() {
    // Cancel existing subscriptions
    _cancelSubscriptions();

    if (_chatService == null) return;

    // Message stream
    _messageSubscription = _chatService!.messageStream.listen(
      _onNewMessage,
      onError: (error) => print('❌ Message stream error: $error'),
    );

    // Typing stream
    _typingSubscription = _chatService!.typingStream.listen(
      _onUserTyping,
      onError: (error) => print('❌ Typing stream error: $error'),
    );

    // Connection stream
    _connectionSubscription = _chatService!.connectionStream.listen(
      _onConnectionChanged,
      onError: (error) => print('❌ Connection stream error: $error'),
    );

    // Read status stream
    _readStatusSubscription = _chatService!.readStatusStream.listen(
      _onReadStatusChanged,
      onError: (error) => print('❌ Read status stream error: $error'),
    );
  }

  void _cancelSubscriptions() {
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _connectionSubscription?.cancel();
    _readStatusSubscription?.cancel();
    _typingTimer?.cancel();
  }

  Future<void> _loadInitialMessages() async {
    if (!mounted || roomId == null) return;

    setState(() => _isLoading = true);

    try {
      print('📥 Loading messages for room $roomId');
      final response = await _chatService!.getChatMessages(roomId!);

      List<ChatMessage> messages = [];
      if (response is Map && response['success'] == true) {
        final rawMessages = response['messages'] as List<dynamic>?;
        if (rawMessages != null) {
          for (var messageData in rawMessages) {
            try {
              final message = _parseMessage(messageData);
              messages.add(message);
            } catch (e) {
              print('⚠️ Failed to parse message: $e');
              print('Raw data: $messageData');
            }
          }
        }
      }

      // Sort messages by creation time
      messages.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return -1;
        if (b.createdAt == null) return 1;
        return a.createdAt!.compareTo(b.createdAt!);
      });

      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(messages);
          _isLoading = false;
        });

        print('✅ Loaded ${messages.length} messages');
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      print('❌ Error loading messages: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถโหลดข้อความได้: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  ChatMessage _parseMessage(dynamic messageData) {
    try {
      Map<String, dynamic> data;

      if (messageData is Map) {
        data = Map<String, dynamic>.from(messageData);
      } else if (messageData is String) {
        final decoded = jsonDecode(messageData);
        data = Map<String, dynamic>.from(decoded);
      } else {
        throw Exception('Invalid message format: ${messageData.runtimeType}');
      }

      // Map both snake_case and camelCase to standardized format
      final mappedData = {
        'message_id':
            data['message_id']?.toString() ?? data['messageId']?.toString(),
        'room_id':
            data['room_id']?.toString() ??
            data['roomId']?.toString() ??
            roomId.toString(),
        'sender_id': data['sender_id'] ?? data['senderId'],
        'sender_type':
            data['sender_type']?.toString() ?? data['senderType']?.toString(),
        'sender_name':
            data['sender_name']?.toString() ?? data['senderName']?.toString(),
        'sender_photo':
            data['sender_photo']?.toString() ?? data['senderPhoto']?.toString(),
        'message_text':
            data['message_text']?.toString() ?? data['messageText']?.toString(),
        'message_type':
            data['message_type']?.toString() ??
            data['messageType']?.toString() ??
            'text',
        'image_url':
            data['image_url']?.toString() ?? data['imageUrl']?.toString(),
        'latitude': data['latitude']?.toString(),
        'longitude': data['longitude']?.toString(),
        'is_read': data['is_read'] ?? data['isRead'] ?? false,
        'created_at':
            data['created_at']?.toString() ??
            data['createdAt']?.toString() ??
            DateTime.now().toIso8601String(),
        'updated_at':
            data['updated_at']?.toString() ??
            data['updatedAt']?.toString() ??
            data['created_at']?.toString() ??
            data['createdAt']?.toString(),
      };

      return ChatMessage.fromJson(mappedData);
    } catch (e) {
      print('⚠️ Error parsing message: $e');
      rethrow;
    }
  }

  void _onNewMessage(ChatMessage message) {
    if (!mounted) return;

    print(
      '📨 New message received: ${message.messageText?.substring(0, 50) ?? 'No text'}...',
    );
    print('📍 Message room: ${message.roomId}, Current room: $roomId');
    print('👤 Message sender: ${message.senderId} (${message.senderType})');

    // Check if message belongs to current room
    if (message.roomId?.toString() != roomId.toString()) {
      print('⚠️ Message not for current room, ignoring');
      return;
    }

    // Check for duplicate messages
    final isDuplicate = _messages.any((existingMessage) {
      // Check by message ID first
      if (existingMessage.messageId == message.messageId &&
          existingMessage.messageId != null &&
          message.messageId != null) {
        return true;
      }

      // If no message ID or they don't match, check content and time
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
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

      // Mark as read if message is not from current user
      if (!_isMyMessage(message)) {
        _markAsRead();
      }

      print('✅ New message added to UI');
    } else {
      print('🔄 Duplicate message ignored');
    }
  }

  bool _isMyMessage(ChatMessage message) {
    // For rider: check if sender_type is 'rider' and sender_id matches riderId
    return message.senderType == 'rider' &&
        message.senderId.toString() == riderId?.toString();
  }

  bool _isMessageTimeSimilar(DateTime? time1, DateTime? time2) {
    if (time1 == null || time2 == null) return false;
    return (time1.difference(time2).abs().inSeconds < 5);
  }

  void _onUserTyping(Map<String, dynamic> data) {
    final roomIdFromEvent = data['roomId']?.toString();
    final userIdFromEvent = data['userId']?.toString();
    final isTyping = data['isTyping'] ?? false;

    print(
      '⌨️ Typing event: room=$roomIdFromEvent, user=$userIdFromEvent, typing=$isTyping',
    );

    if (mounted &&
        roomIdFromEvent == roomId.toString() &&
        userIdFromEvent != userId.toString()) {
      // Compare with userId for socket auth
      setState(() {
        _isPartnerTyping = isTyping;
      });

      // Auto-stop typing after 3 seconds
      if (isTyping) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _isPartnerTyping) {
            setState(() {
              _isPartnerTyping = false;
            });
          }
        });
      }
    }
  }

  void _onConnectionChanged(bool connected) {
    if (mounted) {
      setState(() {
        _isConnected = connected;
      });

      if (connected && !_isJoinedRoom && roomId != null) {
        // Reconnected - rejoin room
        print('🔄 Reconnected, rejoining room $roomId');
        _chatService!.joinRoom(roomId!).then((_) {
          _isJoinedRoom = true;
        });
      }
    }
  }

  void _onReadStatusChanged(Map<String, dynamic> data) {
    print('👁️ Read status changed: $data');
    // Handle read status changes if needed
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
    if (_isConnected && _isJoinedRoom) {
      _chatService?.markAsRead();
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _pendingImage == null) return;

    try {
      String? imageUrl;

      // Upload image if there's one
      if (_pendingImage != null) {
        setState(() => _isUploadingImage = true);

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
          setState(() => _isUploadingImage = false);
          return;
        } finally {
          setState(() => _isUploadingImage = false);
        }
      }

      // Clear input and stop typing immediately
      final messageToSend = text;
      _controller.clear();
      _chatService?.stopTyping();

      // Create message request
      final request = SendMessageRequest(
        roomId: roomId!,
        messageText: messageToSend.isEmpty ? null : messageToSend,
        messageType: _pendingImage != null ? 'image' : 'text',
        imageUrl: imageUrl,
      );

      // Send message
      await _chatService!.sendMessage(request);

      setState(() {
        _pendingImage = null;
      });

      print('✅ Message sent successfully');
    } catch (e) {
      print('❌ Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ส่งข้อความไม่สำเร็จ: $e'),
            backgroundColor: Colors.red,
          ),
        );

        // Restore text if sending failed
        if (text.isNotEmpty && _controller.text.isEmpty) {
          _controller.text = text;
        }
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
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
    } catch (e) {
      print('❌ Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถเลือกรูปภาพได้: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onTextChanged(String text) {
    if (text.isNotEmpty && _isConnected && _isJoinedRoom) {
      _chatService?.startTyping();

      // Cancel previous timer
      _typingTimer?.cancel();

      // Stop typing after 2 seconds of inactivity
      _typingTimer = Timer(const Duration(seconds: 2), () {
        _chatService?.stopTyping();
      });
    }
  }

  Widget _buildMessage(ChatMessage message) {
    final isOwnMessage = _isMyMessage(message);
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

  String _formatMessageTime(DateTime? dateTime) {
    if (dateTime == null) return '';

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
            backgroundImage: partnerPhoto != null && partnerPhoto!.isNotEmpty
                ? NetworkImage(partnerPhoto!)
                : null,
            child: (partnerPhoto == null || partnerPhoto!.isEmpty)
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

  Widget _buildImagePreview() {
    if (_pendingImage == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              _pendingImage!,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('รูปภาพที่เลือก', style: TextStyle(fontSize: 14)),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _pendingImage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          _buildImagePreview(),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.photo),
                onPressed: _isUploadingImage
                    ? null
                    : () => _showImageSourceDialog(),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: _onTextChanged,
                  decoration: InputDecoration(
                    hintText: 'พิมพ์ข้อความ...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 8),
              _isUploadingImage
                  ? const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
            ],
          ),
        ],
      ),
    );
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เลือกที่มาของรูปภาพ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('ถ่าย��ูป'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('เลือกจากแกลเลอรี'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _isJoinedRoom) {
      _markAsRead();
    }
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
              backgroundImage: partnerPhoto != null && partnerPhoto!.isNotEmpty
                  ? NetworkImage(partnerPhoto!)
                  : null,
              child: (partnerPhoto == null || partnerPhoto!.isEmpty)
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
              color: Colors.red,
              padding: const EdgeInsets.all(8),
              child: const Text(
                'กำลังเชื่อมต่อ...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),

          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? const Center(
                    child: Text(
                      'ยังไม่มีข้อความ\nเริ่มสนทนากับลูกค้าได้เลย',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessage(_messages[index]);
                    },
                  ),
          ),

          // Typing indicator
          _buildTypingIndicator(),

          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    print('🗑️ Disposing RiderChatPage');

    WidgetsBinding.instance.removeObserver(this);

    // Stop typing
    _chatService?.stopTyping();

    // Leave room
    if (_isJoinedRoom && roomId != null) {
      _chatService?.leaveRoom();
    }

    // Cancel subscriptions and timers
    _cancelSubscriptions();

    // Dispose controllers
    _controller.dispose();
    _scrollController.dispose();

    // Dispose chat service
    _chatService?.dispose();

    super.dispose();
  }
}
