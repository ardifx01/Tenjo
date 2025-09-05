# API Documentation

This document provides comprehensive API documentation for the Tenjo Employee Monitoring System.

## Base URL

```
https://your-domain.com/api
```

## Authentication

All API endpoints require authentication using Sanctum tokens.

### Headers Required

```
Authorization: Bearer {your-api-token}
Content-Type: application/json
Accept: application/json
```

## Clients API

### Register Client

Register a new client device.

**Endpoint:** `POST /clients/register`

**Request Body:**
```json
{
    "device_name": "John's Laptop",
    "device_type": "laptop",
    "os_info": "Windows 11 Pro",
    "ip_address": "192.168.1.100",
    "mac_address": "AA:BB:CC:DD:EE:FF",
    "username": "john.doe",
    "hostname": "JOHN-LAPTOP"
}
```

**Response (201 Created):**
```json
{
    "success": true,
    "data": {
        "client": {
            "id": 1,
            "device_name": "John's Laptop",
            "device_type": "laptop",
            "os_info": "Windows 11 Pro",
            "ip_address": "192.168.1.100",
            "mac_address": "AA:BB:CC:DD:EE:FF",
            "username": "john.doe",
            "hostname": "JOHN-LAPTOP",
            "status": "active",
            "last_seen": "2024-01-15T10:30:00.000000Z",
            "created_at": "2024-01-15T10:30:00.000000Z",
            "updated_at": "2024-01-15T10:30:00.000000Z"
        },
        "api_token": "1|abcdef123456789..."
    },
    "message": "Client registered successfully"
}
```

### Update Client Status

Update client heartbeat and status.

**Endpoint:** `POST /clients/{client_id}/heartbeat`

**Request Body:**
```json
{
    "ip_address": "192.168.1.100",
    "system_info": {
        "cpu_usage": 45.2,
        "memory_usage": 62.8,
        "disk_usage": 78.5,
        "active_window": "Google Chrome - Gmail"
    }
}
```

**Response (200 OK):**
```json
{
    "success": true,
    "data": {
        "client": {
            "id": 1,
            "status": "active",
            "last_seen": "2024-01-15T11:30:00.000000Z"
        }
    },
    "message": "Heartbeat received"
}
```

### Get Client Details

Retrieve detailed information about a client.

**Endpoint:** `GET /clients/{client_id}`

**Response (200 OK):**
```json
{
    "success": true,
    "data": {
        "client": {
            "id": 1,
            "device_name": "John's Laptop",
            "device_type": "laptop",
            "os_info": "Windows 11 Pro",
            "ip_address": "192.168.1.100",
            "mac_address": "AA:BB:CC:DD:EE:FF",
            "username": "john.doe",
            "hostname": "JOHN-LAPTOP",
            "status": "active",
            "last_seen": "2024-01-15T11:30:00.000000Z",
            "created_at": "2024-01-15T10:30:00.000000Z",
            "updated_at": "2024-01-15T11:30:00.000000Z",
            "screenshots_count": 145,
            "browser_events_count": 89,
            "process_events_count": 234
        }
    }
}
```

### List Clients

Get paginated list of all clients.

**Endpoint:** `GET /clients`

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `per_page` (optional): Items per page (default: 15, max: 100)
- `status` (optional): Filter by status (active, inactive, offline)
- `search` (optional): Search by device name, username, or hostname

**Response (200 OK):**
```json
{
    "success": true,
    "data": {
        "clients": {
            "data": [
                {
                    "id": 1,
                    "device_name": "John's Laptop",
                    "username": "john.doe",
                    "status": "active",
                    "last_seen": "2024-01-15T11:30:00.000000Z"
                }
            ],
            "current_page": 1,
            "per_page": 15,
            "total": 1,
            "last_page": 1
        }
    }
}
```

## Screenshots API

### Upload Screenshot

Upload a screenshot from the client.

**Endpoint:** `POST /screenshots`

**Content-Type:** `multipart/form-data`

**Request Body:**
```
client_id: 1
screenshot: [binary file data]
timestamp: 2024-01-15 11:30:00
file_size: 2048576
active_window: Google Chrome - Gmail
```

**Response (201 Created):**
```json
{
    "success": true,
    "data": {
        "screenshot": {
            "id": 1,
            "client_id": 1,
            "filename": "screenshot_20240115_113000_abc123.png",
            "file_path": "screenshots/2024/01/15/screenshot_20240115_113000_abc123.png",
            "file_size": 2048576,
            "active_window": "Google Chrome - Gmail",
            "taken_at": "2024-01-15T11:30:00.000000Z",
            "created_at": "2024-01-15T11:30:00.000000Z"
        }
    },
    "message": "Screenshot uploaded successfully"
}
```

### Get Screenshots

Get paginated screenshots for a client.

**Endpoint:** `GET /screenshots`

**Query Parameters:**
- `client_id` (required): Client ID
- `page` (optional): Page number
- `per_page` (optional): Items per page
- `date_from` (optional): Start date (Y-m-d format)
- `date_to` (optional): End date (Y-m-d format)

**Response (200 OK):**
```json
{
    "success": true,
    "data": {
        "screenshots": {
            "data": [
                {
                    "id": 1,
                    "filename": "screenshot_20240115_113000_abc123.png",
                    "file_path": "screenshots/2024/01/15/screenshot_20240115_113000_abc123.png",
                    "file_size": 2048576,
                    "active_window": "Google Chrome - Gmail",
                    "taken_at": "2024-01-15T11:30:00.000000Z",
                    "thumbnail_url": "/api/screenshots/1/thumbnail",
                    "download_url": "/api/screenshots/1/download"
                }
            ],
            "current_page": 1,
            "per_page": 15,
            "total": 145,
            "last_page": 10
        }
    }
}
```

### Download Screenshot

Download original screenshot file.

**Endpoint:** `GET /screenshots/{screenshot_id}/download`

**Response:** Binary file data with appropriate headers

### Get Screenshot Thumbnail

Get thumbnail version of screenshot.

**Endpoint:** `GET /screenshots/{screenshot_id}/thumbnail`

**Response:** Binary image data (JPEG, 300x200px)

## Browser Events API

### Log Browser Event

Log browser activity from the client.

**Endpoint:** `POST /browser-events`

**Request Body:**
```json
{
    "client_id": 1,
    "url": "https://www.google.com/search?q=laravel+tutorial",
    "title": "laravel tutorial - Google Search",
    "browser": "Google Chrome",
    "action": "visit",
    "timestamp": "2024-01-15 11:30:00"
}
```

**Response (201 Created):**
```json
{
    "success": true,
    "data": {
        "browser_event": {
            "id": 1,
            "client_id": 1,
            "url": "https://www.google.com/search?q=laravel+tutorial",
            "title": "laravel tutorial - Google Search",
            "browser": "Google Chrome",
            "action": "visit",
            "timestamp": "2024-01-15T11:30:00.000000Z",
            "created_at": "2024-01-15T11:30:00.000000Z"
        }
    },
    "message": "Browser event logged"
}
```

### Get Browser Events

Get paginated browser events for a client.

**Endpoint:** `GET /browser-events`

**Query Parameters:**
- `client_id` (required): Client ID
- `page` (optional): Page number
- `per_page` (optional): Items per page
- `date_from` (optional): Start date
- `date_to` (optional): End date
- `browser` (optional): Filter by browser
- `search` (optional): Search in URL or title

**Response (200 OK):**
```json
{
    "success": true,
    "data": {
        "browser_events": {
            "data": [
                {
                    "id": 1,
                    "url": "https://www.google.com/search?q=laravel+tutorial",
                    "title": "laravel tutorial - Google Search",
                    "browser": "Google Chrome",
                    "action": "visit",
                    "timestamp": "2024-01-15T11:30:00.000000Z",
                    "domain": "www.google.com"
                }
            ],
            "current_page": 1,
            "per_page": 15,
            "total": 89,
            "last_page": 6
        }
    }
}
```

## Process Events API

### Log Process Event

Log application/process activity from the client.

**Endpoint:** `POST /process-events`

**Request Body:**
```json
{
    "client_id": 1,
    "process_name": "chrome.exe",
    "window_title": "Gmail - Google Chrome",
    "executable_path": "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
    "pid": 1234,
    "action": "start",
    "timestamp": "2024-01-15 11:30:00"
}
```

**Response (201 Created):**
```json
{
    "success": true,
    "data": {
        "process_event": {
            "id": 1,
            "client_id": 1,
            "process_name": "chrome.exe",
            "window_title": "Gmail - Google Chrome",
            "executable_path": "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
            "pid": 1234,
            "action": "start",
            "timestamp": "2024-01-15T11:30:00.000000Z",
            "created_at": "2024-01-15T11:30:00.000000Z"
        }
    },
    "message": "Process event logged"
}
```

### Get Process Events

Get paginated process events for a client.

**Endpoint:** `GET /process-events`

**Query Parameters:**
- `client_id` (required): Client ID
- `page` (optional): Page number
- `per_page` (optional): Items per page
- `date_from` (optional): Start date
- `date_to` (optional): End date
- `process_name` (optional): Filter by process name
- `action` (optional): Filter by action (start, stop, focus)

**Response (200 OK):**
```json
{
    "success": true,
    "data": {
        "process_events": {
            "data": [
                {
                    "id": 1,
                    "process_name": "chrome.exe",
                    "window_title": "Gmail - Google Chrome",
                    "executable_path": "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
                    "pid": 1234,
                    "action": "start",
                    "timestamp": "2024-01-15T11:30:00.000000Z"
                }
            ],
            "current_page": 1,
            "per_page": 15,
            "total": 234,
            "last_page": 16
        }
    }
}
```

## URL Events API

### Log URL Event

Log specific URL access events.

**Endpoint:** `POST /url-events`

**Request Body:**
```json
{
    "client_id": 1,
    "url": "https://github.com/laravel/laravel",
    "title": "GitHub - laravel/laravel: Laravel Framework",
    "method": "GET",
    "response_code": 200,
    "timestamp": "2024-01-15 11:30:00"
}
```

**Response (201 Created):**
```json
{
    "success": true,
    "data": {
        "url_event": {
            "id": 1,
            "client_id": 1,
            "url": "https://github.com/laravel/laravel",
            "title": "GitHub - laravel/laravel: Laravel Framework",
            "method": "GET",
            "response_code": 200,
            "timestamp": "2024-01-15T11:30:00.000000Z",
            "created_at": "2024-01-15T11:30:00.000000Z"
        }
    },
    "message": "URL event logged"
}
```

## Streaming API

### Start Stream

Initialize streaming session for a client.

**Endpoint:** `POST /stream/start`

**Request Body:**
```json
{
    "client_id": 1,
    "quality": "high",
    "framerate": 30
}
```

**Response (200 OK):**
```json
{
    "success": true,
    "data": {
        "session_id": "stream_session_abc123",
        "websocket_url": "wss://your-domain.com:8443/stream/abc123",
        "ice_servers": [
            {
                "urls": "stun:stun.l.google.com:19302"
            },
            {
                "urls": "turn:your-domain.com:3478",
                "username": "turnuser",
                "credential": "turnpass"
            }
        ]
    }
}
```

### Stop Stream

Stop streaming session.

**Endpoint:** `POST /stream/stop`

**Request Body:**
```json
{
    "session_id": "stream_session_abc123"
}
```

**Response (200 OK):**
```json
{
    "success": true,
    "message": "Stream stopped"
}
```

## Analytics API

### Get Client Statistics

Get activity statistics for a client.

**Endpoint:** `GET /analytics/client/{client_id}`

**Query Parameters:**
- `date_from` (optional): Start date
- `date_to` (optional): End date
- `granularity` (optional): hour, day, week, month

**Response (200 OK):**
```json
{
    "success": true,
    "data": {
        "statistics": {
            "screenshots_count": 145,
            "browser_events_count": 89,
            "process_events_count": 234,
            "active_hours": 6.5,
            "top_applications": [
                {"name": "Google Chrome", "usage_time": 3.2},
                {"name": "Visual Studio Code", "usage_time": 2.1}
            ],
            "top_websites": [
                {"domain": "github.com", "visits": 45},
                {"domain": "stackoverflow.com", "visits": 32}
            ],
            "productivity_score": 78
        }
    }
}
```

### Get Dashboard Summary

Get overall system statistics.

**Endpoint:** `GET /analytics/dashboard`

**Response (200 OK):**
```json
{
    "success": true,
    "data": {
        "summary": {
            "total_clients": 15,
            "active_clients": 12,
            "offline_clients": 3,
            "total_screenshots": 2145,
            "total_events": 8934,
            "average_productivity": 75,
            "storage_used": "2.4 GB"
        }
    }
}
```

## Error Responses

All API endpoints return consistent error responses:

### 400 Bad Request
```json
{
    "success": false,
    "error": "Validation failed",
    "details": {
        "client_id": ["The client id field is required."],
        "timestamp": ["The timestamp field must be a valid date."]
    }
}
```

### 401 Unauthorized
```json
{
    "success": false,
    "error": "Unauthorized",
    "message": "Invalid or missing API token"
}
```

### 403 Forbidden
```json
{
    "success": false,
    "error": "Forbidden",
    "message": "You don't have permission to access this resource"
}
```

### 404 Not Found
```json
{
    "success": false,
    "error": "Not Found",
    "message": "The requested resource was not found"
}
```

### 422 Unprocessable Entity
```json
{
    "success": false,
    "error": "Unprocessable Entity",
    "message": "The given data was invalid",
    "details": {
        "file": ["The uploaded file is too large"]
    }
}
```

### 429 Too Many Requests
```json
{
    "success": false,
    "error": "Too Many Requests",
    "message": "Rate limit exceeded. Try again later."
}
```

### 500 Internal Server Error
```json
{
    "success": false,
    "error": "Internal Server Error",
    "message": "An unexpected error occurred"
}
```

## Rate Limits

API endpoints have the following rate limits:

- **General endpoints**: 100 requests per minute per IP
- **Upload endpoints**: 10 requests per minute per client
- **Streaming endpoints**: 5 requests per minute per client
- **Authentication endpoints**: 5 requests per minute per IP

## Pagination

List endpoints use cursor-based pagination:

```json
{
    "data": [...],
    "current_page": 1,
    "per_page": 15,
    "total": 234,
    "last_page": 16,
    "first_page_url": "https://your-domain.com/api/screenshots?page=1",
    "last_page_url": "https://your-domain.com/api/screenshots?page=16",
    "next_page_url": "https://your-domain.com/api/screenshots?page=2",
    "prev_page_url": null
}
```

## Filtering and Searching

Most list endpoints support filtering and searching:

### Date Filtering
```
GET /api/screenshots?date_from=2024-01-01&date_to=2024-01-31
```

### Text Search
```
GET /api/browser-events?search=laravel
```

### Status Filtering
```
GET /api/clients?status=active
```

### Combining Filters
```
GET /api/process-events?client_id=1&date_from=2024-01-01&process_name=chrome.exe&action=start
```

## Webhook Endpoints

### Client Status Change
Webhook called when client status changes.

**Endpoint:** `POST /webhooks/client-status`

**Payload:**
```json
{
    "event": "client.status.changed",
    "client_id": 1,
    "old_status": "active",
    "new_status": "offline",
    "timestamp": "2024-01-15T11:30:00.000000Z"
}
```

### Alert Triggered
Webhook called when monitoring alert is triggered.

**Endpoint:** `POST /webhooks/alert`

**Payload:**
```json
{
    "event": "alert.triggered",
    "client_id": 1,
    "alert_type": "suspicious_activity",
    "details": "Unusual application usage detected",
    "timestamp": "2024-01-15T11:30:00.000000Z"
}
```

## SDK Examples

### Python Client Example
```python
import requests
import json

class TenjoAPI:
    def __init__(self, base_url, token):
        self.base_url = base_url
        self.headers = {
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json',
            'Accept': 'application/json'
        }
    
    def register_client(self, device_info):
        response = requests.post(
            f'{self.base_url}/clients/register',
            headers=self.headers,
            json=device_info
        )
        return response.json()
    
    def upload_screenshot(self, client_id, screenshot_file):
        files = {'screenshot': screenshot_file}
        data = {'client_id': client_id}
        
        response = requests.post(
            f'{self.base_url}/screenshots',
            headers={'Authorization': self.headers['Authorization']},
            files=files,
            data=data
        )
        return response.json()
```

### JavaScript Example
```javascript
class TenjoAPI {
    constructor(baseUrl, token) {
        this.baseUrl = baseUrl;
        this.headers = {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json',
            'Accept': 'application/json'
        };
    }
    
    async getClients() {
        const response = await fetch(`${this.baseUrl}/clients`, {
            headers: this.headers
        });
        return response.json();
    }
    
    async logBrowserEvent(eventData) {
        const response = await fetch(`${this.baseUrl}/browser-events`, {
            method: 'POST',
            headers: this.headers,
            body: JSON.stringify(eventData)
        });
        return response.json();
    }
}
```
