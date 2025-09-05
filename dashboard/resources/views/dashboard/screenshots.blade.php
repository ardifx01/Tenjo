@extends('layouts.app')

@section('title', 'Screenshots - Tenjo Dashboard')

@section('styles')
<style>
.screenshot-card {
    transition: transform 0.2s, box-shadow 0.2s;
    border: none;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.screenshot-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 16px rgba(0,0,0,0.15);
}

.screenshot-thumbnail {
    border-radius: 0.375rem 0.375rem 0 0;
}

.pagination .page-link {
    border-radius: 0.375rem;
    margin: 0 2px;
    border: 1px solid #dee2e6;
}

.pagination .page-item.active .page-link {
    background-color: #0d6efd;
    border-color: #0d6efd;
}

.filter-card {
    border: none;
    box-shadow: 0 1px 4px rgba(0,0,0,0.1);
}

.table th {
    border-top: none;
    font-weight: 600;
    background-color: #f8f9fa;
}

.screenshot-thumbnail:hover {
    opacity: 0.8;
    transition: opacity 0.2s;
}

#screenshots-list .btn-sm {
    padding: 0.25rem 0.5rem;
}
</style>
@endsection

@section('content')
<div class="fade-in">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <div>
            <h2 class="page-title">Screenshots</h2>
            <p class="text-muted">View captured screenshots from all monitored clients</p>
        </div>
    </div>

    <!-- Filter Form -->
    <div class="card filter-card mb-4">
        <div class="card-header bg-light">
            <i class="fas fa-filter me-2"></i>Filter Screenshots
        </div>
        <div class="card-body">
            <form method="GET" action="{{ route('screenshots') }}">
                <div class="row g-3">
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
                    <div class="col-md-4">
                        <label class="form-label">Date</label>
                        <input type="date" name="date" class="form-control" value="{{ request('date', today()->toDateString()) }}">
                    </div>
                    <div class="col-md-4 d-flex align-items-end">
                        <button type="submit" class="btn btn-primary">
                            <i class="fas fa-search me-1"></i>Filter
                        </button>
                    </div>
                </div>
            </form>
        </div>
    </div>

    <!-- Screenshots Grid -->
    <div class="card">
        <div class="card-header d-flex justify-content-between align-items-center">
            <h5 class="mb-0">
                <i class="fas fa-images me-2"></i>Screenshots
                <span class="badge bg-primary ms-2">{{ $screenshots->total() }}</span>
            </h5>
            <div class="btn-group" role="group">
                <input type="radio" class="btn-check" name="view-mode" id="grid-view" checked>
                <label class="btn btn-outline-primary btn-sm" for="grid-view" title="Grid View">
                    <i class="fas fa-th"></i>
                </label>
                <input type="radio" class="btn-check" name="view-mode" id="list-view">
                <label class="btn btn-outline-primary btn-sm" for="list-view" title="List View">
                    <i class="fas fa-list"></i>
                </label>
            </div>
        </div>
        <div class="card-body">
            @if($screenshots->count() > 0)
                <div id="screenshots-grid" class="row">
                    @foreach($screenshots as $screenshot)
                        <div class="col-lg-3 col-md-4 col-sm-6 mb-4">
                            <div class="card screenshot-card h-100">
                                <div class="position-relative">
                                    <img src="{{ Storage::url($screenshot->file_path) }}"
                                         alt="Screenshot {{ $screenshot->filename }}"
                                         class="screenshot-thumbnail w-100"
                                         style="height: 200px; object-fit: cover; cursor: pointer;"
                                         data-bs-toggle="modal"
                                         data-bs-target="#screenshotModal"
                                         data-screenshot="{{ Storage::url($screenshot->file_path) }}">
                                    <div class="position-absolute top-0 end-0 m-2">
                                        <span class="badge bg-dark">{{ $screenshot->file_size ? number_format($screenshot->file_size / 1024, 0) . 'KB' : 'N/A' }}</span>
                                    </div>
                                </div>
                                <div class="card-body p-3">
                                    <div class="d-flex justify-content-between align-items-start mb-2">
                                        <h6 class="card-title mb-0">{{ $screenshot->client->hostname ?? 'Unknown' }}</h6>
                                        <small class="text-muted">{{ $screenshot->resolution ?? 'N/A' }}</small>
                                    </div>
                                    <p class="card-text mb-2">
                                        <small class="text-muted">
                                            <i class="fas fa-user me-1"></i>{{ $screenshot->client->username ?? 'Unknown' }}
                                        </small>
                                    </p>
                                    <p class="card-text mb-2">
                                        <small class="text-muted">
                                            <i class="fas fa-clock me-1"></i>
                                            {{ $screenshot->captured_at ? $screenshot->captured_at->diffForHumans() : $screenshot->created_at->diffForHumans() }}
                                        </small>
                                    </p>
                                    @if($screenshot->active_window)
                                        <p class="card-text mb-0">
                                            <small class="text-info">
                                                <i class="fas fa-window-maximize me-1"></i>
                                                {{ Str::limit($screenshot->active_window, 25) }}
                                            </small>
                                        </p>
                                    @endif
                                    <div class="d-flex justify-content-between align-items-center">
                                        <button class="btn btn-outline-primary btn-sm"
                                                data-bs-toggle="modal"
                                                data-bs-target="#screenshotModal"
                                                data-screenshot="{{ Storage::url($screenshot->file_path) }}">
                                            <i class="fas fa-eye me-1"></i>View
                                        </button>
                                        <button class="btn btn-outline-secondary btn-sm">
                                            <i class="fas fa-download"></i>
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    @endforeach
                </div>

                <!-- Pagination for Grid View -->
                <div id="grid-pagination" class="d-flex justify-content-between align-items-center mt-4">
                    <div class="text-muted">
                        Showing {{ $screenshots->firstItem() ?? 0 }} to {{ $screenshots->lastItem() ?? 0 }} of {{ $screenshots->total() }} screenshots
                    </div>
                    <div>
                        {{ $screenshots->appends(request()->query())->links('pagination::bootstrap-4') }}
                    </div>
                </div>

                <div id="screenshots-list" class="table-responsive d-none">
                    <table class="table">
                        <thead>
                            <tr>
                                <th>Preview</th>
                                <th>Client</th>
                                <th>Captured At</th>
                                <th>Active Window</th>
                                <th>Size</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($screenshots as $screenshot)
                                <tr>
                                    <td>
                                        <img src="{{ Storage::url($screenshot->file_path) }}"
                                             alt="Screenshot {{ $screenshot->filename }}"
                                             class="screenshot-thumbnail"
                                             style="width: 60px; height: 40px; object-fit: cover; cursor: pointer;"
                                             data-bs-toggle="modal"
                                             data-bs-target="#screenshotModal"
                                             data-screenshot="{{ Storage::url($screenshot->file_path) }}">
                                    </td>
                                    <td>{{ $screenshot->client->hostname ?? 'Unknown' }}</td>
                                    <td>{{ $screenshot->captured_at ? $screenshot->captured_at->format('M d, Y H:i') : $screenshot->created_at->format('M d, Y H:i') }}</td>
                                    <td>{{ Str::limit($screenshot->active_window ?? 'N/A', 40) }}</td>
                                    <td>{{ $screenshot->file_size ? number_format($screenshot->file_size / 1024, 0) . ' KB' : 'N/A' }}</td>
                                    <td>
                                        <button class="btn btn-outline-primary btn-sm me-1"
                                                data-bs-toggle="modal"
                                                data-bs-target="#screenshotModal"
                                                data-screenshot="{{ Storage::url($screenshot->file_path) }}">
                                            <i class="fas fa-eye"></i>
                                        </button>
                                        <button class="btn btn-outline-secondary btn-sm">
                                            <i class="fas fa-download"></i>
                                        </button>
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>

                <!-- Pagination for List View -->
                <div id="list-pagination" class="d-flex justify-content-between align-items-center mt-4 d-none">
                    <div class="text-muted">
                        Showing {{ $screenshots->firstItem() ?? 0 }} to {{ $screenshots->lastItem() ?? 0 }} of {{ $screenshots->total() }} screenshots
                    </div>
                    <div>
                        {{ $screenshots->appends(request()->query())->links('pagination::bootstrap-4') }}
                    </div>
                </div>
            @else
                <div class="text-center py-5">
                    <div class="mb-4">
                        <i class="fas fa-camera-retro text-muted" style="font-size: 4rem;"></i>
                    </div>
                    <h4 class="text-muted mb-3">No Screenshots Found</h4>
                    <p class="text-muted mb-4">No screenshots found for the selected filters.</p>
                    <div class="row justify-content-center">
                        <div class="col-md-8">
                            <div class="alert alert-info">
                                <i class="fas fa-info-circle me-2"></i>
                                <strong>Tips:</strong>
                                <ul class="mb-0 mt-2 text-start">
                                    <li>Try selecting a different date range</li>
                                    <li>Check if the client is actively monitored</li>
                                    <li>Screenshots are captured automatically every minute</li>
                                </ul>
                            </div>
                        </div>
                    </div>
                </div>
            @endif
        </div>
    </div>
</div>

<!-- Screenshot Modal -->
<div class="modal fade" id="screenshotModal" tabindex="-1" aria-labelledby="screenshotModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="screenshotModalLabel">Screenshot Preview</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body text-center">
                <div id="modal-loading" class="d-none">
                    <div class="spinner-border text-primary" role="status">
                        <span class="visually-hidden">Loading...</span>
                    </div>
                    <p class="mt-2">Loading screenshot...</p>
                </div>
                <img id="modal-screenshot" src="" alt="Screenshot" class="img-fluid" style="max-height: 70vh;">
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                <button type="button" class="btn btn-primary">Download</button>
            </div>
        </div>
    </div>
</div>
@endsection

@section('scripts')
<script>
document.addEventListener('DOMContentLoaded', function() {
    // View mode toggle
    const gridView = document.getElementById('grid-view');
    const listView = document.getElementById('list-view');
    const screenshotsGrid = document.getElementById('screenshots-grid');
    const screenshotsList = document.getElementById('screenshots-list');
    const gridPagination = document.getElementById('grid-pagination');
    const listPagination = document.getElementById('list-pagination');

    gridView.addEventListener('change', function() {
        if (this.checked) {
            screenshotsGrid.classList.remove('d-none');
            screenshotsList.classList.add('d-none');
            gridPagination.classList.remove('d-none');
            listPagination.classList.add('d-none');
        }
    });

    listView.addEventListener('change', function() {
        if (this.checked) {
            screenshotsGrid.classList.add('d-none');
            screenshotsList.classList.remove('d-none');
            gridPagination.classList.add('d-none');
            listPagination.classList.remove('d-none');
        }
    });

    // Screenshot modal
    const screenshotModal = document.getElementById('screenshotModal');
    const modalScreenshot = document.getElementById('modal-screenshot');

    screenshotModal.addEventListener('show.bs.modal', function(event) {
        const button = event.relatedTarget;
        const screenshotUrl = button.getAttribute('data-screenshot');

        // Show loading state
        modalScreenshot.src = '';
        modalScreenshot.alt = 'Loading...';

        // Set the actual image
        modalScreenshot.src = screenshotUrl;
        modalScreenshot.alt = 'Screenshot Preview';

        // Handle load errors
        modalScreenshot.onerror = function() {
            this.src = 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAwIiBoZWlnaHQ9IjMwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHJlY3Qgd2lkdGg9IjEwMCUiIGhlaWdodD0iMTAwJSIgZmlsbD0iI2Y4ZjlmYSIvPgo8dGV4dCB4PSI1MCUiIHk9IjUwJSIgZm9udC1mYW1pbHk9IkFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjE0IiBmaWxsPSIjNmM3NTdkIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBkeT0iLjNlbSI+SW1hZ2UgTm90IEZvdW5kPC90ZXh0Pgo8L3N2Zz4=';
            this.alt = 'Image Not Found';
        };
    });
});
</script>
@endsection
