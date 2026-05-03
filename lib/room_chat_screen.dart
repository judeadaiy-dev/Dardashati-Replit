import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';
import 'services/database_service.dart';
import 'mock_data.dart';
import 'profile_screen.dart';

class RoomChatScreen extends StatefulWidget {
  final AppRoom room;
  final AppUser currentUser;
  final AppThemeData theme;
  const RoomChatScreen({required this.room, required this.currentUser, required this.theme});

  @override
  State<RoomChatScreen> createState() => _RoomChatScreenState();
}

class _RoomChatScreenState extends State<RoomChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  List<AppMessage> _messages = [];
  AppMessage? _replyTo;
  RealtimeChannel? _channel;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeRealtime();
    DatabaseService.joinRoom(widget.room.id);
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await DatabaseService.getRoomMessages(widget.room.id);
      if (mounted) setState(() { _messages = msgs; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _messages = List.from(mockMessages); _loading = false; });
    }
    _scrollToBottom();
  }

  void _subscribeRealtime() {
    _channel = DatabaseService.subscribeToRoomMessages(widget.room.id, (record) async {
      // جلب الرسالة الكاملة مع بيانات المرسل
      try {
        final msgs = await DatabaseService.getRoomMessages(widget.room.id);
        if (mounted) { setState(() => _messages = msgs); _scrollToBottom(); }
      } catch (_) {
        // أضف الرسالة مبدئياً بدون بيانات كاملة
        final msg = AppMessage(
          id: record['id'] ?? '', senderId: record['sender_id'] ?? '',
          senderName: '', senderAvatar: '', content: record['content'] ?? '',
          time: DateTime.tryParse(record['created_at'] ?? '') ?? DateTime.now(),
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
      await DatabaseService.sendRoomMessage(roomId: widget.room.id, content: text, replyToId: replyId);
    } catch (_) {
      // أضف الرسالة محلياً كـ fallback
      setState(() {
        _messages.add(AppMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: widget.currentUser.id, senderName: widget.currentUser.fullName,
          senderAvatar: widget.currentUser.avatarUrl, content: text,
          time: DateTime.now(), replyToContent: _replyTo?.content,
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
        title: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: t.button.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(widget.room.icon, style: const TextStyle(fontSize: 20)))),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.room.name, style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 15)),
            Text(widget.room.membersCountLabel, style: TextStyle(color: t.text.withOpacity(0.5), fontSize: 11)),
          ]),
        ]),
        actions: [IconButton(icon: Icon(Icons.people_alt_outlined, color: t.text.withOpacity(0.7)), onPressed: () => _showMembers(context, t))],
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
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: msg.senderId, currentUserId: widget.currentUser.id, theme: t))),
                child: CircleAvatar(backgroundImage: msg.senderAvatar.isNotEmpty ? NetworkImage(msg.senderAvatar) : null, radius: 16, backgroundColor: t.button.withOpacity(0.2), child: msg.senderAvatar.isEmpty ? Text(msg.senderName.isNotEmpty ? msg.senderName[0] : '?', style: TextStyle(color: t.button, fontSize: 12)) : null),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe && msg.senderName.isNotEmpty)
                  Padding(padding: const EdgeInsets.only(bottom: 4, right: 4, left: 4), child: Text(msg.senderName, style: TextStyle(color: t.button, fontSize: 11, fontWeight: FontWeight.bold))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? t.button : t.card,
                    borderRadius: BorderRadius.only(topLeft: const Radius.circular(18), topRight: const Radius.circular(18), bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4), bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18)),
                    border: isMe ? null : Border.all(color: t.text.withOpacity(0.08)),
                  ),
                  child: Column(crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
                    if (msg.replyToContent != null)
                      Container(
                        padding: const EdgeInsets.all(8), margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(color: isMe ? Colors.white.withOpacity(0.15) : t.button.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border(right: BorderSide(color: isMe ? Colors.white.withOpacity(0.5) : t.button, width: 3))),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if (msg.replyToSender != null) Text(msg.replyToSender!, style: TextStyle(color: isMe ? Colors.white.withOpacity(0.8) : t.button, fontSize: 10, fontWeight: FontWeight.bold)),
                          Text(msg.replyToContent!, style: TextStyle(color: isMe ? Colors.white.withOpacity(0.7) : t.text.withOpacity(0.6), fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ]),
                      ),
                    if (msg.isAudio)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.play_circle_filled, color: isMe ? Colors.white : t.button, size: 28),
                        const SizedBox(width: 8),
                        Container(width: 100, height: 4, decoration: BoxDecoration(color: (isMe ? Colors.white : t.button).withOpacity(0.4), borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 8),
                        Text(msg.audioDuration ?? '0:00', style: TextStyle(color: isMe ? Colors.white.withOpacity(0.7) : t.text.withOpacity(0.5), fontSize: 11)),
                      ])
                    else
                      Text(msg.content, style: TextStyle(color: isMe ? Colors.white : t.text, fontSize: 14)),
                  ]),
                ),
                Padding(padding: const EdgeInsets.only(top: 4, right: 4, left: 4), child: Text(msg.formattedTime, style: TextStyle(color: t.text.withOpacity(0.3), fontSize: 10))),
              ],
            )),
          ],
        ),
      ),
    );
  }

  Widget _replyBar(AppThemeData t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: t.menu,
      child: Row(children: [
        Container(width: 3, height: 36, color: t.button),
        const SizedBox(width: 10),
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
          child: Row(children: [
            Expanded(child: TextField(controller: _ctrl, style: TextStyle(color: t.text, fontSize: 14), maxLines: null, textAlign: TextAlign.right, decoration: InputDecoration(hintText: 'اكتب رسالة...', hintStyle: TextStyle(color: t.text.withOpacity(0.3)), border: InputBorder.none), onSubmitted: (_) => _send())),
            Icon(Icons.emoji_emotions_outlined, color: t.text.withOpacity(0.4), size: 22),
          ]),
        )),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _send,
          child: Container(width: 48, height: 48, decoration: BoxDecoration(color: t.button, shape: BoxShape.circle, boxShadow: [BoxShadow(color: t.button.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]), child: _sending ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: t.buttonText, strokeWidth: 2)) : Icon(Icons.send_rounded, color: t.buttonText, size: 22)),
        ),
      ]),
    );
  }

  void _showMembers(BuildContext context, AppThemeData t) async {
    final members = await DatabaseService.getRoomMembers(widget.room.id).catchError((_) => mockUsers);
    if (!mounted) return;
    showModalBottomSheet(
      context: context, backgroundColor: t.menu,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: t.text.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Text('أعضاء الغرفة', style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Expanded(child: ListView.builder(
          itemCount: members.length,
          itemBuilder: (ctx, i) {
            final u = members[i];
            return ListTile(
              leading: Stack(children: [
                CircleAvatar(backgroundImage: u.avatarUrl.isNotEmpty ? NetworkImage(u.avatarUrl) : null, radius: 22, backgroundColor: t.button.withOpacity(0.2)),
                if (u.isOnline) Positioned(bottom: 0, right: 0, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: t.menu, width: 2)))),
              ]),
              title: Text(u.fullName, style: TextStyle(color: t.text, fontWeight: FontWeight.bold)),
              subtitle: Text(u.isOnline ? 'متصل' : 'غير متصل', style: TextStyle(color: u.isOnline ? Colors.green : t.text.withOpacity(0.4), fontSize: 12)),
            );
          },
        )),
      ]),
    );
  }
}
