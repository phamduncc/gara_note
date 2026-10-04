# 🚗 Gara Note - Ứng dụng Quản lý Gara (Offline 100%)

Ứng dụng quản lý gara ô tô, xe máy hoàn toàn offline, không phụ thuộc internet.

## ✨ Tính năng chính

### 1. 👥 Quản lý Khách hàng & Xe
- Thêm, sửa, xóa thông tin khách hàng
- Quản lý thông tin xe (biển số, hãng, số khung, số máy, km hiện tại)
- Xem lịch sử sửa chữa của từng xe
- Tìm kiếm nhanh theo tên, số điện thoại, biển số

### 2. 🔧 Quản lý Sửa chữa & Phiếu công việc
- Tạo phiếu sửa chữa với mã tự động
- Thêm hạng mục sửa chữa và phụ tùng thay thế
- Tính tiền công, giảm giá, tổng tiền tự động
- Quản lý trạng thái: Chờ sửa → Đang sửa → Hoàn thành → Đã thanh toán
- In hóa đơn (tính năng mở rộng)

### 3. 📦 Quản lý Kho phụ tùng
- Quản lý chi tiết phụ tùng (tên, mã, giá nhập, giá bán, tồn kho)
- Cảnh báo phụ tùng sắp hết hàng
- Trừ kho tự động khi xuất bán
- Tìm kiếm phụ tùng nhanh chóng

### 4. 💰 Quản lý Công nợ
- Theo dõi khách hàng còn nợ
- Lịch sử thanh toán chi tiết
- Tổng hợp công nợ theo từng khách hàng
- Thêm thanh toán cho từng phiếu

### 5. 📊 Báo cáo Thống kê
- Báo cáo theo ngày, tuần, tháng, năm
- Thống kê doanh thu, số phiếu sửa chữa
- Biểu đồ trực quan
- Top phụ tùng bán chạy

### 6. � Dữ liệu Offline
- 100% offline, không cần kết nối internet
- Dữ liệu lưu trữ an toàn trên thiết bị
- Không cần đăng nhập (ứng dụng cá nhân)

## 🛠 Công nghệ sử dụng

- **Framework**: Flutter (hỗ trợ Android, iOS, Windows)
- **Database**: SQLite (lưu trữ offline)
- **Charts**: FL Chart
- **Ngôn ngữ**: Dart
- **Đặc điểm**: 100% offline, không cần đăng nhập

## 📱 Cài đặt và Chạy ứng dụng

### Yêu cầu
- Flutter SDK (≥ 3.10.0)
- Android Studio / VS Code
- Thiết bị Android hoặc Emulator

### Các bước cài đặt

1. **Clone hoặc tải project**
```bash
cd gara_note
```

2. **Cài đặt dependencies**
```bash
flutter pub get
```

3. **Chạy ứng dụng**
```bash
flutter run
```

hoặc chạy trên thiết bị cụ thể:
```bash
flutter run -d windows
flutter run -d android
```

4. **Build APK cho Android**
```bash
flutter build apk --release
```

File APK sẽ được tạo tại: `build/app/outputs/flutter-apk/app-release.apk`

## 📂 Cấu trúc Project

```
lib/
├── models/              # Data models
│   ├── customer.dart
│   ├── vehicle.dart
│   ├── repair_order.dart
│   ├── part.dart
│   ├── payment.dart
│   └── user.dart
├── database/            # SQLite database
│   └── database_helper.dart
├── providers/           # State management
│   └── auth_provider.dart
├── screens/             # UI screens
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── customers/
│   ├── repairs/
│   ├── parts/
│   ├── debts/
│   └── reports/
├── utils/              # Constants & utilities
│   └── constants.dart
└── main.dart           # Entry point
```

## 🎨 Giao diện

- Màu chủ đạo: Xanh dương (Blue) - chuyên nghiệp
- Thiết kế: Material Design 3
- Nút to, dễ bấm - phù hợp cho thợ lớn tuổi
- Giao diện rõ ràng, trực quan

## 💾 Dữ liệu

- Tất cả dữ liệu được lưu trữ local trên thiết bị
- Không cần kết nối internet
- Database: SQLite
- Vị trí database: `[App Data]/databases/gara_note.db`

## 🔄 Tính năng sắp tới

- [ ] Xuất báo cáo Excel/PDF
- [ ] Sao lưu và khôi phục dữ liệu
- [ ] In hóa đơn qua Bluetooth
- [ ] Nhắc lịch bảo dưỡng định kỳ
- [ ] Quét QR code phụ tùng
- [ ] Đồng bộ nhiều thiết bị (online)

## 📞 Hỗ trợ

Phù hợp cho:
- ✅ Tiệm sửa xe máy
- ✅ Gara ô tô nhỏ
- ✅ Đại lý bảo dưỡng độc lập
- ✅ Cửa hàng bán phụ tùng

## 📄 License

MIT License - Tự do sử dụng và chỉnh sửa

---

**Phiên bản**: 1.0.0  
**Tác giả**: Gara Note Team  
**Ngày phát hành**: 2026
