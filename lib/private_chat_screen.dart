import 'package:dardashati/extensions.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:blur/blur.dart'; // المكتبة التي أضفناها للتأثير الزجاجي

// استخدام المسار الجديد المعتمد للمشروع
import 'package:dardashati/models.dart'; 
import 'package:dardashati/services/database_service.dart';
import 'package:dardashati/profile_screen.dart'; 

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
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadInitialMessages();
    _markAsRead();
  }

  // ماركة الرسائل كمقروءة فور الدخول
  void _markAsRead() {
    DatabaseService.markPrivateMessagesRead(widget.otherUserId);
  }

  // تحميل الرسائل واستخدام الـ Stream للبقاء على اتصال دائم (مثل تليجرام)
  void _loadInitialMessages() async {
    // هذه الدالة تجلب الرسائل القديمة مرة واحدة ثم نعتمد على الـ Stream
    final msgs = await DatabaseService.getPrivateMessages(widget.otherUserId);
    if (mounted) {
      setState(() {
        _messages = msgs;
        _loading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Scaffold(
      backgroundColor: t.background,
      // AppBar بنظام Glassmorphism
      appBar: AppBar(
        flexibleSpace: Container().frozen(blur: 10, color: t.menu.withOpacity(0.7)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: t.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: _buildAppBarTitle(t),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  // نستخدم الـ Stream الذي صنعناه في DatabaseService لسرعة الاستجابة
                  stream: DatabaseService.getMessagesStream(widget.otherUserId),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      // تحويل البيانات القادمة من Stream إلى قائمة رسائل
                      final newMessages = snapshot.data!
                          .map((m) => AppMessage.fromMap(m))
                          .toList();
                      return ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(15),
                        itemCount: newMessages.length,
                        itemBuilder: (ctx, i) => _buildMessageBubble(newMessages[i], t),
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
              if (_replyTo != null) _buildReplyPreview(t),
              _buildInputArea(t),
            ],
          ),
        ],
      ),
    );
  }

  // تصميم الفقاعة (Bubble) بلمسة راقية
  Widget _buildMessageBubble(AppMessage msg, AppThemeData t) {
    final isMe = msg.senderId == widget.currentUser.id;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? t.button : t.card.withOpacity(0.8),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 5),
            bottomRight: Radius.circular(isMe ? 5 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Text(
          msg.content,
          style: TextStyle(
            color: isMe ? t.buttonText : t.text,
            fontSize: 15,
            fontFamily: 'Tajawal', // استخدام الخط العربي الذي أضفناه
          ),
          textAlign: TextAlign.right,
        ),
      ),
    );
  }

  Widget _buildInputArea(AppThemeData t) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: t.menu.withOpacity(0.8),
      ).frozen(blur: 15), // تأثير زجاجي لمنطقة الكتابة
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              style: TextStyle(color: t.text),
              decoration: InputDecoration(
                hintText: "اكتب رسالة...",
                hintStyle: TextStyle(color: t.text.withOpacity(0.5)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          CircleAvatar(
            backgroundColor: t.button,
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: () async {
                if (_ctrl.text.isNotEmpty) {
                  final content = _ctrl.text;
                  _ctrl.clear();
                  await DatabaseService.sendMessage(widget.otherUserId, content);
                  _scrollToBottom();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // عنوان الـ AppBar مع حالة المتصل
  Widget _buildAppBarTitle(AppThemeData t) {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: widget.otherUserAvatar.isNotEmpty 
            ? NetworkImage(widget.otherUserAvatar) 
            : null,
          radius: 18,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName, 
              style: TextStyle(color: t.text, fontSize: 16, fontWeight: FontWeight.bold)),
            Text("متصل الآن", 
              style: TextStyle(color: Colors.green, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}
