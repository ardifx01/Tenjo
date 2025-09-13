<?php

namespace App\Http\Controllers;

use App\Models\Client;
use App\Models\Screenshot;
use App\Models\BrowserEvent;
use App\Models\ProcessEvent;
use App\Models\UrlEvent;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\View\View;
use Carbon\Carbon;

class DashboardController extends Controller
{
    public function index(): View
    {
        $clients = Client::with(['screenshots' => function($query) {
                $query->latest()->limit(1);
            }])
            ->orderBy('last_seen', 'desc')
            ->get();

        $stats = [
            'total_clients' => Client::count(),
            'active_clients' => Client::whereDate('last_seen', today())->count(),
            'online_clients' => $clients->filter(fn($client) => $client->isOnline())->count(),
            'total_screenshots' => Screenshot::whereDate('created_at', today())->count(),
        ];

        return view('dashboard.index', compact('clients', 'stats'));
    }

    public function clientDetails(string $clientId): View
    {
        $client = Client::where('client_id', $clientId)
            ->with([
                'screenshots' => function($query) {
                    $query->whereDate('captured_at', today())
                          ->orderBy('captured_at', 'desc');
                },
                'browserEvents' => function($query) {
                    $query->whereDate('created_at', today())
                          ->orderBy('start_time', 'desc');
                },
                'urlEvents' => function($query) {
                    $query->whereDate('created_at', today())
                          ->orderBy('start_time', 'desc');
                },
                'processEvents' => function($query) {
                    $query->whereDate('created_at', today())
                          ->orderBy('start_time', 'desc')
                          ->limit(50);
                }
            ])
            ->firstOrFail();

        // Browser usage statistics
        $browserStats = BrowserEvent::where('client_id', $client->id)
            ->whereDate('created_at', today())
            ->selectRaw('browser_name, SUM(duration) as total_duration, COUNT(*) as sessions')
            ->groupBy('browser_name')
            ->get();

        // Top URLs accessed today
        $topUrls = UrlEvent::where('client_id', $client->id)
            ->whereDate('created_at', today())
            ->selectRaw('url, SUM(duration) as total_duration, COUNT(*) as visits')
            ->groupBy('url')
            ->orderBy('total_duration', 'desc')
            ->limit(10)
            ->get();

        return view('dashboard.client-details', compact('client', 'browserStats', 'topUrls'));
    }

    public function clientLive(string $clientId): View
    {
        $client = Client::where('client_id', $clientId)->firstOrFail();

        return view('dashboard.client-live', compact('client'));
    }

    public function historyActivity(Request $request): View
    {
        // Apply filters
        $from = $request->get('from', today()->subDays(7)->toDateString());
        $to = $request->get('to', today()->addDay()->toDateString()); // Include today

        $query = Client::with([
            'browserEvents' => function($q) use ($from, $to) {
                $q->whereBetween('created_at', [$from, $to])
                  ->orderBy('created_at', 'desc')
                  ->limit(10);
            },
            'processEvents' => function($q) use ($from, $to) {
                $q->whereBetween('created_at', [$from, $to])
                  ->orderBy('created_at', 'desc')
                  ->limit(10);
            },
            'urlEvents' => function($q) use ($from, $to) {
                $q->whereBetween('created_at', [$from, $to])
                  ->orderBy('created_at', 'desc')
                  ->limit(10);
            }
        ]);

        // Client filter
        if ($request->has('client_id') && $request->client_id) {
            $query->where('client_id', $request->client_id);
        }

        $clients = $query->get();

        // Activity summary
        $activitySummary = [
            'browser_events' => BrowserEvent::whereBetween('created_at', [$from, $to])->count(),
            'process_events' => ProcessEvent::whereBetween('created_at', [$from, $to])->count(),
            'url_events' => UrlEvent::whereBetween('created_at', [$from, $to])->count(),
            'screenshots' => Screenshot::whereBetween('captured_at', [$from, $to])->count(),
        ];

        return view('dashboard.history-activity', compact('clients', 'activitySummary', 'from', 'to'));
    }

    public function screenshots(Request $request): View
    {
        $query = Screenshot::with('client');

        // Client filter
        if ($request->has('client_id')) {
            $client = Client::where('client_id', $request->client_id)->first();
            if ($client) {
                $query->where('client_id', $client->id);
            }
        }

        // Date filter
        if ($request->has('date')) {
            $query->whereDate('captured_at', $request->date);
        } else {
            $query->whereDate('captured_at', today());
        }

        $screenshots = $query->orderBy('captured_at', 'desc')->paginate(20);
        $clients = Client::orderBy('hostname')->get();

        return view('dashboard.screenshots', compact('screenshots', 'clients'));
    }

    public function browserActivity(Request $request): View
    {
        $query = BrowserEvent::with('client');

        // Client filter
        if ($request->has('client_id') && $request->client_id) {
            $client = Client::where('client_id', $request->client_id)->first();
            if ($client) {
                $query->where('client_id', $client->id);
            }
        }

        // Date range filter
        $dateRange = $request->get('date_range', 'today');
        switch ($dateRange) {
            case 'yesterday':
                $query->whereDate('created_at', today()->subDay());
                break;
            case 'week':
                $query->whereBetween('created_at', [today()->startOfWeek(), today()->endOfWeek()]);
                break;
            case 'month':
                $query->whereMonth('created_at', today()->month)
                      ->whereYear('created_at', today()->year);
                break;
            default: // today
                $query->whereDate('created_at', today());
        }

        // Browser filter
        if ($request->has('browser') && $request->browser) {
            $query->where('browser_name', 'LIKE', '%' . ucfirst($request->browser) . '%');
        }

        // Get browser events
        $browserEvents = $query->orderBy('created_at', 'desc')->paginate(20);

        // Generate statistics
        $statsQuery = BrowserEvent::query();

        // Apply same filters for stats
        if ($request->has('client_id') && $request->client_id) {
            $client = Client::where('client_id', $request->client_id)->first();
            if ($client) {
                $statsQuery->where('client_id', $client->id);
            }
        }

        switch ($dateRange) {
            case 'yesterday':
                $statsQuery->whereDate('created_at', today()->subDay());
                break;
            case 'week':
                $statsQuery->whereBetween('created_at', [today()->startOfWeek(), today()->endOfWeek()]);
                break;
            case 'month':
                $statsQuery->whereMonth('created_at', today()->month)
                          ->whereYear('created_at', today()->year);
                break;
            default:
                $statsQuery->whereDate('created_at', today());
        }

        if ($request->has('browser') && $request->browser) {
            $statsQuery->where('browser_name', 'LIKE', '%' . ucfirst($request->browser) . '%');
        }

        $stats = [
            'total_events' => $statsQuery->count(),
            'unique_urls' => $statsQuery->whereNotNull('url')->distinct('url')->count('url'),
            'avg_session_time' => 0, // Simplified for now since we don't have duration field in our schema
            'active_clients' => $statsQuery->distinct('client_id')->count('client_id'),
        ];

        // Top domains
        $topDomains = $statsQuery->whereNotNull('url')
            ->get()
            ->groupBy(function($item) {
                $url = parse_url($item->url, PHP_URL_HOST);
                return $url ? str_replace('www.', '', $url) : 'unknown';
            })
            ->map(function($group, $domain) {
                return [
                    'domain' => $domain,
                    'visits' => $group->count()
                ];
            })
            ->sortByDesc('visits')
            ->take(5)
            ->values();

        // Browser stats
        $browserStats = $statsQuery->whereNotNull('browser_name')
            ->get()
            ->groupBy('browser_name')
            ->map(function($group, $browser) use ($stats) {
                return [
                    'browser' => $browser,
                    'usage' => $stats['total_events'] > 0 ? round(($group->count() / $stats['total_events']) * 100, 1) : 0
                ];
            })
            ->sortByDesc('usage')
            ->take(5)
            ->values();

        $clients = Client::orderBy('hostname')->get();

        return view('dashboard.browser-activity', compact(
            'browserEvents',
            'clients',
            'stats',
            'topDomains',
            'browserStats'
        ));
    }

    public function urlActivity(Request $request): View
    {
        $query = UrlEvent::with('client');

        // Client filter
        if ($request->has('client_id') && $request->client_id) {
            $client = Client::where('client_id', $request->client_id)->first();
            if ($client) {
                $query->where('client_id', $client->id);
            }
        }

        // Date range filter
        $dateRange = $request->get('date_range', 'today');
        switch ($dateRange) {
            case 'yesterday':
                $query->whereDate('created_at', today()->subDay());
                break;
            case 'week':
                $query->whereBetween('created_at', [today()->startOfWeek(), today()->endOfWeek()]);
                break;
            case 'month':
                $query->whereMonth('created_at', today()->month)
                      ->whereYear('created_at', today()->year);
                break;
            default:
                $query->whereDate('created_at', today());
        }

        // URL search filter
        if ($request->has('search') && $request->search) {
            $query->where('url', 'LIKE', '%' . $request->search . '%')
                  ->orWhere('page_title', 'LIKE', '%' . $request->search . '%');
        }

        // Event type filter
        if ($request->has('event_type') && $request->event_type) {
            $query->where('event_type', $request->event_type);
        }

        $urlEvents = $query->orderBy('start_time', 'desc')->paginate(20);
        $clients = Client::orderBy('hostname')->get();

        // Generate statistics
        $statsQuery = UrlEvent::query();

        // Apply same filters for stats
        if ($request->has('client_id') && $request->client_id) {
            $client = Client::where('client_id', $request->client_id)->first();
            if ($client) {
                $statsQuery->where('client_id', $client->id);
            }
        }

        switch ($dateRange) {
            case 'yesterday':
                $statsQuery->whereDate('created_at', today()->subDay());
                break;
            case 'week':
                $statsQuery->whereBetween('created_at', [today()->startOfWeek(), today()->endOfWeek()]);
                break;
            case 'month':
                $statsQuery->whereMonth('created_at', today()->month)
                          ->whereYear('created_at', today()->year);
                break;
            default:
                $statsQuery->whereDate('created_at', today());
        }

        if ($request->has('search') && $request->search) {
            $statsQuery->where('url', 'LIKE', '%' . $request->search . '%')
                      ->orWhere('page_title', 'LIKE', '%' . $request->search . '%');
        }

        if ($request->has('event_type') && $request->event_type) {
            $statsQuery->where('event_type', $request->event_type);
        }

        // Calculate stats separately to avoid query conflicts
        $totalEvents = $statsQuery->count();

        // Create fresh query for unique URLs count
        $uniqueUrlsQuery = UrlEvent::whereDate('created_at', today());
        if ($request->has('client_id') && $request->client_id) {
            $uniqueUrlsQuery->where('client_id', $request->client_id);
        }
        if ($request->has('event_type') && $request->event_type) {
            $uniqueUrlsQuery->where('event_type', $request->event_type);
        }
        $uniqueUrls = $uniqueUrlsQuery->distinct('url')->count();

        // Create fresh query for average duration
        $avgDurationQuery = UrlEvent::whereDate('created_at', today())
            ->whereNotNull('duration');
        if ($request->has('client_id') && $request->client_id) {
            $avgDurationQuery->where('client_id', $request->client_id);
        }
        if ($request->has('event_type') && $request->event_type) {
            $avgDurationQuery->where('event_type', $request->event_type);
        }
        $avgDuration = round($avgDurationQuery->avg('duration') / 60, 1) ?? 0;

        // Create fresh query for active clients
        $activeClientsQuery = UrlEvent::whereDate('created_at', today());
        if ($request->has('client_id') && $request->client_id) {
            $activeClientsQuery->where('client_id', $request->client_id);
        }
        if ($request->has('event_type') && $request->event_type) {
            $activeClientsQuery->where('event_type', $request->event_type);
        }
        $activeClients = $activeClientsQuery->distinct('client_id')->count();

        $stats = [
            'total_events' => $totalEvents,
            'unique_urls' => $uniqueUrls,
            'avg_duration' => $avgDuration,
            'active_clients' => $activeClients,
        ];

        // Top URLs
        $topUrls = $statsQuery->get()
            ->groupBy('url')
            ->map(function($group, $url) {
                return [
                    'url' => $url,
                    'title' => $group->first()->page_title ?? 'No title',
                    'visits' => $group->count(),
                    'total_duration' => round($group->sum('duration') / 60, 1) // in minutes
                ];
            })
            ->sortByDesc('visits')
            ->take(10)
            ->values();

        // Top domains
        $topDomains = $statsQuery->get()
            ->groupBy(function($item) {
                $url = parse_url($item->url, PHP_URL_HOST);
                return $url ? str_replace('www.', '', $url) : 'unknown';
            })
            ->map(function($group, $domain) {
                return [
                    'domain' => $domain,
                    'visits' => $group->count(),
                    'duration' => round($group->sum('duration') / 60, 1) // in minutes
                ];
            })
            ->sortByDesc('visits')
            ->take(5)
            ->values();

        return view('dashboard.url-activity', compact(
            'urlEvents',
            'clients',
            'stats',
            'topUrls',
            'topDomains'
        ));
    }

    public function exportReport(Request $request)
    {
        // This would generate PDF report
        // For now, return JSON data that can be processed

        $from = $request->get('from', today()->subDays(7)->toDateString());
        $to = $request->get('to', today()->toDateString());

        $reportData = [
            'period' => ['from' => $from, 'to' => $to],
            'clients' => Client::count(),
            'screenshots' => Screenshot::whereBetween('captured_at', [$from, $to])->count(),
            'browser_sessions' => BrowserEvent::whereBetween('created_at', [$from, $to])->count(),
            'urls_visited' => UrlEvent::whereBetween('created_at', [$from, $to])->count(),
        ];

        return response()->json($reportData);
    }
}
