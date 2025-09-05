@extends('layouts.app')

@section('title', 'URL Activity - Tenjo Dashboard')

@section('styles')
<style>
.stats-card {
    border: none;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    transition: transform 0.2s;
}

.stats-card:hover {
    transform: translateY(-2px);
}

.stats-icon {
    width: 50px;
    height: 50px;
    border-radius: 10px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 1.2rem;
    color: white;
}

.url-item {
    border-left: 3px solid #007bff;
    background: #f8f9fa;
    transition: all 0.2s;
}

.url-item:hover {
    background: #e9ecef;
    border-left-color: #0056b3;
}

.domain-card {
    border: 1px solid #e9ecef;
    border-radius: 8px;
    transition: all 0.2s;
}

.domain-card:hover {
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.event-badge {
    font-size: 0.75rem;
}

.url-link {
    color: #007bff;
    text-decoration: none;
    transition: color 0.2s;
}

.url-link:hover {
    color: #0056b3;
    text-decoration: underline;
}

.pagination .page-link {
    color: #007bff;
    border: 1px solid #dee2e6;
    padding: 0.375rem 0.75rem;
}

.pagination .page-link:hover {
    color: #0056b3;
    background-color: #e9ecef;
    border-color: #dee2e6;
}

.pagination .page-item.active .page-link {
    background-color: #007bff;
    border-color: #007bff;
    color: #fff;
}

.pagination .page-item.disabled .page-link {
    color: #6c757d;
    background-color: #fff;
    border-color: #dee2e6;
}

.pagination-info {
    font-size: 0.875rem;
    color: #6c757d;
}
</style>
@endsection

@section('content')
<div class="fade-in">
    <!-- Header -->
    <div class="d-flex justify-content-between align-items-center mb-4">
        <div>
            <h2 class="page-title">URL Activity</h2>
            <p class="text-muted">Track website visits and URL access patterns across all clients</p>
        </div>
        <div>
            <a href="{{ route('export.report') }}" class="btn btn-outline-primary">
                <i class="fas fa-download me-1"></i>Export Report
            </a>
        </div>
    </div>

    <!-- Statistics Cards -->
    <div class="row mb-4">
        <div class="col-lg-3 col-md-6 mb-3">
            <div class="card stats-card">
                <div class="card-body d-flex align-items-center">
                    <div class="stats-icon bg-primary me-3">
                        <i class="fas fa-globe"></i>
                    </div>
                    <div>
                        <h3 class="mb-0">{{ number_format($stats['total_events']) }}</h3>
                        <small class="text-muted">Total URL Events</small>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-lg-3 col-md-6 mb-3">
            <div class="card stats-card">
                <div class="card-body d-flex align-items-center">
                    <div class="stats-icon bg-success me-3">
                        <i class="fas fa-link"></i>
                    </div>
                    <div>
                        <h3 class="mb-0">{{ number_format($stats['unique_urls']) }}</h3>
                        <small class="text-muted">Unique URLs</small>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-lg-3 col-md-6 mb-3">
            <div class="card stats-card">
                <div class="card-body d-flex align-items-center">
                    <div class="stats-icon bg-warning me-3">
                        <i class="fas fa-clock"></i>
                    </div>
                    <div>
                        <h3 class="mb-0">{{ $stats['avg_duration'] }}m</h3>
                        <small class="text-muted">Avg Duration</small>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-lg-3 col-md-6 mb-3">
            <div class="card stats-card">
                <div class="card-body d-flex align-items-center">
                    <div class="stats-icon bg-info me-3">
                        <i class="fas fa-users"></i>
                    </div>
                    <div>
                        <h3 class="mb-0">{{ number_format($stats['active_clients']) }}</h3>
                        <small class="text-muted">Active Clients</small>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Filter Form -->
    <div class="card mb-4">
        <div class="card-header">
            <i class="fas fa-filter me-2"></i>Filter URL Activity
        </div>
        <div class="card-body">
            <form method="GET" action="{{ route('url.activity') }}">
                <div class="row g-3">
                    <div class="col-md-2">
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
                    <div class="col-md-2">
                        <label class="form-label">Date Range</label>
                        <select name="date_range" class="form-select">
                            <option value="today" {{ request('date_range', 'today') == 'today' ? 'selected' : '' }}>Today</option>
                            <option value="yesterday" {{ request('date_range') == 'yesterday' ? 'selected' : '' }}>Yesterday</option>
                            <option value="week" {{ request('date_range') == 'week' ? 'selected' : '' }}>This Week</option>
                            <option value="month" {{ request('date_range') == 'month' ? 'selected' : '' }}>This Month</option>
                        </select>
                    </div>
                    <div class="col-md-2">
                        <label class="form-label">Event Type</label>
                        <select name="event_type" class="form-select">
                            <option value="">All Events</option>
                            <option value="url_opened" {{ request('event_type') == 'url_opened' ? 'selected' : '' }}>URL Opened</option>
                            <option value="url_closed" {{ request('event_type') == 'url_closed' ? 'selected' : '' }}>URL Closed</option>
                        </select>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label">Search URL</label>
                        <input type="text" name="search" class="form-control"
                               placeholder="Search URLs or page titles..."
                               value="{{ request('search') }}">
                    </div>
                    <div class="col-md-2 d-flex align-items-end">
                        <button type="submit" class="btn btn-primary me-2">
                            <i class="fas fa-search me-1"></i>Filter
                        </button>
                        <a href="{{ route('url.activity') }}" class="btn btn-outline-secondary">
                            <i class="fas fa-times me-1"></i>Clear
                        </a>
                    </div>
                </div>
            </form>
        </div>
    </div>

    <!-- Main Content Area -->
    <div class="row">
        <!-- URL Events List -->
        <div class="col-lg-8">
            <div class="card">
                <div class="card-header">
                    <div class="d-flex justify-content-between align-items-center">
                        <h6 class="mb-0">
                            <i class="fas fa-list me-2"></i>URL Events
                        </h6>
                        <div class="text-end">
                            <small class="text-muted d-block">
                                {{ number_format($urlEvents->total()) }} total events
                            </small>
                            @if($urlEvents->hasPages())
                                <small class="text-muted">
                                    Page {{ $urlEvents->currentPage() }} of {{ $urlEvents->lastPage() }}
                                </small>
                            @endif
                        </div>
                    </div>
                </div>
                <div class="card-body">
                    @if($urlEvents->count() > 0)
                        <div class="list-group list-group-flush">
                            @foreach($urlEvents as $event)
                                <div class="url-item p-3 mb-3">
                                    <div class="d-flex justify-content-between align-items-start">
                                        <div class="flex-grow-1">
                                            <div class="d-flex align-items-center mb-2">
                                                <span class="badge event-badge {{ $event->event_type == 'url_opened' ? 'bg-success' : 'bg-warning' }} me-2">
                                                    {{ $event->event_type == 'url_opened' ? 'Opened' : 'Closed' }}
                                                </span>
                                                <small class="text-muted">
                                                    <i class="fas fa-user me-1"></i>{{ $event->client->hostname ?? 'Unknown' }}
                                                    <i class="fas fa-clock ms-3 me-1"></i>{{ \Carbon\Carbon::parse($event->start_time)->format('H:i:s') }}
                                                    @if($event->duration)
                                                        <i class="fas fa-stopwatch ms-3 me-1"></i>{{ gmdate('H:i:s', $event->duration) }}
                                                    @endif
                                                </small>
                                            </div>
                                            <h6 class="mb-1">
                                                {{ Str::limit($event->page_title ?? 'No title', 60) }}
                                            </h6>
                                            <a href="{{ $event->url }}" target="_blank" class="url-link">
                                                <i class="fas fa-external-link-alt me-1"></i>{{ Str::limit($event->url, 80) }}
                                            </a>
                                        </div>
                                        <div class="text-end">
                                            <small class="text-muted">
                                                {{ \Carbon\Carbon::parse($event->created_at)->format('M d, Y') }}
                                            </small>
                                        </div>
                                    </div>
                                </div>
                            @endforeach
                        </div>

                        <!-- Pagination -->
                        <div class="mt-4">
                            <div class="row align-items-center mb-3">
                                <div class="col-md-6">
                                    <small class="text-muted">
                                        Showing {{ $urlEvents->firstItem() ?? 0 }} to {{ $urlEvents->lastItem() ?? 0 }}
                                        of {{ number_format($urlEvents->total()) }} events
                                    </small>
                                </div>
                                <div class="col-md-6 text-end">
                                    @if($urlEvents->hasPages())
                                        <div class="btn-group btn-group-sm" role="group">
                                            @if($urlEvents->currentPage() > 1)
                                                <a href="{{ $urlEvents->appends(request()->query())->url(1) }}"
                                                   class="btn btn-outline-secondary btn-sm">
                                                    <i class="fas fa-fast-backward"></i> First
                                                </a>
                                            @endif

                                            @if($urlEvents->hasMorePages())
                                                <a href="{{ $urlEvents->appends(request()->query())->url($urlEvents->lastPage()) }}"
                                                   class="btn btn-outline-secondary btn-sm">
                                                    Last <i class="fas fa-fast-forward"></i>
                                                </a>
                                            @endif
                                        </div>
                                    @endif
                                </div>
                            </div>

                            @if($urlEvents->hasPages())
                                <nav aria-label="URL Events pagination">
                                    <ul class="pagination pagination-sm justify-content-center mb-0">
                                        {{-- Previous Page Link --}}
                                        @if($urlEvents->onFirstPage())
                                            <li class="page-item disabled">
                                                <span class="page-link">
                                                    <i class="fas fa-chevron-left"></i> Previous
                                                </span>
                                            </li>
                                        @else
                                            <li class="page-item">
                                                <a class="page-link" href="{{ $urlEvents->appends(request()->query())->previousPageUrl() }}">
                                                    <i class="fas fa-chevron-left"></i> Previous
                                                </a>
                                            </li>
                                        @endif

                                        {{-- First Page Link --}}
                                        @if($urlEvents->currentPage() > 3)
                                            <li class="page-item">
                                                <a class="page-link" href="{{ $urlEvents->appends(request()->query())->url(1) }}">1</a>
                                            </li>
                                            @if($urlEvents->currentPage() > 4)
                                                <li class="page-item disabled"><span class="page-link">...</span></li>
                                            @endif
                                        @endif

                                        {{-- Page Number Links --}}
                                        @for($i = max(1, $urlEvents->currentPage() - 2); $i <= min($urlEvents->lastPage(), $urlEvents->currentPage() + 2); $i++)
                                            @if($i == $urlEvents->currentPage())
                                                <li class="page-item active">
                                                    <span class="page-link">{{ $i }}</span>
                                                </li>
                                            @else
                                                <li class="page-item">
                                                    <a class="page-link" href="{{ $urlEvents->appends(request()->query())->url($i) }}">{{ $i }}</a>
                                                </li>
                                            @endif
                                        @endfor

                                        {{-- Last Page Link --}}
                                        @if($urlEvents->currentPage() < $urlEvents->lastPage() - 2)
                                            @if($urlEvents->currentPage() < $urlEvents->lastPage() - 3)
                                                <li class="page-item disabled"><span class="page-link">...</span></li>
                                            @endif
                                            <li class="page-item">
                                                <a class="page-link" href="{{ $urlEvents->appends(request()->query())->url($urlEvents->lastPage()) }}">{{ $urlEvents->lastPage() }}</a>
                                            </li>
                                        @endif

                                        {{-- Next Page Link --}}
                                        @if($urlEvents->hasMorePages())
                                            <li class="page-item">
                                                <a class="page-link" href="{{ $urlEvents->appends(request()->query())->nextPageUrl() }}">
                                                    Next <i class="fas fa-chevron-right"></i>
                                                </a>
                                            </li>
                                        @else
                                            <li class="page-item disabled">
                                                <span class="page-link">
                                                    Next <i class="fas fa-chevron-right"></i>
                                                </span>
                                            </li>
                                        @endif
                                    </ul>
                                </nav>
                            @endif
                        </div>
                    @else
                        <div class="text-center py-5">
                            <i class="fas fa-globe fa-3x text-muted mb-3"></i>
                            <h5 class="text-muted">No URL events found</h5>
                            <p class="text-muted">Try adjusting your filters or check back later.</p>
                        </div>
                    @endif
                </div>
            </div>
        </div>

        <!-- Top URLs & Domains -->
        <div class="col-lg-4">
            <!-- Top URLs -->
            <div class="card mb-4">
                <div class="card-header">
                    <h6 class="mb-0">
                        <i class="fas fa-chart-bar me-2"></i>Top URLs
                    </h6>
                </div>
                <div class="card-body">
                    @if(!empty($topUrls) && count($topUrls) > 0)
                        @foreach($topUrls as $urlData)
                            <div class="d-flex justify-content-between align-items-center mb-3">
                                <div class="flex-grow-1">
                                    <h6 class="mb-1">{{ Str::limit($urlData['title'], 25) }}</h6>
                                    <small class="text-muted">{{ Str::limit($urlData['url'], 35) }}</small>
                                    <div class="progress mt-1" style="height: 6px;">
                                        <div class="progress-bar bg-primary"
                                             style="width: {{ count($topUrls) > 0 && $topUrls[0]['visits'] > 0 ? ($urlData['visits'] / $topUrls[0]['visits']) * 100 : 100 }}%"></div>
                                    </div>
                                </div>
                                <div class="text-end ms-3">
                                    <span class="badge bg-primary">{{ $urlData['visits'] }}</span>
                                    @if($urlData['total_duration'] > 0)
                                        <br><small class="text-muted">{{ $urlData['total_duration'] }}m</small>
                                    @endif
                                </div>
                            </div>
                        @endforeach
                    @else
                        <p class="text-muted text-center">No URL data available</p>
                    @endif
                </div>
            </div>

            <!-- Top Domains -->
            <div class="card">
                <div class="card-header">
                    <h6 class="mb-0">
                        <i class="fas fa-chart-pie me-2"></i>Top Domains
                    </h6>
                </div>
                <div class="card-body">
                    @if(!empty($topDomains) && count($topDomains) > 0)
                        @foreach($topDomains as $domain)
                            <div class="domain-card p-2 mb-3">
                                <div class="d-flex justify-content-between align-items-center">
                                    <div class="flex-grow-1">
                                        <h6 class="mb-1">{{ $domain['domain'] }}</h6>
                                        <div class="progress" style="height: 6px;">
                                            <div class="progress-bar bg-success"
                                                 style="width: {{ count($topDomains) > 0 && $topDomains[0]['visits'] > 0 ? ($domain['visits'] / $topDomains[0]['visits']) * 100 : 100 }}%"></div>
                                        </div>
                                    </div>
                                    <div class="text-end ms-3">
                                        <span class="badge bg-success">{{ $domain['visits'] }}</span>
                                        @if($domain['duration'] > 0)
                                            <br><small class="text-muted">{{ $domain['duration'] }}m</small>
                                        @endif
                                    </div>
                                </div>
                            </div>
                        @endforeach
                    @else
                        <p class="text-muted text-center">No domain data available</p>
                    @endif
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
