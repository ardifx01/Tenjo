# Platform-Specific Import Handling

## Overview

The Tenjo client uses platform-specific libraries to access system APIs for monitoring browser activity and window information. These imports are handled conditionally to ensure the application works across different operating systems.

## Import Strategy

### Windows-specific modules:
- `win32gui` - Windows API for window management
- `win32process` - Windows process management
- `pygetwindow` - Cross-platform window management (fallback)

### macOS-specific modules:
- `AppKit.NSWorkspace` - macOS application workspace
- `Quartz` - macOS graphics and window system

### Linux-specific:
- Uses standard `psutil` and basic process monitoring

## Handling Import Errors

The code uses conditional imports with availability flags:

```python
if platform.system() == 'Windows':
    try:
        import win32gui
        import win32process
        WINDOWS_AVAILABLE = True
    except ImportError:
        WINDOWS_AVAILABLE = False
        win32gui = None
```

## IDE/Linter Warnings

### Expected Warnings

When developing on macOS or Linux, you may see warnings like:
- `Import "win32gui" could not be resolved from source`
- `Import "win32process" could not be resolved from source`

These warnings are **expected and normal** because:
1. These modules only exist on Windows
2. The imports are conditional and properly handled
3. The code includes fallbacks for when modules aren't available

### How to Handle

1. **Ignore the warnings** - They don't affect functionality
2. **Use platform-specific linting** - Configure your IDE to lint only for the current platform
3. **Use type stubs** - Install type stubs for cross-platform development

## Testing Imports

Use the provided test script to verify imports work correctly:

```bash
cd client/
python test_imports.py
```

This will test all imports and show which ones are available on your current platform.

## Installation

The installer (`install.py`) automatically handles platform-specific dependencies:

- **Windows**: Installs `pywin32` and `pygetwindow`
- **macOS**: Installs `pyobjc-framework-*` packages
- **Linux**: Uses standard libraries only

## Troubleshooting

### Windows Issues

If you encounter Windows-specific import errors:

1. Install pywin32 manually:
   ```bash
   pip install pywin32
   ```

2. Run post-install script:
   ```bash
   python Scripts/pywin32_postinstall.py -install
   ```

### macOS Issues

If you encounter macOS-specific import errors:

1. Install Xcode command line tools:
   ```bash
   xcode-select --install
   ```

2. Install pyobjc frameworks:
   ```bash
   pip install pyobjc-framework-Quartz pyobjc-framework-AppKit
   ```

### General Issues

If imports still fail:

1. **Check Python version**: Ensure Python 3.7+ is installed
2. **Virtual environment**: Create a clean virtual environment
3. **Permissions**: Ensure proper permissions for system API access
4. **Dependencies**: Run the installer script to handle all dependencies

## Development Notes

When developing cross-platform features:

1. Always use conditional imports
2. Provide fallback mechanisms
3. Test on target platforms
4. Handle ImportError gracefully
5. Document platform-specific behavior

The current implementation prioritizes reliability over eliminating IDE warnings, ensuring the application works correctly regardless of development environment.
