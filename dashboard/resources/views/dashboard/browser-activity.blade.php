@extends('layouts.app')

@section('title', 'Browser Activity - Tenjo Dashboard')

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

.timeline {
    position: relative;
    padding-left: 30px;
}

.timeline::before {
    content: '';
    position: absolute;
    left: 15px;
    top: 0;
    bottom: 0;
    width: 2px;
    background: var(--bs-border-color);
}

.timeline-item {
    position: relative;
    margin-bottom: 20px;
}

.timeline-marker {
    position: absolute;
    left: -22px;
    top: 5px;
    width: 30px;
    height: 30px;
    background: white;
    border: 2px solid var(--bs-primary);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
}

.timeline-content {
    background: var(--bs-gray-50);
    padding: 15px;
    border-radius: 8px;
    border-left: 3px solid var(--bs-primary);
}

.table th {
    border-top: none;
    font-weight: 600;
    background-color: #f8f9fa;
}

/* Custom Pagination Styles */
.pagination-info {
    font-size: 0.875rem;
    color: #6c757d;
}

.pagination-sm .page-link {
    padding: 0.375rem 0.75rem;
    font-size: 0.875rem;
    border-radius: 0.25rem;
    transition: all 0.2s ease-in-out;
}

.pagination-sm .page-link:hover {
    background-color: #e9ecef;
    border-color: #dee2e6;
    transform: translateY(-1px);
}

.pagination-sm .page-item.active .page-link {
    background-color: #0d6efd;
    border-color: #0d6efd;
    box-shadow: 0 2px 4px rgba(13, 110, 253, 0.25);
}

.pagination-sm .page-item.disabled .page-link {
    color: #adb5bd;
    background-color: #fff;
    border-color: #dee2e6;
}

.pagination .page-item:first-child .page-link,
.pagination .page-item:last-child .page-link {
    border-radius: 0.25rem;
}

@media (max-width: 992px) {
    .col-lg-4 .card {
        margin-bottom: 1rem;
    }

    /* Tablet - keep text left aligned */
    .col-lg-4 .card-body .d-flex {
        justify-content: space-between !important;
        align-items: center !important;
    }

    .col-lg-4 .card-body .flex-grow-1 {
        text-align: left !important;
    }

    .col-lg-4 .card-body .flex-grow-1 h6 {
        text-align: left !important;
        margin-bottom: 0.5rem;
    }
}

@media (max-width: 768px) {
    .pagination-info {
        margin-bottom: 1rem;
        text-align: center;
    }

    .d-flex.justify-content-between {
        flex-direction: column;
        align-items: center;
    }

    /* Mobile responsive for domain and browser cards */
    .col-lg-4 .card-body .d-flex {
        flex-direction: column !important;
        align-items: flex-start !important;
        justify-content: flex-start !important;
        text-align: left !important;
    }

    .col-lg-4 .card-body .flex-grow-1 {
        margin-bottom: 0.5rem;
        text-align: left !important;
        width: 100%;
    }

    .col-lg-4 .card-body .flex-grow-1 h6 {
        text-align: left !important;
        margin-bottom: 0.5rem;
    }

    .col-lg-4 .card-body .progress {
        margin-bottom: 0.5rem;
        width: 100%;
    }

    .col-lg-4 .card-body .badge {
        margin-left: 0 !important;
        margin-top: 0.25rem;
        align-self: flex-start !important;
    }
}
</style>
@endsection

@section('content')
<div class="fade-in">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <div>
            <h2 class="page-title">Browser Activity</h2>
            <p class="text-muted">Monitor browser usage and web activity across all clients</p>
        </div>
    </div>

    <!-- Filter Form -->
    <div class="card mb-4">
        <div class="card-header">
            <i class="fas fa-filter me-2"></i>Filter Browser Activity
        </div>
        <div class="card-body">
            <form method="GET" action="{{ route('browser.activity') }}">
                <div class="row g-3">
                    <div class="col-md-3">
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
                    <div class="col-md-3">
                        <label class="form-label">Date Range</label>
                        <select name="date_range" class="form-select">
                            <option value="today" {{ request('date_range', 'today') == 'today' ? 'selected' : '' }}>Today</option>
                            <option value="yesterday" {{ request('date_range') == 'yesterday' ? 'selected' : '' }}>Yesterday</option>
                            <option value="week" {{ request('date_range') == 'week' ? 'selected' : '' }}>This Week</option>
                            <option value="month" {{ request('date_range') == 'month' ? 'selected' : '' }}>This Month</option>
                        </select>
                    </div>
                    <div class="col-md-3">
                        <label class="form-label">Browser</label>
                        <select name="browser" class="form-select">
                            <option value="">All Browsers</option>
                            <option value="chrome" {{ request('browser') == 'chrome' ? 'selected' : '' }}>Chrome</option>
                            <option value="firefox" {{ request('browser') == 'firefox' ? 'selected' : '' }}>Firefox</option>
                            <option value="safari" {{ request('browser') == 'safari' ? 'selected' : '' }}>Safari</option>
                            <option value="edge" {{ request('browser') == 'edge' ? 'selected' : '' }}>Edge</option>
                        </select>
                    </div>
                    <div class="col-md-3 d-flex align-items-end">
                        <button type="submit" class="btn btn-primary">
                            <i class="fas fa-search me-1"></i>Filter
                        </button>
                    </div>
                </div>
            </form>
        </div>
    </div>

    <!-- Statistics Cards -->
    <div class="row mb-4">
        <div class="col-md-3 mb-3">
            <div class="card stats-card">
                <div class="card-body">
                    <div class="d-flex align-items-center">
                        <div class="stats-icon bg-primary">
                            <i class="fas fa-globe"></i>
                        </div>
                        <div class="ms-3">
                            <h5 class="mb-0">{{ number_format($stats['total_events'] ?? 0) }}</h5>
                            <small class="text-muted">Total Events</small>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-md-3 mb-3">
            <div class="card stats-card">
                <div class="card-body">
                    <div class="d-flex align-items-center">
                        <div class="stats-icon bg-success">
                            <i class="fas fa-link"></i>
                        </div>
                        <div class="ms-3">
                            <h5 class="mb-0">{{ number_format($stats['unique_urls'] ?? 0) }}</h5>
                            <small class="text-muted">Unique URLs</small>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-md-3 mb-3">
            <div class="card stats-card">
                <div class="card-body">
                    <div class="d-flex align-items-center">
                        <div class="stats-icon bg-warning">
                            <i class="fas fa-clock"></i>
                        </div>
                        <div class="ms-3">
                            <h5 class="mb-0">{{ number_format($stats['avg_session_time'] ?? 0) }}m</h5>
                            <small class="text-muted">Avg Session</small>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-md-3 mb-3">
            <div class="card stats-card">
                <div class="card-body">
                    <div class="d-flex align-items-center">
                        <div class="stats-icon bg-info">
                            <i class="fas fa-users"></i>
                        </div>
                        <div class="ms-3">
                            <h5 class="mb-0">{{ number_format($stats['active_clients'] ?? 0) }}</h5>
                            <small class="text-muted">Active Clients</small>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="row">
        <!-- Recent Browser Activity -->
        <div class="col-lg-8 mb-4">
            <div class="card">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h5 class="mb-0">
                        <i class="fas fa-history me-2"></i>Recent Activity
                    </h5>
                    <div class="btn-group btn-group-sm" role="group">
                        <input type="radio" class="btn-check" name="activity-view" id="timeline-view" checked>
                        <label class="btn btn-outline-primary" for="timeline-view">Timeline</label>
                        <input type="radio" class="btn-check" name="activity-view" id="table-view">
                        <label class="btn btn-outline-primary" for="table-view">Table</label>
                    </div>
                </div>
                <div class="card-body">
                    <div id="timeline-container">
                        @if($browserEvents->count() > 0)
                            <div class="timeline">
                                @foreach($browserEvents as $event)
                                    <div class="timeline-item">
                                        <div class="timeline-marker">
                                            <i class="fas fa-globe text-primary"></i>
                                        </div>
                                        <div class="timeline-content">
                                            <div class="d-flex justify-content-between align-items-start">
                                                <div class="flex-grow-1">
                                                    <h6 class="mb-1">{{ $event->title ?: 'Browser Activity' }}</h6>
                                                    <p class="mb-1">
                                                        <a href="{{ $event->url ?: '#' }}" target="_blank" class="text-decoration-none">
                                                            {{ Str::limit($event->url ?: 'No URL', 60) }}
                                                        </a>
                                                    </p>
                                                    <div class="text-muted small">
                                                        <i class="fas fa-desktop me-1"></i>{{ $event->client->hostname ?? 'Unknown' }}
                                                        <i class="fas fa-globe ms-3 me-1"></i>{{ $event->browser_name ?? 'Unknown' }}
                                                        <i class="fas fa-tag ms-3 me-1"></i>{{ ucfirst($event->event_type) }}
                                                    </div>
                                                </div>
                                                <span class="badge bg-light text-dark">
                                                    {{ $event->created_at->format('H:i') }}
                                                </span>
                                            </div>
                                        </div>
                                    </div>
                                @endforeach
                            </div>
                        @else
                            <div class="text-center py-5">
                                <div class="mb-4">
                                    <i class="fas fa-globe-americas text-muted" style="font-size: 4rem;"></i>
                                </div>
                                <h5 class="text-muted mb-3">No Browser Activity Found</h5>
                                <p class="text-muted mb-4">No browser activity found for the selected filters.</p>
                                <div class="alert alert-info">
                                    <i class="fas fa-info-circle me-2"></i>
                                    Try adjusting your filters or check if clients are actively monitored.
                                </div>
                            </div>
                        @endif
                    </div>

                    <div id="table-container" class="d-none">
                        <div class="table-responsive">
                            <table class="table table-hover">
                                <thead>
                                    <tr>
                                        <th>Time</th>
                                        <th>Client</th>
                                        <th>Browser</th>
                                        <th>Event Type</th>
                                        <th>URL</th>
                                        <th>Title</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @foreach($browserEvents as $event)
                                        <tr>
                                            <td>{{ $event->created_at->format('H:i:s') }}</td>
                                            <td>{{ $event->client->hostname ?? 'Unknown' }}</td>
                                            <td>
                                                <span class="badge bg-primary">{{ $event->browser_name ?? 'Unknown' }}</span>
                                            </td>
                                            <td>
                                                <span class="badge bg-info">{{ ucfirst($event->event_type) }}</span>
                                            </td>
                                            <td>
                                                @if($event->url)
                                                    <a href="{{ $event->url }}" target="_blank" class="text-decoration-none">
                                                        {{ Str::limit($event->url, 40) }}
                                                    </a>
                                                @else
                                                    <span class="text-muted">No URL</span>
                                                @endif
                                            </td>
                                            <td>{{ Str::limit($event->title ?? 'No title', 30) }}</td>
                                        </tr>
                                    @endforeach
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <!-- Custom Pagination -->
                    @if($browserEvents->hasPages())
                        <div class="mt-4 pt-3 border-top">
                            <div class="row align-items-center mb-3">
                                <div class="col-md-6">
                                    <small class="text-muted">
                                        Showing {{ $browserEvents->firstItem() }} to {{ $browserEvents->lastItem() }}
                                        of {{ number_format($browserEvents->total()) }} events
                                    </small>
                                </div>
                                <div class="col-md-6 text-end">
                                    <div class="btn-group btn-group-sm" role="group">
                                        @if($browserEvents->currentPage() > 1)
                                            <a href="{{ $browserEvents->appends(request()->query())->url(1) }}"
                                               class="btn btn-outline-secondary btn-sm">
                                                <i class="fas fa-fast-backward"></i> First
                                            </a>
                                        @endif

                                        @if($browserEvents->hasMorePages())
                                            <a href="{{ $browserEvents->appends(request()->query())->url($browserEvents->lastPage()) }}"
                                               class="btn btn-outline-secondary btn-sm">
                                                Last <i class="fas fa-fast-forward"></i>
                                            </a>
                                        @endif
                                    </div>
                                </div>
                            </div>

                            <nav aria-label="Browser Events Pagination">
                                <ul class="pagination pagination-sm justify-content-center mb-0">
                                    {{-- Previous Page Link --}}
                                    @if($browserEvents->onFirstPage())
                                        <li class="page-item disabled">
                                            <span class="page-link">
                                                <i class="fas fa-chevron-left"></i> Previous
                                            </span>
                                        </li>
                                    @else
                                        <li class="page-item">
                                            <a class="page-link" href="{{ $browserEvents->appends(request()->query())->previousPageUrl() }}">
                                                <i class="fas fa-chevron-left"></i> Previous
                                            </a>
                                        </li>
                                    @endif

                                    {{-- Page Number Links --}}
                                    @php
                                        $start = max($browserEvents->currentPage() - 2, 1);
                                        $end = min($start + 4, $browserEvents->lastPage());
                                        $start = max($end - 4, 1);
                                    @endphp

                                    @if($start > 1)
                                        <li class="page-item">
                                            <a class="page-link" href="{{ $browserEvents->appends(request()->query())->url(1) }}">1</a>
                                        </li>
                                        @if($start > 2)
                                            <li class="page-item disabled">
                                                <span class="page-link">...</span>
                                            </li>
                                        @endif
                                    @endif

                                    @for($i = $start; $i <= $end; $i++)
                                        @if($i == $browserEvents->currentPage())
                                            <li class="page-item active">
                                                <span class="page-link">{{ $i }}</span>
                                            </li>
                                        @else
                                            <li class="page-item">
                                                <a class="page-link" href="{{ $browserEvents->appends(request()->query())->url($i) }}">{{ $i }}</a>
                                            </li>
                                        @endif
                                    @endfor

                                    @if($end < $browserEvents->lastPage())
                                        @if($end < $browserEvents->lastPage() - 1)
                                            <li class="page-item disabled">
                                                <span class="page-link">...</span>
                                            </li>
                                        @endif
                                        <li class="page-item">
                                            <a class="page-link" href="{{ $browserEvents->appends(request()->query())->url($browserEvents->lastPage()) }}">{{ $browserEvents->lastPage() }}</a>
                                        </li>
                                    @endif

                                    {{-- Next Page Link --}}
                                    @if($browserEvents->hasMorePages())
                                        <li class="page-item">
                                            <a class="page-link" href="{{ $browserEvents->appends(request()->query())->nextPageUrl() }}">
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

                            <div class="text-center mt-2">
                                <small class="text-muted">
                                    Page {{ $browserEvents->currentPage() }} of {{ $browserEvents->lastPage() }}
                                </small>
                            </div>
                        </div>
                    @endif
                </div>
            </div>
        </div>

        <!-- Top Domains & Browsers -->
        <div class="col-lg-4">
            <!-- Top Domains -->
            <div class="card mb-4">
                <div class="card-header">
                    <h6 class="mb-0">
                        <i class="fas fa-chart-pie me-2"></i>Top Domains
                    </h6>
                </div>
                <div class="card-body">
                    @if(!empty($topDomains))
                        @foreach($topDomains as $domain)
                            <div class="d-flex justify-content-between align-items-center mb-3">
                                <div class="flex-grow-1">
                                    <h6 class="mb-1">{{ $domain['domain'] }}</h6>
                                    <div class="progress" style="height: 6px;">
                                        <div class="progress-bar bg-primary"
                                             style="width: {{ count($topDomains) > 0 && $topDomains[0]['visits'] > 0 ? ($domain['visits'] / $topDomains[0]['visits']) * 100 : 100 }}%"></div>
                                    </div>
                                </div>
                                <span class="badge bg-primary ms-2">{{ $domain['visits'] }}</span>
                            </div>
                        @endforeach
                    @else
                        <p class="text-muted text-center">No domain data available</p>
                    @endif
                </div>
            </div>

            <!-- Browser Distribution -->
            <div class="card">
                <div class="card-header">
                    <h6 class="mb-0">
                        <i class="fas fa-browser me-2"></i>Browser Usage
                    </h6>
                </div>
                <div class="card-body">
                    @if(!empty($browserStats))
                        @foreach($browserStats as $browser)
                            <div class="d-flex justify-content-between align-items-center mb-3">
                                <div class="flex-grow-1">
                                    <h6 class="mb-1">
                                        <i class="fab fa-{{ strtolower($browser['browser']) }} me-2"></i>
                                        {{ $browser['browser'] }}
                                    </h6>
                                    <div class="progress" style="height: 6px;">
                                        <div class="progress-bar bg-success"
                                             style="width: {{ count($browserStats) > 0 && $browserStats[0]['usage'] > 0 ? ($browser['usage'] / $browserStats[0]['usage']) * 100 : 100 }}%"></div>
                                    </div>
                                </div>
                                <span class="badge bg-success ms-2">{{ $browser['usage'] }}%</span>
                            </div>
                        @endforeach
                    @else
                        <p class="text-muted text-center">No browser data available</p>
                    @endif
                </div>
            </div>
        </div>
    </div>
</div>
@endsection

@section('scripts')
<script>
document.addEventListener('DOMContentLoaded', function() {
    // Activity view toggle
    const timelineView = document.getElementById('timeline-view');
    const tableView = document.getElementById('table-view');
    const timelineContainer = document.getElementById('timeline-container');
    const tableContainer = document.getElementById('table-container');

    timelineView.addEventListener('change', function() {
        if (this.checked) {
            timelineContainer.classList.remove('d-none');
            tableContainer.classList.add('d-none');
        }
    });

    tableView.addEventListener('change', function() {
        if (this.checked) {
            timelineContainer.classList.add('d-none');
            tableContainer.classList.remove('d-none');
        }
    });
});
</script>
@endsection
