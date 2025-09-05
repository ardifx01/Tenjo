@extends('layouts.app')

@section('title', 'Client Details - ' . $client->hostname)

@section('breadcrumb')
<nav aria-label="breadcrumb">
    <ol class="breadcrumb">
        <li class="breadcrumb-item"><a href="{{ route('dashboard') }}">Dashboard</a></li>
        <li class="breadcrumb-item active">{{ $client->hostname }}</li>
    </ol>
</nav>
@endsection

@section('content')
<div class="d-flex justify-content-between align-items-center mb-4">
    <div>
        <h1 class="h3 mb-0">{{ $client->hostname }}</h1>
        <p class="text-muted mb-0">Client Details & Activity</p>
    </div>
    <div>
        <a href="{{ route('client.live', $client->client_id) }}" class="btn btn-primary">
            <i class="fas fa-video"></i> Live View
        </a>
    </div>
</div>

<!-- Client Info -->
<div class="row mb-4">
    <div class="col-md-4">
        <div class="card">
            <div class="card-header">
                <h6 class="mb-0">Client Information</h6>
            </div>
            <div class="card-body">
                <dl class="row">
                    <dt class="col-sm-4">Hostname:</dt>
                    <dd class="col-sm-8">{{ $client->hostname }}</dd>

                    <dt class="col-sm-4">User:</dt>
                    <dd class="col-sm-8">{{ $client->username }}</dd>

                    <dt class="col-sm-4">IP Address:</dt>
                    <dd class="col-sm-8">{{ $client->ip_address }}</dd>

                    <dt class="col-sm-4">Status:</dt>
                    <dd class="col-sm-8">
                        <span class="badge {{ $client->isOnline() ? 'bg-success' : 'bg-secondary' }}">
                            {{ $client->isOnline() ? 'Online' : 'Offline' }}
                        </span>
                    </dd>

                    <dt class="col-sm-4">OS:</dt>
                    <dd class="col-sm-8">{{ $client->getOsDisplayName() }}</dd>

                    <dt class="col-sm-4">Last Seen:</dt>
                    <dd class="col-sm-8">{{ $client->last_seen ? $client->last_seen->diffForHumans() : 'Never' }}</dd>
                </dl>
            </div>
        </div>
    </div>

    <div class="col-md-8">
        <div class="card">
            <div class="card-header">
                <h6 class="mb-0">Today's Activity Summary</h6>
            </div>
            <div class="card-body">
                <div class="row text-center">
                    <div class="col-md-3">
                        <div class="border-end">
                            <h4 class="text-primary mb-0">{{ $client->screenshots->count() }}</h4>
                            <small class="text-muted">Screenshots</small>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="border-end">
                            <h4 class="text-success mb-0">{{ $browserStats->sum('sessions') }}</h4>
                            <small class="text-muted">Browser Sessions</small>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="border-end">
                            <h4 class="text-info mb-0">{{ $client->urlEvents->count() }}</h4>
                            <small class="text-muted">URLs Visited</small>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <h4 class="text-warning mb-0">{{ $client->processEvents->count() }}</h4>
                        <small class="text-muted">Process Events</small>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Browser Usage Stats -->
@if($browserStats->count() > 0)
<div class="card mb-4">
    <div class="card-header">
        <h6 class="mb-0">Browser Usage Today</h6>
    </div>
    <div class="card-body">
        <div class="row">
            <div class="col-md-8">
                <canvas id="browserChart" height="100"></canvas>
            </div>
            <div class="col-md-4">
                @foreach($browserStats as $browser)
                <div class="d-flex justify-content-between align-items-center mb-2">
                    <div>
                        <strong>{{ $browser->browser_name }}</strong>
                        <br>
                        <small class="text-muted">{{ $browser->sessions }} sessions</small>
                    </div>
                    <div class="text-end">
                        <span class="badge bg-primary">{{ gmdate('H:i:s', $browser->total_duration) }}</span>
                    </div>
                </div>
                @endforeach
            </div>
        </div>
    </div>
</div>
@endif

<!-- Screenshots -->
<div class="card mb-4">
    <div class="card-header d-flex justify-content-between align-items-center">
        <h6 class="mb-0">Screenshots (Today)</h6>
        <a href="{{ route('screenshots', ['client_id' => $client->client_id]) }}" class="btn btn-sm btn-outline-primary">
            View All
        </a>
    </div>
    <div class="card-body">
        @if($client->screenshots->count() > 0)
            <div class="row">
                @foreach($client->screenshots->take(6) as $screenshot)
                <div class="col-md-2 mb-3">
                    <div class="position-relative">
                        <img src="{{ $screenshot->url }}"
                             class="img-fluid rounded screenshot-thumbnail"
                             style="width: 100%; height: 100px; object-fit: cover;"
                             data-bs-toggle="modal"
                             data-bs-target="#screenshotModal"
                             data-screenshot="{{ $screenshot->url }}"
                             data-time="{{ $screenshot->captured_at->format('H:i:s') }}">
                        <div class="position-absolute bottom-0 start-0 end-0 bg-dark bg-opacity-75 text-white text-center py-1">
                            <small>{{ $screenshot->captured_at->format('H:i') }}</small>
                        </div>
                    </div>
                </div>
                @endforeach
            </div>
        @else
            <p class="text-muted text-center">No screenshots available for today.</p>
        @endif
    </div>
</div>

<!-- Top URLs -->
@if($topUrls->count() > 0)
<div class="card mb-4">
    <div class="card-header">
        <h6 class="mb-0">Top URLs Visited Today</h6>
    </div>
    <div class="card-body">
        <div class="table-responsive">
            <table class="table table-sm">
                <thead>
                    <tr>
                        <th>URL</th>
                        <th>Visits</th>
                        <th>Total Time</th>
                        <th>Average Time</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach($topUrls as $url)
                    <tr>
                        <td>
                            <div class="text-truncate" style="max-width: 300px;">
                                <a href="{{ $url->url }}" target="_blank" class="text-decoration-none">
                                    {{ $url->url }}
                                </a>
                            </div>
                        </td>
                        <td>{{ $url->visits }}</td>
                        <td>{{ gmdate('H:i:s', $url->total_duration) }}</td>
                        <td>{{ gmdate('H:i:s', $url->total_duration / $url->visits) }}</td>
                    </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    </div>
</div>
@endif

<!-- Recent Browser Activity -->
<div class="card">
    <div class="card-header">
        <h6 class="mb-0">Recent Browser Activity</h6>
    </div>
    <div class="card-body">
        @if($client->browserEvents->count() > 0)
            <div class="table-responsive">
                <table class="table table-sm table-striped">
                    <thead>
                        <tr>
                            <th>Time</th>
                            <th>Event</th>
                            <th>Browser</th>
                            <th>Duration</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach($client->browserEvents->take(10) as $event)
                        <tr>
                            <td>{{ $event->start_time ? $event->start_time->format('H:i:s') : '-' }}</td>
                            <td>
                                <span class="badge {{ $event->event_type === 'browser_started' ? 'bg-success' : 'bg-danger' }}">
                                    {{ ucfirst(str_replace('_', ' ', $event->event_type)) }}
                                </span>
                            </td>
                            <td>{{ $event->browser_name }}</td>
                            <td>{{ $event->duration ? gmdate('H:i:s', $event->duration) : '-' }}</td>
                        </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        @else
            <p class="text-muted text-center">No browser activity recorded today.</p>
        @endif
    </div>
</div>

<!-- Screenshot Modal -->
<div class="modal fade" id="screenshotModal" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Screenshot</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body text-center">
                <img id="modalScreenshot" src="" class="img-fluid rounded">
                <p id="modalTime" class="mt-2 text-muted"></p>
            </div>
        </div>
    </div>
</div>
@endsection

@section('scripts')
<script>
    // Screenshot modal
    document.addEventListener('DOMContentLoaded', function() {
        const modal = document.getElementById('screenshotModal');
        if (modal) {
            modal.addEventListener('show.bs.modal', function(event) {
                const button = event.relatedTarget;
                const screenshot = button.getAttribute('data-screenshot');
                const time = button.getAttribute('data-time');

                document.getElementById('modalScreenshot').src = screenshot;
                document.getElementById('modalTime').textContent = 'Captured at: ' + time;
            });
        }
    });

    // Browser usage chart
    @if($browserStats->count() > 0)
    const ctx = document.getElementById('browserChart').getContext('2d');
    new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: [
                @foreach($browserStats as $browser)
                '{{ $browser->browser_name }}',
                @endforeach
            ],
            datasets: [{
                data: [
                    @foreach($browserStats as $browser)
                    {{ $browser->total_duration }},
                    @endforeach
                ],
                backgroundColor: [
                    '#FF6384',
                    '#36A2EB',
                    '#FFCE56',
                    '#4BC0C0',
                    '#9966FF',
                    '#FF9F40'
                ]
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    display: false
                }
            }
        }
    });
    @endif
</script>
@endsection
