# WinUtil Tiếng Việt - Launcher

Launcher tải WinUtil từ GitHub, dịch sang tiếng Việt, build và chạy.

## Tính năng mới: Chọn ngôn ngữ trong WinUtil

Sau khi build, WinUtil sẽ có **ComboBox chọn ngôn ngữ** ở góc trên bên phải (cạnh nút Theme):
- **Tiếng Việt** (mặc định)
- **English**

Khi đổi ngôn ngữ:
1. WinUtil đóng
2. Dùng `en_translations.json` hoặc `vi_translations.json` để dịch
3. Compile lại
4. WinUtil mở lại với ngôn ngữ mới

**Lưu ý:** Cần có cả 2 file từ điển (`vi_translations.json` và `en_translations.json`) để chuyển đổi qua lại.

## Cách dùng (chạy trực tiếp)

```powershell
# Chạy với quyền Admin (PowerShell phải Run as Administrator)
powershell -ExecutionPolicy Bypass -File .\WinUtil-Vi-Launcher.ps1
```

File đã lưu UTF-8 BOM. Nếu tiếng Việt hiển thị sai, dùng PowerShell 7:
```powershell
pwsh -ExecutionPolicy Bypass -File .\WinUtil-Vi-Launcher.ps1
```

## Cấu trúc thư mục (cần có)

```
WinUtil-Vi/
├── WinUtil-Vi-Launcher.ps1       # Script chính (GUI)
├── Translate-Vi.ps1              # Script dịch (hỗ trợ -Language vi/en)
├── Compile-Vi.ps1                # Script build (đã sửa encoding)
├── Invoke-WPFLanguageChange.ps1  # Function đổi ngôn ngữ (copy vào WinUtil)
└── config/
    ├── vi_translations.json      # Từ điển EN → VI
    └── en_translations.json      # Từ điển VI → EN (để đổi lại tiếng Anh)
```

## Menu (GUI)

1. **Tải bản mới từ GitHub, dịch, build và chạy** – Có checkbox: tải bản mới hay dùng file hiện có
2. **Chạy bản hiện tại (offline)** – Chạy winutil.ps1 đã build
3. **Chỉnh sửa bản dịch** – Mở vi_translations.json để chỉnh trực tiếp
4. **Thêm bản dịch mới** – Form nhập chuỗi EN → VI. Nếu chuỗi đã tồn tại thì **ghi đè** bản cũ

## Dữ liệu lưu ở đâu

- Clone/build: `%LOCALAPPDATA%\WinUtil-Vi\winutil\`
- winutil.ps1: `%LOCALAPPDATA%\WinUtil-Vi\winutil\winutil.ps1`

## Build thành EXE

### Bước 1: Cài ps2exe (chỉ làm một lần)

Mở **PowerShell** (không cần Admin) và chạy:

```powershell
Install-Module ps2exe -Scope CurrentUser
```

Nếu báo lỗi NuGet, chạy lần lượt:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module ps2exe -Scope CurrentUser
```

### Bước 2: Build EXE

Trong thư mục winutil:

```powershell
powershell -ExecutionPolicy Bypass -File .\Build-Exe.ps1
```

Hoặc build tay:

```powershell
Invoke-ps2exe .\WinUtil-Vi-Launcher.ps1 .\WinUtil-Vi.exe -requireAdmin -noConsole
```

### Sau khi build

Đặt **cùng thư mục** với `WinUtil-Vi.exe` khi đem đi máy khác:
- `Translate-Vi.ps1`
- `Compile-Vi.ps1`
- `Invoke-WPFLanguageChange.ps1`
- `config\vi_translations.json`
- `config\en_translations.json`
- `meo.ico` (icon)
