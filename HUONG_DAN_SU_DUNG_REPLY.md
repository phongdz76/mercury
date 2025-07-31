# 📱 HƯỚNG DẪN SỬ DỤNG TÍNH NĂNG REPLY

## 🎯 Tổng quan

Tính năng Reply cho phép bạn trả lời trực tiếp một tin nhắn cụ thể trong cuộc trò chuyện, giúp theo dõi ngữ cảnh và tổ chức cuộc hội thoại tốt hơn.

---

## 🚀 Cách sử dụng Reply

### 1. **Trả lời một tin nhắn**

**Bước 1:** Tìm tin nhắn bạn muốn trả lời

- Cuộn lên/xuống để tìm tin nhắn cần reply

**Bước 2:** Nhấn nút Reply

- Bên dưới mỗi tin nhắn có biểu tượng ↩️ (Reply)
- Nhấn vào biểu tượng này

**Bước 3:** Xem preview tin nhắn được reply

- Phần preview sẽ xuất hiện phía trên ô nhập tin nhắn
- Preview hiển thị tên người gửi và nội dung tin nhắn gốc

**Bước 4:** Nhập tin nhắn trả lời

- Gõ nội dung trả lời vào ô tin nhắn
- Có thể đính kèm file/hình ảnh như bình thường

**Bước 5:** Gửi tin nhắn

- Nhấn nút Send (➤)
- Tin nhắn reply sẽ được gửi và hiển thị với ngữ cảnh

---

## 📋 Các tính năng Reply chi tiết

### ✅ **Reply Preview**

- **Vị trí:** Xuất hiện phía trên ô nhập tin nhắn
- **Nội dung:** Hiển thị tên người gửi và preview nội dung
- **Màu sắc:** Viền xanh để dễ nhận biết

### ✅ **Reply Context trong tin nhắn**

- **Hiển thị:** Mỗi tin nhắn reply sẽ có phần context phía trên
- **Tương tác:** Nhấn vào context để scroll đến tin nhắn gốc
- **Format:** Hiển thị tên người gửi và nội dung bị cắt ngắn

### ✅ **Reply Count**

- **Vị trí:** Bên dưới mỗi tin nhắn có replies
- **Hiển thị:** Số lượng replies (ví dụ: "3 Replies")
- **Tương tác:** Nhấn để xem tất cả replies trong modal

---

## 🛠️ Các thao tác quản lý Reply

### **1. Hủy Reply (Clear Reply)**

- **Cách 1:** Nhấn nút ❌ trên thanh AppBar (chỉ hiện khi đang reply)
- **Cách 2:** Reply sẽ tự động clear sau khi gửi tin nhắn thành công

### **2. Xem tin nhắn gốc**

- Nhấn vào phần Reply Context trong tin nhắn
- App sẽ tự động scroll đến tin nhắn gốc được reply

### **3. Xem tất cả Replies**

- Nhấn vào "X Replies" bên dưới tin nhắn
- Modal sẽ hiển thị tất cả tin nhắn reply
- Có thể scroll để xem đầy đủ

---

## 💡 Mẹo sử dụng hiệu quả

### **📝 Khi nào nên dùng Reply:**

- ✅ Trả lời câu hỏi cụ thể
- ✅ Phản hồi về một chủ đề riêng
- ✅ Làm rõ ngữ cảnh trong group chat
- ✅ Tham khảo tin nhắn cũ

### **🎨 Nhận biết Reply:**

- **Viền xanh:** Reply context có viền màu xanh
- **Icon ↩️:** Biểu tượng reply rõ ràng
- **Preview text:** Nội dung được cắt ngắn (2 dòng)
- **Tên người gửi:** Hiển thị bold màu xanh

### **⚡ Thao tác nhanh:**

- **Double tap:** Context để scroll nhanh đến tin nhắn gốc
- **Long press:** Reply button để xem options (nếu có)
- **Swipe:** Có thể swipe tin nhắn để reply nhanh (tùy implementation)

---

## 🔧 Tính năng bổ sung

### **📎 Reply với đính kèm**

- Có thể reply kèm hình ảnh, file, video
- Preview sẽ hiển thị cả nội dung reply và attachment
- Hỗ trợ caption cho file đính kèm

### **👥 Reply trong Group Chat**

- Hiển thị avatar và tên người gửi rõ ràng
- Reply context giúp theo dõi cuộc hội thoại phức tạp
- Tất cả thành viên đều thấy reply context

### **📱 Reply trong Direct Chat**

- Interface gọn gàng hơn
- Focus vào nội dung tin nhắn
- Context vẫn được hiển thị đầy đủ

---

## 🚨 Lưu ý quan trọng

### **⚠️ Giới hạn:**

- Chỉ reply được tin nhắn còn tồn tại
- Không thể reply tin nhắn đã bị xóa
- Reply context sẽ hiển thị "Message not found" nếu tin nhắn gốc bị xóa

### **🔒 Bảo mật:**

- Chỉ reply được tin nhắn trong cuộc trò chuyện bạn có quyền truy cập
- Reply context tuân theo quyền riêng tư của cuộc trò chuyện

### **📊 Hiệu suất:**

- Reply không ảnh hưởng đến tốc độ gửi tin nhắn
- Auto-scroll mượt mà khi xem tin nhắn gốc
- Lazy loading cho danh sách replies

---

## 🎯 Tóm tắt các bước cơ bản

1. **Nhấn ↩️** trên tin nhắn muốn reply
2. **Xem preview** phía trên ô nhập tin nhắn
3. **Gõ nội dung** reply
4. **Nhấn Send** để gửi
5. **Nhấn context** để xem tin nhắn gốc
6. **Nhấn reply count** để xem tất cả replies

---

## 📞 Hỗ trợ

Nếu gặp vấn đề với tính năng Reply:

- Kiểm tra kết nối internet
- Restart ứng dụng nếu reply không hoạt động
- Đảm bảo app đã được cập nhật phiên bản mới nhất

**Chúc bạn có trải nghiệm chat tuyệt vời! 🎉**
