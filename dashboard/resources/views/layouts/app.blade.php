<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('title', 'Tenjo Dashboard')</title>

    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">

    <!-- Font Awesome -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">

    <!-- Custom CSS -->
    <style>
        :root {
            --primary-blue: #2563eb;
            --light-blue: #3b82f6;
            --blue-50: #eff6ff;
            --blue-100: #dbeafe;
            --blue-500: #3b82f6;
            --blue-600: #2563eb;
            --blue-700: #1d4ed8;
            --success-color: #10b981;
            --warning-color: #f59e0b;
            --danger-color: #ef4444;
            --info-color: #3b82f6;
            --dark-text: #1f2937;
            --light-text: #6b7280;
            --border-color: #e5e7eb;
            --bg-light: #ffffff;
        }

        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            background-color: var(--bg-light);
            color: var(--dark-text);
        }

        /* Top Navigation */
        .top-navbar {
            background: linear-gradient(135deg, var(--primary-blue) 0%, var(--light-blue) 100%);
            box-shadow: 0 2px 10px rgba(37, 99, 235, 0.15);
            z-index: 1030;
        }

        .navbar-brand {
            font-weight: 700;
            font-size: 1.5rem;
            color: white !important;
        }

        .navbar-nav .nav-link {
            color: rgba(255, 255, 255, 0.9) !important;
            padding: 0.8rem 1.2rem !important;
            border-radius: 8px;
            margin: 0 0.2rem;
            transition: all 0.3s ease;
            font-weight: 500;
        }

        .navbar-nav .nav-link:hover {
            color: white !important;
            background-color: rgba(255, 255, 255, 0.15);
            transform: translateY(-1px);
        }

        .navbar-nav .nav-link.active {
            color: white !important;
            background-color: rgba(255, 255, 255, 0.2);
            box-shadow: 0 2px 8px rgba(255, 255, 255, 0.1);
        }

        .navbar-toggler {
            border: 2px solid rgba(255, 255, 255, 0.3);
            border-radius: 8px;
        }

        .navbar-toggler:focus {
            box-shadow: 0 0 0 0.25rem rgba(255, 255, 255, 0.25);
        }

        .client-card {
            border: none;
            border-radius: 16px;
            box-shadow: 0 2px 8px rgba(37, 99, 235, 0.08);
            transition: all 0.3s ease;
            background: white;
            border: 1px solid var(--blue-100);
        }

        .client-card:hover {
            transform: translateY(-4px);
            box-shadow: 0 8px 25px rgba(37, 99, 235, 0.15);
        }

        .status-badge {
            font-size: 0.75rem;
            padding: 6px 12px;
            border-radius: 20px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .status-online {
            background: linear-gradient(45deg, var(--success-color), #34d399);
            color: white;
        }

        .status-offline {
            background: linear-gradient(45deg, var(--danger-color), #f87171);
            color: white;
        }

        .status-idle {
            background: linear-gradient(45deg, var(--warning-color), #fbbf24);
            color: white;
        }

        .stats-card {
            background: linear-gradient(135deg, var(--primary-blue) 0%, var(--light-blue) 100%);
            border: none;
            border-radius: 20px;
            color: white;
            overflow: hidden;
            position: relative;
        }

        .stats-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: linear-gradient(45deg, rgba(255,255,255,0.1), transparent);
            pointer-events: none;
        }

        .stats-card .card-body {
            position: relative;
            z-index: 1;
        }

        .stats-number {
            font-size: 2.5rem;
            font-weight: 800;
            line-height: 1;
            text-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }

        .screenshot-thumbnail {
            width: 120px;
            height: 80px;
            object-fit: cover;
            border-radius: 12px;
            border: 2px solid #f1f5f9;
            transition: all 0.3s ease;
        }

        .screenshot-thumbnail:hover {
            border-color: var(--info-color);
            transform: scale(1.05);
        }

        .main-content {
            padding: 30px;
            background-color: var(--bg-light);
            margin-top: 80px; /* Space for fixed navbar */
        }

        .card {
            border: 1px solid var(--blue-100);
            border-radius: 16px;
            box-shadow: 0 2px 8px rgba(37, 99, 235, 0.08);
            background: white;
            transition: all 0.3s ease;
        }

        .card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 15px rgba(37, 99, 235, 0.12);
        }

        .card-header {
            background: linear-gradient(45deg, var(--blue-50), var(--blue-100));
            border-bottom: 1px solid var(--blue-100);
            border-radius: 16px 16px 0 0 !important;
            padding: 1.5rem;
            font-weight: 600;
            color: var(--primary-blue);
        }

        .card-body {
            color: var(--dark-text);
        }

        .card-body h6, .card-body h5, .card-body h4, .card-body h3 {
            color: var(--dark-text);
        }

        .table {
            border-radius: 12px;
            overflow: hidden;
        }

        .table thead th {
            background: linear-gradient(45deg, var(--blue-50), var(--blue-100));
            border-bottom: 2px solid var(--blue-200);
            font-weight: 600;
            text-transform: uppercase;
            font-size: 0.75rem;
            letter-spacing: 0.5px;
            padding: 1rem;
            color: var(--primary-blue);
        }

        .table tbody td {
            padding: 1rem;
            vertical-align: middle;
            border-bottom: 1px solid var(--blue-100);
            color: var(--dark-text);
        }

        .table tbody tr:hover {
            background: linear-gradient(45deg, var(--blue-50), #f8fafc);
        }

        /* Text color utilities */
        .text-dark {
            color: var(--dark-text) !important;
        }

        .text-blue {
            color: var(--primary-blue) !important;
        }

        .text-light-blue {
            color: var(--light-blue) !important;
        }

        .btn-primary {
            background: linear-gradient(135deg, var(--primary-blue) 0%, var(--light-blue) 100%);
            border: none;
            border-radius: 10px;
            padding: 10px 20px;
            font-weight: 600;
            transition: all 0.3s ease;
        }

        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(37, 99, 235, 0.4);
        }

        .btn-outline-primary {
            border: 2px solid var(--primary-blue);
            color: var(--primary-blue);
            border-radius: 10px;
            padding: 8px 16px;
            font-weight: 600;
            transition: all 0.3s ease;
        }

        .btn-outline-primary:hover {
            background: linear-gradient(135deg, var(--primary-blue) 0%, var(--light-blue) 100%);
            border-color: transparent;
            transform: translateY(-2px);
        }

        .alert {
            border: none;
            border-radius: 12px;
            padding: 1rem 1.25rem;
            margin-bottom: 1.5rem;
        }

        .alert-success {
            background: linear-gradient(45deg, #ecfdf5, #d1fae5);
            color: #065f46;
            border-left: 4px solid var(--success-color);
        }

        .alert-danger {
            background: linear-gradient(45deg, #fef2f2, #fecaca);
            color: #991b1b;
            border-left: 4px solid var(--danger-color);
        }

        .form-control, .form-select {
            border-radius: 10px;
            border: 2px solid var(--border-color);
            padding: 12px 16px;
            transition: all 0.3s ease;
        }

        .form-control:focus, .form-select:focus {
            border-color: var(--primary-blue);
            box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
        }

        .page-title {
            color: var(--primary-blue);
            font-weight: 700;
            margin-bottom: 0.5rem;
        }

        .text-muted {
            color: var(--light-text) !important;
        }

        .stats-icon {
            width: 60px;
            height: 60px;
            border-radius: 16px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.5rem;
        }

        .bg-primary {
            background: linear-gradient(135deg, var(--primary-blue) 0%, var(--light-blue) 100%) !important;
        }

        .bg-success {
            background: linear-gradient(135deg, var(--success-color), #34d399) !important;
        }

        .bg-warning {
            background: linear-gradient(135deg, var(--warning-color), #fbbf24) !important;
        }

        .bg-info {
            background: linear-gradient(135deg, var(--info-color), #60a5fa) !important;
        }

        /* Animations */
        .fade-in {
            animation: fadeIn 0.6s ease-out;
        }

        @keyframes fadeIn {
            from {
                opacity: 0;
                transform: translateY(30px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        /* Responsive adjustments */
        @media (max-width: 768px) {
            .main-content {
                padding: 20px 15px;
                margin-top: 70px;
            }

            .stats-number {
                font-size: 2rem;
            }

            .navbar-nav {
                background: rgba(255, 255, 255, 0.1);
                border-radius: 8px;
                margin-top: 0.5rem;
                padding: 0.5rem;
            }
        }

        @media (max-width: 576px) {
            .main-content {
                padding: 15px 10px;
            }

            .page-title {
                font-size: 1.5rem;
            }
        }
    </style>

    @yield('styles')
</head>
<body>
    <!-- Top Navigation -->
    <nav class="navbar navbar-expand-lg navbar-dark top-navbar fixed-top">
        <div class="container-fluid">
            <a class="navbar-brand" href="{{ route('dashboard') }}">
                <i class="fas fa-shield-alt me-2"></i>Tenjo
            </a>

            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>

            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav me-auto">
                    <li class="nav-item">
                        <a class="nav-link {{ request()->routeIs('dashboard') ? 'active' : '' }}" href="{{ route('dashboard') }}">
                            <i class="fas fa-tachometer-alt me-2"></i>Dashboard
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link {{ request()->routeIs('history.activity') ? 'active' : '' }}" href="{{ route('history.activity') }}">
                            <i class="fas fa-history me-2"></i>History Activity
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link {{ request()->routeIs('screenshots') ? 'active' : '' }}" href="{{ route('screenshots') }}">
                            <i class="fas fa-camera me-2"></i>Screenshots
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link {{ request()->routeIs('browser.activity') ? 'active' : '' }}" href="{{ route('browser.activity') }}">
                            <i class="fas fa-globe me-2"></i>Browser Activity
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link {{ request()->routeIs('url.activity') ? 'active' : '' }}" href="{{ route('url.activity') }}">
                            <i class="fas fa-link me-2"></i>URL Activity
                        </a>
                    </li>
                </ul>
            </div>
        </div>
    </nav>

    <!-- Main Content -->
    <div class="container-fluid">
        <main class="main-content">
            @yield('breadcrumb')

            @if(session('success'))
                <div class="alert alert-success alert-dismissible fade show" role="alert">
                    {{ session('success') }}
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
            @endif

            @if(session('error'))
                <div class="alert alert-danger alert-dismissible fade show" role="alert">
                    {{ session('error') }}
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
            @endif

            @yield('content')
        </main>
    </div>

    <!-- Bootstrap JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>

    <!-- Chart.js for charts -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

    @yield('scripts')
</body>
</html>
