@extends('layouts.app')

@section('title', 'History Activity - Tenjo Dashboard')

@section('content')
<div class="fade-in">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <div>
            <h2 class="page-title">History Activity</h2>
            <p class="text-muted">Monitor user activities and system events across all clients</p>
        </div>
        <div class="d-flex gap-2">
            <button class="btn btn-outline-success btn-sm" onclick="exportActivityData()">
                <i class="fas fa-download me-1"></i>Export Data
            </button>
            <button class="btn btn-outline-info btn-sm" onclick="refreshData()">
                <i class="fas fa-sync-alt me-1"></i>Refresh
            </button>
        </div>
    </div>

    <!-- Filter Form -->
    <div class="card mb-4">
        <div class="card-header">
            <i class="fas fa-filter me-2"></i>Filter Activities
        </div>
        <div class="card-body">
            <form method="GET" action="{{ route('history.activity') }}">
                <div class="row g-3">
                    <div class="col-md-3">
                        <label class="form-label">From Date</label>
                        <input type="date" name="from" class="form-control" value="{{ $from }}">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label">To Date</label>
                        <input type="date" name="to" class="form-control" value="{{ $to }}">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label">Client</label>
                        <select name="client_id" class="form-select">
                            <option value="">All Clients</option>
                            @foreach($clients as $client)
                                <option value="{{ $client->client_id }}" {{ request('client_id') == $client->client_id ? 'selected' : '' }}>
                                    {{ $client->hostname }} ({{ $client->username }})
                                </option>
                            @endforeach
                        </select>
                    </div>
                    <div class="col-md-2 d-flex align-items-end">
                        <button type="submit" class="btn btn-primary w-100">
                            <i class="fas fa-search me-1"></i>Filter
                        </button>
                    </div>
                </div>
            </form>
        </div>
    </div>

    <!-- Activity Summary -->
    <div class="row mb-4">
        <div class="col-md-3 mb-3">
            <div class="card stats-card">
                <div class="card-body text-center">
                    <div class="stats-number">{{ number_format($activitySummary['browser_events']) }}</div>
                    <p class="mb-0">Browser Events</p>
                </div>
            </div>
        </div>
        <div class="col-md-3 mb-3">
            <div class="card stats-card">
                <div class="card-body text-center">
                    <div class="stats-number">{{ number_format($activitySummary['process_events']) }}</div>
                    <p class="mb-0">Process Events</p>
                </div>
            </div>
        </div>
        <div class="col-md-3 mb-3">
            <div class="card stats-card">
                <div class="card-body text-center">
                    <div class="stats-number">{{ number_format($activitySummary['url_events']) }}</div>
                    <p class="mb-0">URL Events</p>
                </div>
            </div>
        </div>
        <div class="col-md-3 mb-3">
            <div class="card stats-card">
                <div class="card-body text-center">
                    <div class="stats-number">{{ number_format($activitySummary['screenshots']) }}</div>
                    <p class="mb-0">Screenshots</p>
                </div>
            </div>
        </div>
    </div>

    <!-- Client Activities -->
    <div class="row">
        @forelse($clients as $client)
            <div class="col-md-6 mb-4">
                <div class="card client-card h-100">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h5 class="mb-0">
                            <i class="fas fa-desktop me-2"></i>{{ $client->hostname }}
                        </h5>
                        <span class="status-badge status-{{ $client->isOnline() ? 'online' : 'offline' }}">
                            {{ $client->isOnline() ? 'Online' : 'Offline' }}
                        </span>
                    </div>
                    <div class="card-body">
                        <div class="row text-center">
                            <div class="col-6">
                                <h4 class="text-primary mb-1">{{ $client->browserEvents->count() }}</h4>
                                <small class="text-muted">Browser Events</small>
                            </div>
                            <div class="col-6">
                                <h4 class="text-success mb-1">{{ $client->processEvents->count() }}</h4>
                                <small class="text-muted">Process Events</small>
                            </div>
                        </div>

                        <hr>

                        <div class="recent-activity">
                            <h6 class="mb-3">Recent Activities</h6>

                            <!-- Browser Events -->
                            @if($client->browserEvents->count() > 0)
                                <div class="mb-3">
                                    <small class="text-muted fw-bold">🌐 Browser Activities</small>
                                </div>
                                @foreach($client->browserEvents->take(3) as $event)
                                    <div class="d-flex align-items-start mb-3">
                                        <div class="flex-shrink-0">
                                            <i class="fas fa-globe text-info"></i>
                                        </div>
                                        <div class="flex-grow-1 ms-3">
                                            <div class="fw-medium">{{ $event->title ?? 'Page Visit' }}</div>
                                            <small class="text-muted d-block">{{ $event->url }}</small>
                                            <small class="text-success">{{ $event->browser_name }} • {{ $event->created_at->diffForHumans() }}</small>
                                        </div>
                                    </div>
                                @endforeach
                            @endif

                            <!-- Process Events -->
                            @if($client->processEvents->count() > 0)
                                <div class="mb-3 mt-3">
                                    <small class="text-muted fw-bold">⚙️ Process Activities</small>
                                </div>
                                @foreach($client->processEvents->take(3) as $event)
                                    <div class="d-flex align-items-center mb-2">
                                        <div class="flex-shrink-0">
                                            <i class="fas fa-cogs text-warning"></i>
                                        </div>
                                        <div class="flex-grow-1 ms-3">
                                            <div class="fw-medium">{{ $event->process_name }}</div>
                                            <small class="text-muted">{{ $event->event_type }} • PID: {{ $event->process_pid }} • {{ $event->created_at->diffForHumans() }}</small>
                                        </div>
                                    </div>
                                @endforeach
                            @endif

                            @if($client->browserEvents->count() == 0 && $client->processEvents->count() == 0)
                                <p class="text-muted mb-0">No recent activities</p>
                            @endif
                        </div>

                        <div class="mt-3">
                            <a href="{{ route('client.details', $client->client_id) }}" class="btn btn-outline-primary btn-sm">
                                <i class="fas fa-eye me-1"></i>View Details
                            </a>
                            <a href="{{ route('client.live', $client->client_id) }}" class="btn btn-primary btn-sm">
                                <i class="fas fa-video me-1"></i>Live View
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        @empty
            <div class="col-12">
                <div class="card">
                    <div class="card-body text-center py-5">
                        <i class="fas fa-database text-muted mb-3" style="font-size: 3rem;"></i>
                        <h4 class="text-muted">No Activities Found</h4>
                        <p class="text-muted">No client activities found for the selected date range.</p>
                    </div>
                </div>
            </div>
        @endforelse
    </div>
</div>
@endsection
