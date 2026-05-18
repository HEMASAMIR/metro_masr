import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';

class MetroChatScreen extends StatefulWidget {
  final String roomId;
  final String roomName;
  final String userName;

  const MetroChatScreen({Key? key, required this.roomId, required this.roomName, required this.userName}) : super(key: key);

  @override
  State<MetroChatScreen> createState() => _MetroChatScreenState();
}

class _MetroChatScreenState extends State<MetroChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> messages = [];
  final ScrollController _scrollController = ScrollController();
  bool isConnecting = true;
  late RealtimeChannel _channel;

  @override
  void initState() {
    super.initState();
    _connectSupabaseDatabase();
  }

  void _connectSupabaseDatabase() {
    // 1. تحميل الرسائل القديمة
    _loadPreviousMessages();

    // 2. الاستماع لأي رسالة جديدة تضاف في الداتابيز
    _channel = Supabase.instance.client
        .channel('public:messages:${widget.roomId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: widget.roomId,
          ),
          callback: (payload) {
            if (mounted) {
              setState(() {
                messages.add(Map<String, dynamic>.from(payload.newRecord));
              });
              _scrollToBottom();
            }
          },
        )
        .subscribe((status, [error]) {
          if (status == 'SUBSCRIBED') {
            if (mounted) {
              setState(() {
                isConnecting = false;
              });
            }
          } else if (status == 'CLOSED' || status == 'CHANNEL_ERROR') {
            if (mounted) {
              setState(() {
                isConnecting = true;
              });
            }
          }
        });
  }

  Future<void> _loadPreviousMessages() async {
    try {
      final response = await Supabase.instance.client
          .from('messages')
          .select()
          .eq('room_id', widget.roomId)
          .order('created_at', ascending: true)
          .limit(100);

      if (mounted) {
        setState(() {
          messages = List<Map<String, dynamic>>.from(response);
          // إذا انتهى التحميل ولم يتم الاتصال بالـ realtime بعد
          if (isConnecting) isConnecting = false; 
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  Future<void> _sendMessage({String? text, String? imageBase64, String type = 'text'}) async {
    if (text == null && imageBase64 == null) return;
    if (text != null && text.trim().isEmpty && imageBase64 == null) return;

    final messageData = {
      'room_id': widget.roomId,
      'sender': widget.userName,
      'text': text,
      'image_base64': imageBase64,
      'type': type,
    };

    _messageController.clear();

    try {
      await Supabase.instance.client.from('messages').insert(messageData);
      // الرسالة ستعود تلقائياً عبر PostgresChanges ولن نحتاج لإضافتها محلياً
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل إرسال الرسالة، تأكد من الاتصال')));
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _showUserProfile(BuildContext context, String userName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.indigo.shade100,
                  child: const Icon(Icons.person, size: 40, color: Colors.indigo),
                ),
                const SizedBox(height: 16),
                Text(userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('راكب موثق في مترو مصر 🇪🇬', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سيتم تفعيل المحادثة الخاصة قريباً')));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.chat),
                      label: const Text('محادثة خاصة'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.report),
                      label: const Text('إبلاغ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      }
    );
  }

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(_channel);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.roomName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
            if (isConnecting)
              const Text('جاري تحميل الرسائل...', style: TextStyle(fontSize: 11, color: Colors.orangeAccent)),
            if (!isConnecting)
              const Text('متصل Live ⚡', style: TextStyle(fontSize: 11, color: Colors.greenAccent)),
          ],
        ),
        backgroundColor: Colors.indigo,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Expanded(
              child: isConnecting && messages.isEmpty
                ? _buildShimmerLoading() 
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg['sender'] == widget.userName;
                      return _buildAnimatedMessageBubble(msg, isMe);
                    },
                  ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        bool isMe = index % 2 == 0;
        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: MediaQuery.of(context).size.width * 0.6,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedMessageBubble(Map<String, dynamic> msg, bool isMe) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          alignment: isMe ? Alignment.bottomRight : Alignment.bottomLeft,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: isMe ? Colors.indigo : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isMe ? const Radius.circular(0) : const Radius.circular(16),
              bottomRight: isMe ? const Radius.circular(16) : const Radius.circular(0),
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe)
                GestureDetector(
                  onTap: () => _showUserProfile(context, msg['sender'] ?? 'مجهول'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.indigo.withOpacity(0.1),
                        child: const Icon(Icons.person, size: 14, color: Colors.indigo),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        msg['sender'] ?? 'مجهول',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.indigo, decoration: TextDecoration.underline),
                      ),
                    ],
                  ),
                ),
              if (!isMe) const SizedBox(height: 6),
              if (msg['type'] == 'image' && msg['image_base64'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    base64Decode(msg['image_base64']),
                    fit: BoxFit.cover,
                  ),
                ),
              if (msg['text'] != null && msg['text'].toString().isNotEmpty)
                Text(
                  msg['text'],
                  style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isConnecting ? Colors.grey : Colors.indigo,
              radius: 24,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: isConnecting ? null : () => _sendMessage(text: _messageController.text),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  enabled: !isConnecting,
                  decoration: const InputDecoration(
                    hintText: 'شارك حالة المترو أو المفقودات...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.camera_alt_outlined, color: isConnecting ? Colors.grey : Colors.indigo, size: 28),
              onPressed: isConnecting ? null : () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سيتم تفعيل رفع الصور لاحقاً')));
              },
            ),
          ],
        ),
      ),
    );
  }
}
