# 📸 DEMO: REPLY FEATURE VISUALIZATION

## 🎬 Kịch bản Demo

**Alice và Bob đang chat trong group "Team Project"**

---

## 📱 Bước 1: Alice gửi tin nhắn gốc

```
┌─────────────────────────────────────┐
│ Team Project                    🔗  │
├─────────────────────────────────────┤
│                                     │
│ 👤 Alice                           │
│ ┌─────────────────────────────────┐ │
│ │ Các bạn có ý kiến gì về design │ │
│ │ mới không?                      │ │
│ │                       10:15 AM │ │
│ └─────────────────────────────────┘ │
│ [2 Replies] [↩️ Reply]             │
│                                     │
└─────────────────────────────────────┘
```

---

## 📱 Bước 2: Bob nhấn Reply

```
┌─────────────────────────────────────┐
│ Team Project                ❌ Clear│
├─────────────────────────────────────┤
│ 👤 Alice                           │
│ ┌─────────────────────────────────┐ │
│ │ Các bạn có ý kiến gì về design │ │
│ │ mới không?                      │ │
│ │                       10:15 AM │ │
│ └─────────────────────────────────┘ │
│ [2 Replies] [↩️ Reply]             │
│                                     │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ ↩️ Alice                       ❌│ │
│ │ Các bạn có ý kiến gì về des...  │ │
│ └─────────────────────────────────┘ │
│ [📎] [Type a message...      ] [➤] │
└─────────────────────────────────────┘
```

---

## 📱 Bước 3: Bob gõ reply

```
┌─────────────────────────────────────┐
│ Team Project                ❌ Clear│
├─────────────────────────────────────┤
│ 👤 Alice                           │
│ ┌─────────────────────────────────┐ │
│ │ Các bạn có ý kiến gì về design │ │
│ │ mới không?                      │ │
│ │                       10:15 AM │ │
│ └─────────────────────────────────┘ │
│ [2 Replies] [↩️ Reply]             │
│                                     │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ ↩️ Alice                       ❌│ │
│ │ Các bạn có ý kiến gì về des...  │ │
│ └─────────────────────────────────┘ │
│ [📎] [Tôi thích màu xanh hơn  ] [➤] │
└─────────────────────────────────────┘
```

---

## 📱 Bước 4: Sau khi gửi reply

```
┌─────────────────────────────────────┐
│ Team Project                    🔗  │
├─────────────────────────────────────┤
│ 👤 Alice                           │
│ ┌─────────────────────────────────┐ │
│ │ Các bạn có ý kiến gì về design │ │
│ │ mới không?                      │ │
│ │                       10:15 AM │ │
│ └─────────────────────────────────┘ │
│ [3 Replies] [↩️ Reply]             │
│                                     │
│                          👤 Bob    │
│                 ┌─────────────────┐ │
│                 │ ↩️ Alice        │ │
│                 │ Các bạn có ý... │ │
│                 ├─────────────────┤ │
│                 │ Tôi thích màu   │ │
│                 │ xanh hơn        │ │
│                 │      10:16 AM ✓ │ │
│                 └─────────────────┘ │
│                 [1 Reply] [↩️ Reply]│
│                                     │
├─────────────────────────────────────┤
│ [📎] [Type a message...      ] [➤] │
└─────────────────────────────────────┘
```

---

## 📱 Bước 5: Xem tất cả replies

**Alice nhấn "3 Replies" trên tin nhắn gốc:**

```
┌─────────────────────────────────────┐
│           3 Replies                 │
├─────────────────────────────────────┤
│                          👤 Bob    │
│                 ┌─────────────────┐ │
│                 │ ↩️ Alice        │ │
│                 │ Các bạn có ý... │ │
│                 ├─────────────────┤ │
│                 │ Tôi thích màu   │ │
│                 │ xanh hơn        │ │
│                 │      10:16 AM ✓ │ │
│                 └─────────────────┘ │
│                                     │
│ 👤 Charlie                         │
│ ┌─────────────────────────────────┐ │
│ │ ↩️ Alice                       │ │
│ │ Các bạn có ý kiến gì về des... │ │
│ ├─────────────────────────────────┤ │
│ │ Màu cam có vẻ năng động hơn    │ │
│ │                      10:17 AM  │ │
│ └─────────────────────────────────┘ │
│                                     │
│                          👤 David  │
│                 ┌─────────────────┐ │
│                 │ ↩️ Alice        │ │
│                 │ Các bạn có ý... │ │
│                 ├─────────────────┤ │
│                 │ Tôi vote cho    │ │
│                 │ màu xanh 👍     │ │
│                 │      10:18 AM ✓ │ │
│                 └─────────────────┘ │
└─────────────────────────────────────┘
```

---

## 📱 Bước 6: Scroll đến tin nhắn gốc

**Bob nhấn vào reply context trong tin nhắn của mình:**

```
┌─────────────────────────────────────┐
│ Team Project                    🔗  │
├─────────────────────────────────────┤
│ 👤 Alice                    ⬇️ SCROLL│
│ ┌─────────────────────────────────┐ │
│ │ Các bạn có ý kiến gì về design │ │ ← Highlighted
│ │ mới không?                      │ │ ← Auto scrolled here
│ │                       10:15 AM │ │
│ └─────────────────────────────────┘ │
│ [3 Replies] [↩️ Reply]             │
│                                     │
│ ... (other messages) ...           │
└─────────────────────────────────────┘
```

---

## 🎨 Màu sắc & Icon

### **Reply Context:**

- 🎨 **Viền:** Xanh dương (#2196F3)
- 🎨 **Background:** Xám nhạt (#F5F5F5)
- 🎨 **Text:** Xanh đậm (#1976D2)
- ↩️ **Icon:** Reply arrow

### **Reply Preview:**

- 🎨 **Viền:** Xanh dương
- 🎨 **Background:** Trắng
- ❌ **Clear button:** Đỏ (#F44336)

### **Reply Button:**

- ↩️ **Icon:** Xám (#757575)
- 🎨 **Hover:** Xanh dương

---

## 🔄 Animation Effects

1. **Reply Preview:** Slide down from top
2. **Clear Reply:** Fade out animation
3. **Scroll to Message:** Smooth scroll + highlight
4. **Reply Modal:** Slide up from bottom
5. **Context Highlight:** Brief glow effect

---

## 📊 Stats Example

**Trong cuộc trò chuyện:**

- ✅ 15 tin nhắn gốc
- ↩️ 23 replies tổng cộng
- 👥 4 người tham gia
- ⏱️ Thời gian reply trung bình: 2 phút

**Reply breakdown:**

- Alice: 8 replies
- Bob: 7 replies
- Charlie: 5 replies
- David: 3 replies

---

**🎉 Demo hoàn thành! Reply feature hoạt động mượt mà và trực quan.**
