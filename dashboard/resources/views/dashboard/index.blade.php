@extends('layouts.app')

@section('title', 'Dashboard - Tenjo')

@section('styles')
<style>
.stats-card {
    border: none;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    transition: transform 0.2s ease;
    border-radius: 12px;
}

.stats-card:hover {
    transform: translateY(-2px);
}

.client-card {
    border: none;
    box-shadow: 0 2px 12px rgba(0,0,0,0.08);
    transition: all 0.3s ease;
    border-radius: 12px;
}

.client-card:hover {
    transform: translateY(-3px);
    box-shadow: 0 4px 20px rgba(0,0,0,0.15);
}

.screenshot-thumbnail {
    width: 100%;
    max-height: 120px;
    object-fit: cover;
    border-radius: 8px;
    border: 2px solid #e9ecef;
    transition: all 0.3s ease;
    cursor: pointer;
}

.screenshot-thumbnail:hover {
    border-color: #007bff;
    transform: scale(1.02);
}

.status-badge {
    font-size: 0.75rem;
    padding: 4px 8px;
    border-radius: 12px;
}

.screenshot-container {
    position: relative;
    overflow: hidden;
    border-radius: 8px;
}

.screenshot-overlay {
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: linear-gradient(to bottom, transparent 60%, rgba(0,0,0,0.7) 100%);
    opacity: 0;
    transition: opacity 0.3s ease;
    display: flex;
    align-items: flex-end;
    padding: 10px;
}

.screenshot-container:hover .screenshot-overlay {
    opacity: 1;
}

.screenshot-info {
    color: white;
    font-size: 0.75rem;
}

.client-info-item {
    display: flex;
    align-items: center;
    margin-bottom: 0.5rem;
    font-size: 0.875rem;
}

.client-info-item i {
    width: 16px;
    margin-right: 8px;
    color: #6c757d;
}

@media (max-width: 768px) {
    .screenshot-thumbnail {
        max-height: 100px;
    }
}
</style>
@endsection

@section('breadcrumb')
<nav aria-label="breadcrumb">
    <ol class="breadcrumb">
        <li class="breadcrumb-item active">Dashboard</li>
    </ol>
</nav>
@endsection

@section('content')
<div class="d-flex justify-content-between align-items-center mb-4">
    <h1 class="h3 mb-0 text-dark">Employee Monitoring Dashboard</h1>
    <div class="text-muted">
        <i class="fas fa-clock"></i> {{ now()->format('M d, Y H:i') }}
    </div>
</div>

<!-- Statistics Cards -->
<div class="row mb-4">
    <div class="col-md-3">
        <div class="card stats-card">
            <div class="card-body text-center">
                <i class="fas fa-desktop fa-2x mb-2"></i>
                <h3 class="mb-0">{{ $stats['total_clients'] }}</h3>
                <small>Total Clients</small>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card stats-card">
            <div class="card-body text-center">
                <i class="fas fa-circle text-success fa-2x mb-2"></i>
                <h3 class="mb-0">{{ $stats['online_clients'] }}</h3>
                <small>Online Now</small>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card stats-card">
            <div class="card-body text-center">
                <i class="fas fa-calendar-check fa-2x mb-2"></i>
                <h3 class="mb-0">{{ $stats['active_clients'] }}</h3>
                <small>Active Today</small>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card stats-card">
            <div class="card-body text-center">
                <i class="fas fa-camera fa-2x mb-2"></i>
                <h3 class="mb-0">{{ $stats['total_screenshots'] }}</h3>
                <small>Screenshots Today</small>
            </div>
        </div>
    </div>
</div>

<!-- Clients Grid -->
<div class="card">
    <div class="card-header">
        <h5 class="mb-0">
            <i class="fas fa-desktop me-2"></i>
            Connected Clients
        </h5>
    </div>
    <div class="card-body">
        @if($clients->count() > 0)
            <div class="row">
                @foreach($clients as $client)
                <div class="col-md-6 col-lg-4 mb-3">
                    <div class="card client-card h-100" data-client-id="{{ $client->client_id }}">
                        <div class="card-body">
                            <div class="d-flex justify-content-between align-items-start mb-3">
                                <h6 class="mb-0 text-dark">{{ $client->hostname }}</h6>
                                <span class="badge status-badge {{ $client->isOnline() ? 'bg-success' : 'bg-secondary' }}">
                                    {{ $client->isOnline() ? 'Online' : 'Offline' }}
                                </span>
                            </div>

                            <div class="client-info-item">
                                <i class="fas fa-user"></i> {{ $client->username }}
                            </div>

                            <div class="client-info-item">
                                <i class="fas fa-network-wired"></i> {{ $client->ip_address }}
                            </div>

                            <div class="client-info-item">
                                <i class="fas fa-laptop"></i> {{ $client->getOsDisplayName() }}
                            </div>

                            <div class="client-info-item last-seen-time">
                                <i class="fas fa-clock"></i>
                                Last seen: {{ $client->last_seen ? $client->last_seen->diffForHumans() : 'Never' }}
                            </div>

                            @if($client->screenshots->count() > 0)
                                @php
                                    $latestScreenshot = $client->screenshots->first();
                                @endphp
                                <div class="mb-3">
                                    <div class="screenshot-container">
                                        <img src="{{ $latestScreenshot->url }}"
                                             alt="Latest screenshot from {{ $client->hostname }}"
                                             class="screenshot-thumbnail"
                                             onclick="showScreenshotModal('{{ $latestScreenshot->url }}', '{{ $client->hostname }}', '{{ $latestScreenshot->captured_at->format('M d, Y H:i:s') }}')"
                                             onerror="this.style.display='none'; this.nextElementSibling.style.display='block';">
                                        <div class="screenshot-overlay">
                                            <div class="screenshot-info">
                                                <i class="fas fa-search-plus me-1"></i>Click to enlarge
                                            </div>
                                        </div>
                                    </div>
                                    <div style="display: none; padding: 20px; text-align: center; background: #f8f9fa; border-radius: 8px; border: 2px dashed #dee2e6;">
                                        <i class="fas fa-image text-muted mb-2" style="font-size: 2rem;"></i>
                                        <p class="text-muted mb-0">Screenshot not available</p>
                                    </div>
                                    <small class="text-muted d-block mt-2">
                                        <i class="fas fa-camera me-1"></i>
                                        Latest: {{ $latestScreenshot->captured_at->format('M d, H:i') }}
                                        @if($latestScreenshot->file_size)
                                            • {{ $latestScreenshot->file_size_human }}
                                        @endif
                                    </small>
                                </div>
                            @else
                                <div class="mb-3 text-center py-3" style="background: #f8f9fa; border-radius: 8px; border: 2px dashed #dee2e6;">
                                    <i class="fas fa-camera-retro text-muted mb-2" style="font-size: 2rem;"></i>
                                    <p class="text-muted mb-0 small">No screenshots available</p>
                                </div>
                            @endif

                            <div class="d-grid gap-2">
                                <div class="btn-group" role="group">
                                    <a href="{{ route('client.live', $client->client_id) }}"
                                       class="btn btn-primary btn-sm">
                                        <i class="fas fa-video"></i> Live
                                    </a>
                                    <a href="{{ route('client.details', $client->client_id) }}"
                                       class="btn btn-outline-primary btn-sm">
                                        <i class="fas fa-info-circle"></i> Details
                                    </a>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                @endforeach
            </div>
        @else
            <div class="text-center py-5">
                <i class="fas fa-desktop fa-3x text-muted mb-3"></i>
                <h5 class="text-muted">No clients connected</h5>
                <p class="text-muted">Install the Tenjo client on employee computers to start monitoring.</p>
            </div>
        @endif
    </div>
</div>

<!-- Screenshot Modal -->
<div class="modal fade" id="screenshotModal" tabindex="-1" aria-labelledby="screenshotModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="screenshotModalLabel">
                    <i class="fas fa-camera me-2"></i>Screenshot Preview
                </h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body text-center">
                <img id="modalScreenshot" src="" alt="Screenshot" class="img-fluid rounded" style="max-height: 500px;">
                <div class="mt-3">
                    <p id="modalScreenshotInfo" class="text-muted mb-0"></p>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-outline-primary" onclick="downloadScreenshot()">
                    <i class="fas fa-download me-1"></i>Download
                </button>
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
            </div>
        </div>
    </div>
</div>
@endsection

@section('scripts')
<script>
    let currentScreenshotUrl = '';

    // Show screenshot in modal
    function showScreenshotModal(url, hostname, timestamp) {
        currentScreenshotUrl = url;
        document.getElementById('modalScreenshot').src = url;
        document.getElementById('modalScreenshotInfo').innerHTML = `
            <strong>${hostname}</strong><br>
            <small>Captured: ${timestamp}</small>
        `;

        const modal = new bootstrap.Modal(document.getElementById('screenshotModal'));
        modal.show();
    }

    // Download screenshot
    function downloadScreenshot() {
        if (currentScreenshotUrl) {
            const link = document.createElement('a');
            link.href = currentScreenshotUrl;
            link.download = 'screenshot_' + new Date().toISOString().replace(/[:.]/g, '-') + '.jpg';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        }
    }

    // Auto-refresh page every 30 seconds
    setTimeout(function() {
        window.location.reload();
    }, 30000);

    // Update last seen times every 10 seconds with AJAX
    setInterval(function() {
        fetch('/api/clients/status', {
            method: 'GET',
            headers: {
                'Accept': 'application/json',
                'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
            }
        })
        .then(response => response.json())
        .then(data => {
            // Update client status indicators
            data.forEach(client => {
                const statusBadge = document.querySelector(`[data-client-id="${client.client_id}"] .status-badge`);
                if (statusBadge) {
                    statusBadge.className = `badge status-badge ${client.is_online ? 'bg-success' : 'bg-secondary'}`;
                    statusBadge.textContent = client.is_online ? 'Online' : 'Offline';
                }

                const lastSeenElement = document.querySelector(`[data-client-id="${client.client_id}"] .last-seen-time`);
                if (lastSeenElement) {
                    lastSeenElement.textContent = client.last_seen_human;
                }
            });
        })
        .catch(error => console.log('Status update error:', error));
    }, 10000);

    // Handle image loading errors
    document.addEventListener('DOMContentLoaded', function() {
        const screenshots = document.querySelectorAll('.screenshot-thumbnail');
        screenshots.forEach(img => {
            img.addEventListener('error', function() {
                console.log('Failed to load screenshot:', this.src);
                this.style.display = 'none';
                const fallback = this.parentElement.nextElementSibling;
                if (fallback) {
                    fallback.style.display = 'block';
                }
            });

            img.addEventListener('load', function() {
                console.log('Successfully loaded screenshot:', this.src);
            });
        });
    });
</script>
@endsection
