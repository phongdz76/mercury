# ⚡ QUICK GUIDE: REPLY FEATURE

## 🎯 Thao tác cơ bản

| Thao tác               | Cách thực hiện        | Kết quả                  |
| ---------------------- | --------------------- | ------------------------ |
| **Reply tin nhắn**     | Nhấn ↩️ trên tin nhắn | Preview xuất hiện        |
| **Hủy reply**          | Nhấn ❌ trên AppBar   | Clear reply state        |
| **Xem tin nhắn gốc**   | Nhấn reply context    | Auto scroll đến tin nhắn |
| **Xem tất cả replies** | Nhấn "X Replies"      | Modal hiển thị danh sách |
| **Gửi reply**          | Gõ nội dung + Send    | Tin nhắn với context     |

## 🔄 Workflow Reply

```
1. Nhấn Reply (↩️) → 2. Preview hiện → 3. Gõ tin nhắn → 4. Send → 5. Auto clear
```

## 📱 UI Elements

### Reply Preview (Input Area)

```
┌─────────────────────────────┐
│ ↩️ @Username               ❌│
│ Preview message content...  │
└─────────────────────────────┘
```

### Reply Context (Message Bubble)

```
┌─────────────────────────────┐
│ ↩️ @Username               │
│ Original message preview    │
├─────────────────────────────┤
│ Your reply message here     │
│ 10:30 AM ✓                 │
└─────────────────────────────┘
```

### Reply Actions

```
[Message Content]
[3 Replies] [↩️ Reply]
```

## 🚀 Shortcuts & Tips

- **Quick reply:** Nhấn ↩️ → Gõ → Enter
- **Cancel reply:** Nhấn ❌ hoặc gửi tin nhắn
- **Navigate:** Context → Auto scroll to original
- **View all:** Reply count → Modal with all replies

## ⚙️ Technical Notes

- **Auto-detect:** Reply state tự động phát hiện
- **Auto-clear:** Reply state clear sau khi gửi
- **WebSocket:** Field `replyTo` được gửi lên server
- **Performance:** Lazy loading cho reply list
- **Compatibility:** Hỗ trợ cả Direct & Group chat

## 🔧 Troubleshooting

| Vấn đề                | Giải pháp           |
| --------------------- | ------------------- |
| Reply không hoạt động | Restart app         |
| Context không scroll  | Kiểm tra message ID |
| Preview không hiện    | Clear cache         |
| Gửi reply lỗi         | Kiểm tra internet   |

---

**Ready to reply! 🎉**
