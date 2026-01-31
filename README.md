# WinUtil Tiếng Việt

[![Version](https://img.shields.io/github/v/release/nqtam6666/Winutil-Vietnamese?color=%230567ff&label=Release&style=for-the-badge)](https://github.com/nqtam6666/Winutil-Vietnamese/releases/latest)

Bản dịch tiếng Việt của **Chris Titus Tech's Windows Utility** – công cụ cài đặt ứng dụng, tối ưu Windows, sửa lỗi cập nhật và quản lý cấu hình hệ thống.

> Dựa trên [winutil](https://github.com/ChrisTitusTech/winutil) của Chris Titus Tech. Cảm ơn dự án gốc!

## Cách sử dụng

**Cần chạy với quyền Administrator** (PowerShell hoặc Terminal: chuột phải → Run as administrator).

### Cài đặt một dòng (như christitus.com/win)

```powershell
irm "https://raw.githubusercontent.com/nqtam6666/Winutil-Vietnamese/main/install.ps1" | iex
```

Hoặc tải trực tiếp `winutil.ps1` từ Releases:

```powershell
irm "https://github.com/nqtam6666/Winutil-Vietnamese/releases/latest/download/winutil.ps1" | iex
```

> **Lưu ý:** Cần có Release trên GitHub với file `winutil.ps1` đính kèm. Xem [Releases](https://github.com/nqtam6666/Winutil-Vietnamese/releases).

### Chạy file EXE (khuyến nghị)

1. Tải [WinUtil-Vi.exe](https://github.com/nqtam6666/Winutil-Vietnamese/releases) từ mục Releases
2. Chuột phải → **Run as administrator**

### Chạy file PS1 (clone repo)

```powershell
powershell -ExecutionPolicy Bypass -File .\WinUtil-Vi-Launcher.ps1
```

Nếu tiếng Việt hiển thị sai, dùng PowerShell 7:

```powershell
pwsh -ExecutionPolicy Bypass -File .\WinUtil-Vi-Launcher.ps1
```

## Tính năng

- **Đa ngôn ngữ:** Chuyển đổi Tiếng Việt / English ngay trong giao diện (ComboBox góc trên bên phải)
- **Cài đặt ứng dụng** – winget, chocolatey
- **Tweaks** – tối ưu, debloat Windows
- **Sửa lỗi Update** – xử lý các vấn đề Windows Update
- **Cấu hình mạng** – DNS, thay đổi cài đặt mạng

## Tải về

- **Releases:** [nqtam6666/Winutil-Vietnamese/releases](https://github.com/nqtam6666/Winutil-Vietnamese/releases)
- **Mã nguồn:** Clone hoặc Download ZIP từ repo này

## Cấu trúc dự án

```
├── WinUtil-Vi-Launcher.ps1    # Launcher chính (GUI)
├── WinUtil-Vi.exe             # Bản build EXE (trong Releases)
├── config/
│   ├── vi_translations.json   # Bản dịch tiếng Việt
│   └── en_translations.json   # Bản dịch tiếng Anh (để chuyển đổi)
├── functions/                 # Logic ứng dụng
├── scripts/                   # Điểm vào
└── ...
```

## Tài liệu gốc

- [WinUtil Documentation](https://winutil.christitus.com/)
- [Dự án gốc - Chris Titus Tech](https://github.com/ChrisTitusTech/winutil)

## Để `irm | iex` hoạt động

Lệnh một dòng cần file `winutil.ps1` trong Releases:

1. Build: Chạy `WinUtil-Vi-Launcher.ps1` → chọn build → file tạo ra tại `%LOCALAPPDATA%\WinUtil-Vi\winutil\winutil.ps1`
2. Tạo Release trên GitHub (Releases → Create new release)
3. Đính kèm file `winutil.ps1` (tên phải đúng)
4. Publish release

## Báo lỗi / Đóng góp

- [Tạo Issue](https://github.com/nqtam6666/Winutil-Vietnamese/issues)
- Pull request đóng góp bản dịch hoặc sửa lỗi đều được chào đón

## Giấy phép

Theo giấy phép của dự án gốc [winutil](https://github.com/ChrisTitusTech/winutil).
