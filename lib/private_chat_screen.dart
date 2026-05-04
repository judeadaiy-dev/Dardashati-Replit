import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// الحل الاحترافي: استخدم المسار الكامل للمشروع دائماً
import 'package:tik_chat_app/models.dart'; 
import 'package:tik_chat_app/services/database_service.dart';
import 'package:tik_chat_app/profile_screen.dart'; // تأكد من المسار الصحيح لهذا الملف أيضاً


class PrivateChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String otherUserAvatar;
  final AppUser currentUser;
  final AppThemeData theme;
  const PrivateChatScreen({required this.otherUserId, required this.otherUserName, required this.otherUserAvatar, required this.currentUser, required this.theme});

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
    } catch (_) {
      if (mounted) setState(() {
        _messages = [
          AppMessage(id: '1', senderId: widget.otherUserId, senderName: widget.otherUserName, senderAvatar: widget.otherUserAvatar, content: 'أهلاً! كيف حالك؟', time: DateTime.now().subtract(const Duration(minutes: 10))),
          AppMessage(id: '2', senderId: widget.currentUser.id, senderName: widget.currentUser.fullName, senderAvatar: widget.currentUser.avatarUrl, content: 'بخير الحمد لله، وأنت؟', time: DateTime.now().subtract(const Duration(minutes: 8))),
        ];
        _loading = false;
      });
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
    _channel = DatabaseService.subscribeToPrivateMessages(widget.otherUserId, (record) async {
      try {
        final msgs = await DatabaseService.getPrivateMessages(widget.otherUserId);
        if (mounted) { setState(() => _messages = msgs); _scrollToBottom(); }
        DatabaseService.markPrivateMessagesRead(widget.otherUserId);
      } catch (_) {
        final msg = AppMessage(
          id: record['id'] ?? '', senderId: record['sender_id'] ?? '',
          senderName: widget.otherUserName, senderAvatar: widget.otherUserAvatar,
          content: record['content'] ?? '', time: DateTime.tryParse(record['created_at'] ?? '') ?? DateTime.now(),
        );
        if (mounted) { setState(() => _messages.add(msg)); _scrollToBottom(); }
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _ctrl.clear();
    final replyId = _replyTo?.id;
    setState(() => _replyTo = null);
    try {
      await DatabaseService.sendPrivateMessage(receiverId: widget.otherUserId, content: text, replyToId: replyId);
    } catch (_) {
      setState(() {
        _messages.add(AppMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: widget.currentUser.id, senderName: widget.currentUser.fullName,
          senderAvatar: widget.currentUser.avatarUrl, content: text, time: DateTime.now(),
        ));
      });
      _scrollToBottom();
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.menu, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: t.text), onPressed: () => Navigator.pop(context)),
        title: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: widget.otherUserId, currentUserId: widget.currentUser.id, theme: t))),
          child: Row(children: [
            Stack(children: [
              CircleAvatar(backgroundImage: widget.otherUserAvatar.isNotEmpty ? NetworkImage(widget.otherUserAvatar) : null, radius: 18, backgroundColor: t.button.withOpacity(0.2), child: widget.otherUserAvatar.isEmpty ? Text(widget.otherUserName[0], style: TextStyle(color: t.button)) : null),
              if (_otherOnline) Positioned(bottom: 0, right: 0, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: t.menu, width: 2)))),
            ]),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.otherUserName, style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 15)),
              Text(_otherOnline ? 'متصل الآن' : 'غير متصل', style: TextStyle(color: _otherOnline ? Colors.green : t.text.withOpacity(0.4), fontSize: 11)),
            ]),
          ]),
        ),
        actions: [
          IconButton(icon: Icon(Icons.call_outlined, color: t.text.withOpacity(0.7)), onPressed: () {}),
          IconButton(icon: Icon(Icons.videocam_outlined, color: t.text.withOpacity(0.7)), onPressed: () {}),
        ],
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
            if (!isMe) ...[CircleAvatar(backgroundImage: widget.otherUserAvatar.isNotEmpty ? NetworkImage(widget.otherUserAvatar) : null, radius: 14, backgroundColor: t.button.withOpacity(0.2)), const SizedBox(width: 8)],
            Flexible(child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (msg.replyToContent != null)
                  Container(margin: const EdgeInsets.only(bottom: 4), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: t.button.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border(right: BorderSide(color: t.button, width: 3))),
                    child: Text(msg.replyToContent!, style: TextStyle(color: t.text.withOpacity(0.5), fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? t.button : t.card,
                    borderRadius: BorderRadius.only(topLeft: const Radius.circular(18), topRight: const Radius.circular(18), bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4), bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18)),
                    border: isMe ? null : Border.all(color: t.text.withOpacity(0.08)),
                  ),
                  child: Text(msg.content, style: TextStyle(color: isMe ? t.buttonText : t.text, fontSize: 14)),
                ),
                Padding(padding: const EdgeInsets.only(top: 4), child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(msg.formattedTime, style: TextStyle(color: t.text.withOpacity(0.3), fontSize: 10)),
                  if (isMe) ...[const SizedBox(width: 4), Icon(Icons.done_all, size: 14, color: t.button)],
                ])),
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
          child: TextField(controller: _ctrl, style: TextStyle(color: t.text, fontSize: 14), textAlign: TextAlign.right, maxLines: null, decoration: InputDecoration(hintText: 'اكتب رسالة...', hintStyle: TextStyle(color: t.text.withOpacity(0.3)), border: InputBorder.none), onSubmitted: (_) => _send()),
        )),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _send,
          child: Container(width: 48, height: 48, decoration: BoxDecoration(color: t.button, shape: BoxShape.circle, boxShadow: [BoxShadow(color: t.button.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]), child: _sending ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: t.buttonText, strokeWidth: 2)) : Icon(Icons.send_rounded, color: t.buttonText, size: 22)),
        ),
      ]),
    );
  }
}
