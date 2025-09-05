@extends('layouts.app')

@section('title', 'Dashboard - Tenjo')

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
                    <div class="card client-card h-100">
                        <div class="card-body">
                            <div class="d-flex justify-content-between align-items-start mb-2">
                                <h6 class="mb-0 text-dark">{{ $client->hostname }}</h6>
                                <span class="badge status-badge {{ $client->isOnline() ? 'bg-success' : 'bg-secondary' }}">
                                    {{ $client->isOnline() ? 'Online' : 'Offline' }}
                                </span>
                            </div>

                            <p class="text-muted small mb-2">
                                <i class="fas fa-user me-1"></i> {{ $client->username }}
                            </p>

                            <p class="text-muted small mb-2">
                                <i class="fas fa-network-wired me-1"></i> {{ $client->ip_address }}
                            </p>

                            <p class="text-muted small mb-2">
                                <i class="fas fa-laptop me-1"></i> {{ $client->getOsDisplayName() }}
                            </p>

                            <p class="text-muted small mb-3">
                                <i class="fas fa-clock me-1"></i>
                                Last seen: {{ $client->last_seen ? $client->last_seen->diffForHumans() : 'Never' }}
                            </p>

                            @if($client->screenshots->count() > 0)
                                <div class="mb-3">
                                    <img src="{{ $client->screenshots->first()->url }}"
                                         alt="Latest screenshot"
                                         class="screenshot-thumbnail">
                                    <small class="text-muted d-block mt-1">
                                        Latest: {{ $client->screenshots->first()->captured_at->format('H:i') }}
                                    </small>
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
@endsection

@section('scripts')
<script>
    // Auto-refresh page every 30 seconds
    setTimeout(function() {
        window.location.reload();
    }, 30000);

    // Update last seen times every 10 seconds
    setInterval(function() {
        // This would typically use AJAX to update timestamps
        console.log('Updating client status...');
    }, 10000);
</script>
@endsection
