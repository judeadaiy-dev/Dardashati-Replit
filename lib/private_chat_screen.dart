import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// الحل الاحترافي: المسارات الصحيحة حسب هيكلة مشروعك
import 'package:tik_chat_app/models.dart'; 
import 'package:tik_chat_app/services/database_service.dart';
import 'package:tik_chat_app/profile_screen.dart'; 

class PrivateChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String otherUserAvatar;
  final AppUser currentUser;
  final AppThemeData theme;

  const PrivateChatScreen({
    super.key, 
    required this.otherUserId, 
    required this.otherUserName, 
    required this.otherUserAvatar, 
    required this.currentUser, 
    required this.theme
  });

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  List<AppMessage> _messages = [];
  AppMessage? _replyTo;
  RealtimeChannel? _channel;
  bool _loading = true;
  bool _sending = false;
  bool _otherOnline = false;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeRealtime();
    _checkOnlineStatus();
    DatabaseService.markPrivateMessagesRead(widget.otherUserId);
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final msgs = await DatabaseService.getPrivateMessages(widget.otherUserId);
      if (mounted) setState(() { _messages = msgs; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; });
      debugPrint("Error loading messages: $e");
    }
    _scrollToBottom();
  }

  Future<void> _checkOnlineStatus() async {
    try {
      final user = await DatabaseService.getUserById(widget.otherUserId);
      if (mounted && user != null) setState(() => _otherOnline = user.isOnline);
    } catch (_) {}
  }

  void _subscribeRealtime() {
    // استخدام الدالة الاحترافية التي أضفناها في DatabaseService
    _channel = DatabaseService.subscribeToPrivateMessages(widget.otherUserId, (record) {
      if (mounted) {
        setState(() {
          _messages.add(AppMessage.fromMap(record));
        });
        _scrollToBottom();
        DatabaseService.markPrivateMessagesRead(widget.otherUserId);
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent, 
          duration: const Duration(milliseconds: 300), 
          curve: Curves.easeOut
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    final replyId = _replyTo?.id;
    _ctrl.clear();
    setState(() => _replyTo = null);

    try {
      await DatabaseService.sendPrivateMessage(
        receiverId: widget.otherUserId, 
        content: text, 
        replyToId: replyId
      );
      // في حالة النجاح، الـ Realtime سيتكفل بإضافة الرسالة للقائمة
    } catch (e) {
      debugPrint("Send error: $e");
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.menu, 
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: t.text), 
          onPressed: () => Navigator.pop(context)
        ),
        title: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: widget.otherUserId, currentUserId: widget.currentUser.id, theme: t))),
          child: Row(children: [
            Stack(children: [
              CircleAvatar(
                backgroundImage: widget.otherUserAvatar.isNotEmpty ? NetworkImage(widget.otherUserAvatar) : null, 
                radius: 18, 
                backgroundColor: t.button.withOpacity(0.2), 
                child: widget.otherUserAvatar.isEmpty ? Text(widget.otherUserName[0], style: TextStyle(color: t.button)) : null
              ),
              if (_otherOnline) Positioned(bottom: 0, right: 0, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: t.menu, width: 2)))),
            ]),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.otherUserName, style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 15)),
              Text(_otherOnline ? 'متصل الآن' : 'غير متصل', style: TextStyle(color: _otherOnline ? Colors.green : t.text.withOpacity(0.4), fontSize: 11)),
            ]),
          ]),
        ),
      ),
      body: Column(children: [
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: t.button))
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  itemCount: _messages.length,
                  itemBuilder: (ctx, i) => _bubble(_messages[i], t),
                ),
        ),
        if (_replyTo != null) _replyBar(t),
        _inputBar(t),
      ]),
    );
  }

  Widget _bubble(AppMessage msg, AppThemeData t) {
    final isMe = msg.senderId == widget.currentUser.id;
    return GestureDetector(
      onLongPress: () => setState(() => _replyTo = msg),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                backgroundImage: msg.senderAvatar != null ? NetworkImage(msg.senderAvatar!) : null, 
                radius: 14, 
                backgroundColor: t.button.withOpacity(0.2)
              ), 
              const SizedBox(width: 8)
            ],
            Flexible(child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? t.button : t.card,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18), 
                      topRight: const Radius.circular(18), 
                      bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4), 
                      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18)
                    ),
                  ),
                  child: Text(msg.content, style: TextStyle(color: isMe ? t.buttonText : t.text, fontSize: 14)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    "${msg.time.hour}:${msg.time.minute.toString().padLeft(2, '0')}", 
                    style: TextStyle(color: t.text.withOpacity(0.3), fontSize: 10)
                  )
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }

  Widget _replyBar(AppThemeData t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), color: t.menu,
      child: Row(children: [
        Container(width: 3, height: 36, color: t.button), const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('رداً على', style: TextStyle(color: t.button, fontSize: 11, fontWeight: FontWeight.bold)),
          Text(_replyTo!.content, style: TextStyle(color: t.text.withOpacity(0.6), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        IconButton(icon: Icon(Icons.close, color: t.text.withOpacity(0.5), size: 20), onPressed: () => setState(() => _replyTo = null)),
      ]),
    );
  }

  Widget _inputBar(AppThemeData t) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 16 + MediaQuery.of(context).padding.bottom / 2),
      color: t.menu,
      child: Row(children: [
        Expanded(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: t.text.withOpacity(0.08))),
          child: TextField(
            controller: _ctrl, 
            style: TextStyle(color: t.text, fontSize: 14), 
            textAlign: TextAlign.right, 
            maxLines: null, 
            decoration: InputDecoration(hintText: 'اكتب رسالة...', hintStyle: TextStyle(color: t.text.withOpacity(0.3)), border: InputBorder.none),
          ),
        )),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _send,
          child: Container(
            width: 48, height: 48, 
            decoration: BoxDecoration(color: t.button, shape: BoxShape.circle), 
            child: _sending 
              ? Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: t.buttonText, strokeWidth: 2))) 
              : Icon(Icons.send_rounded, color: t.buttonText, size: 22)
          ),
        ),
      ]),
    );
  }
}

