dart
flexibleSpace: ClipRRect(
  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
  child: Container(
    decoration: BoxDecoration(
      color: t.menu.withOpacity(0.7),
      backdropFilter: ImageFilters.blur(sigmaX: 10, sigmaY: 10),
    ),
  ),
),
```

And line 166, change:
```dart
).frozen(blur: 15), // تأثير زجاجي لمنطقة الكتابة
```

To:
```dart
),
```

Also add this method before the closing brace of `_PrivateChatScreenState`:
```dart
  // ✅ ADD THIS METHOD
  Widget _buildReplyPreview(AppThemeData t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: t.card.withOpacity(0.5),
        border: Border(
          left: BorderSide(color: t.button, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الرد على: ${_replyTo?.senderName ?? "مستخدم"}',
                  style: TextStyle(
                    color: t.button,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _replyTo?.content ?? '',
                  style: TextStyle(color: t.text, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: t.text.withOpacity(0.5)),
            onPressed: () => setState(() => _replyTo = null),
          ),
        ],
      ),
    );
  }
```

Don't forget to add the import at the top:
```dart
import 'dart:ui' as ui;
import 'dart:ui';
```

---

### **4. lib/profile_screen.dart** - Fix `CrossAxisAlignment.right`

Line 242, change:
```dart
child: Column(crossAxisAlignment: CrossAxisAlignment.right, children: [
```

To:
```dart
child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
```

---

## Summary of Changes:

| File | Changes |
|------|---------|
| `models.dart` | Added `label`, `primaryColor`, `gradientColors`, `accent` to `AppThemeData`; Changed `isRead` from final to mutable in `AppNotification` |
| `database_service.dart` | Added `AppRoom` class; Fixed `$uid` → `$_uid`; Added 7 missing methods |
| `private_chat_screen.dart` | Fixed `.frozen()` calls; Added `_buildReplyPreview()` method |
| `profile_screen.dart` | Changed `CrossAxisAlignment.right` → `CrossAxisAlignment.end` |

Once you make these changes, commit and push them. The build should pass! 🎉
