<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# Tenjo - Employee Monitoring Application

## Project Overview
Tenjo is a stealth employee monitoring application with:
- Python client for cross-platform monitoring (Windows/macOS)
- Laravel 12 dashboard for management
- Real-time screen streaming with FFmpeg + WebRTC
- Browser activity tracking and screenshots
- PostgreSQL/SQLite database

## Architecture
- **Client**: Python application (stealth mode)
- **Backend**: Laravel 12 API
- **Database**: PostgreSQL/SQLite
- **Streaming**: FFmpeg + WebRTC
- **Timezone**: Asia/Jakarta

## Key Features
- Live screen streaming
- Automated screenshots every 1 minute
- Browser activity monitoring
- Application usage tracking
- Stealth installation and operation

## Libraries Used
- mss (screenshots)
- psutil (process monitoring)
- pygetwindow/pywin32 (window tracking)
- FFmpeg + WebRTC (streaming)

- [x] Verify that the copilot-instructions.md file in the .github directory is created.

- [x] Clarify Project Requirements
	<!-- Requirements are clear: Python client + Laravel dashboard for employee monitoring -->

- [x] Scaffold the Project
	<!-- Project structure created with client/ and dashboard/ directories -->

- [x] Customize the Project
	<!-- Created Python client with all modules and Laravel dashboard with models/controllers -->

- [x] Install Required Extensions
	<!-- No extensions needed for this project -->

- [x] Compile the Project
	<!-- Laravel dependencies installed and database migrations run -->

- [x] Create and Run Task
	<!-- Laravel server running on port 8000 -->

- [x] Launch the Project
	<!-- Laravel development server launched successfully -->

- [x] Ensure Documentation is Complete
	<!-- README.md created with comprehensive documentation -->
