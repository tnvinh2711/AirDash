# 🔐 Android Keystore Setup Guide

Hướng dẫn tạo keystore để upload app lên Google Play Store.

## Bước 1: Tạo Keystore

Chạy script để tạo keystore:

```bash
bash generate_keystore.sh
```

Script sẽ hỏi các thông tin sau:
- **Keystore password**: Mật khẩu cho keystore (nhớ lưu lại!)
- **Key password**: Mật khẩu cho key (có thể giống keystore password)
- **First and last name**: Tên của bạn hoặc tên công ty
- **Organizational unit**: Tên phòng ban (có thể để trống)
- **Organization**: Tên tổ chức/công ty
- **City or Locality**: Thành phố
- **State or Province**: Tỉnh/Bang
- **Country Code**: Mã quốc gia (VD: VN cho Việt Nam)

Keystore sẽ được tạo tại: `~/flux-upload-keystore.jks`

## Bước 2: Tạo File key.properties

Copy file template và điền thông tin:

```bash
cp android/key.properties.template android/key.properties
```

Sau đó mở file `android/key.properties` và điền thông tin:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD_HERE
keyPassword=YOUR_KEY_PASSWORD_HERE
keyAlias=flux-upload-key
storeFile=/Users/vinhtruong/flux-upload-keystore.jks
```

**⚠️ QUAN TRỌNG**: 
- File `key.properties` đã được thêm vào `.gitignore` - KHÔNG BAO GIỜ commit file này!
- Lưu mật khẩu ở nơi an toàn (password manager)
- Backup file keystore `.jks` ở nơi an toàn

## Bước 3: Build Release APK/AAB

Build Android App Bundle (AAB) để upload lên Google Play Store:

```bash
fvm flutter build appbundle --release
```

Hoặc build APK:

```bash
fvm flutter build apk --release
```

File output sẽ ở:
- **AAB**: `build/app/outputs/bundle/release/app-release.aab`
- **APK**: `build/app/outputs/flutter-apk/app-release.apk`

## Bước 4: Upload lên Google Play Console

1. Đăng nhập vào [Google Play Console](https://play.google.com/console)
2. Chọn app của bạn
3. Vào **Production** → **Create new release**
4. Upload file `app-release.aab`
5. Điền thông tin release notes
6. Submit for review

## 🔒 Bảo mật

**TUYỆT ĐỐI KHÔNG:**
- ❌ Commit file `key.properties` vào git
- ❌ Commit file `.jks` hoặc `.keystore` vào git
- ❌ Chia sẻ keystore password công khai
- ❌ Mất file keystore (không thể tạo lại!)

**NÊN:**
- ✅ Backup keystore file ở nhiều nơi an toàn
- ✅ Lưu password trong password manager
- ✅ Giữ keystore riêng tư và bảo mật

## 🤖 Codemagic CI/CD Setup

App đã được cấu hình để build tự động trên Codemagic CI. Cần setup các environment variables sau trong Codemagic:

### Environment Variables cần thiết:

1. **`FCI_KEYSTORE_PATH`** - Đường dẫn đến keystore file (Codemagic sẽ tự động upload)
2. **`FCI_KEYSTORE_PASSWORD`** - Mật khẩu keystore
3. **`FCI_KEY_ALIAS`** - Key alias (mặc định: `flux-upload-key`)
4. **`FCI_KEY_PASSWORD`** - Mật khẩu key

### Cách setup trên Codemagic:

1. Vào **App settings** → **Environment variables**
2. Upload keystore file (`.jks`) → Codemagic sẽ tự động set `FCI_KEYSTORE_PATH`
3. Thêm các biến còn lại với giá trị tương ứng
4. Đánh dấu **Secure** cho tất cả các biến

### Build flow:

- **Trên Codemagic CI**: Sử dụng environment variables `FCI_*`
- **Local development**: Sử dụng file `android/key.properties`
- **Fallback**: Sử dụng debug signing nếu không có keystore

## 📝 Ghi chú

- Keystore này sẽ được dùng cho TẤT CẢ các bản update sau này
- Nếu mất keystore, bạn sẽ KHÔNG THỂ update app trên Google Play Store
- Phải tạo app mới với package name khác nếu mất keystore
- Cấu hình Gradle đã hỗ trợ cả local build và Codemagic CI

