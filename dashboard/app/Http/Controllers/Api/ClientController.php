<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Api\Traits\ClientValidation;
use App\Models\Client;
use App\Models\BrowserEvent;
use App\Models\ProcessEvent;
use App\Models\UrlEvent;
use App\Models\Screenshot;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class ClientController extends Controller
{
    use ClientValidation;
    public function register(Request $request): JsonResponse
    {
        try {
            $request->validate([
                'client_id' => 'required|string|max:255',
                'hostname' => 'required|string|max:255',
                'ip_address' => 'required|ip',
                'username' => 'required|string|max:255',
                'os_info' => 'required|array',
                'timezone' => 'string|max:100'
            ]);

            // Check if client already exists by client_id
            $existingClient = Client::where('client_id', $request->client_id)->first();

            if ($existingClient) {
                $existingClient->updateLastSeen();

                Log::info('Client registration - existing client', [
                    'client_id' => $existingClient->client_id,
                    'ip_address' => $request->ip_address,
                    'hostname' => $request->hostname
                ]);

                return response()->json([
                    'success' => true,
                    'client_id' => $existingClient->client_id,
                    'message' => 'Client already registered'
                ]);
            }

            // Create new client with provided client_id
            $client = Client::create([
                'client_id' => $request->client_id,
                'hostname' => $request->hostname,
                'ip_address' => $request->ip_address,
                'username' => $request->username,
                'os_info' => $request->os_info,
                'status' => 'active',
                'first_seen' => now(),  // Fixed: use first_seen instead of first_seen_at
                'last_seen' => now(),   // Fixed: use last_seen instead of last_seen_at
                'timezone' => $request->timezone ?? 'Asia/Jakarta'
            ]);

            Log::info('Client registration - new client created', [
                'client_id' => $client->client_id,
                'ip_address' => $client->ip_address,
                'hostname' => $client->hostname,
                'username' => $client->username
            ]);

            return response()->json([
                'success' => true,
                'client_id' => $client->client_id,
                'message' => 'Client registered successfully'
            ], 201);

        } catch (\Illuminate\Validation\ValidationException $e) {
            Log::warning('Client registration validation failed', [
                'errors' => $e->errors(),
                'input' => $request->except(['os_info'])  // Don't log full os_info for security
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $e->errors()
            ], 422);

        } catch (\Exception $e) {
            Log::error('Client registration failed', [
                'error' => $e->getMessage(),
                'client_id' => $request->client_id ?? 'unknown',
                'ip_address' => $request->ip_address ?? 'unknown',
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Registration failed: ' . $e->getMessage()
            ], 500);
        }
    }

    public function heartbeat(Request $request): JsonResponse
    {
        $request->validate([
            'client_id' => 'required|string',
            'status' => 'string|in:active,inactive'
        ]);

        $client = $this->validateAndGetClient($request);

        if ($this->clientValidationFailed($client)) {
            return $client; // Return the error response
        }

        $client->updateLastSeen();

        return response()->json([
            'success' => true,
            'message' => 'Heartbeat received'
        ]);
    }

    public function getSettings(Request $request, string $clientId): JsonResponse
    {
        $client = Client::where('client_id', $clientId)->first();

        if (!$client) {
            return response()->json([
                'success' => false,
                'message' => 'Client not found'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'settings' => [
                'screenshot_interval' => 60,
                'stream_quality' => 'medium',
                'upload_batch_size' => 10
            ]
        ]);
    }

    public function updateStatus(Request $request, string $clientId): JsonResponse
    {
        $request->validate([
            'status' => 'required|string|in:active,inactive,offline'
        ]);

        $client = Client::where('client_id', $clientId)->first();

        if (!$client) {
            return response()->json([
                'success' => false,
                'message' => 'Client not found'
            ], 404);
        }

        $client->update([
            'status' => $request->status,
            'last_seen' => now()
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Status updated'
        ]);
    }

    public function index(): JsonResponse
    {
        $clients = Client::with(['screenshots' => function($query) {
                $query->latest()->limit(1);
            }])
            ->orderBy('last_seen', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'clients' => $clients
        ]);
    }

    public function show(string $clientId): JsonResponse
    {
        $client = Client::with([
                'screenshots' => function($query) {
                    $query->latest()->limit(10);
                },
                'browserEvents' => function($query) {
                    $query->latest()->limit(20);
                },
                'urlEvents' => function($query) {
                    $query->latest()->limit(20);
                }
            ])
            ->where('client_id', $clientId)
            ->first();

        if (!$client) {
            return response()->json([
                'success' => false,
                'message' => 'Client not found'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'client' => $client
        ]);
    }

    public function getLatestScreenshot(string $clientId): JsonResponse
    {
        $client = Client::where('client_id', $clientId)->first();

        if (!$client) {
            return response()->json([
                'success' => false,
                'message' => 'Client not found'
            ], 404);
        }

        $latestScreenshot = $client->screenshots()
            ->orderBy('captured_at', 'desc')
            ->first();

        if (!$latestScreenshot) {
            return response()->json([
                'success' => false,
                'message' => 'No screenshots available'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'screenshot' => [
                'id' => $latestScreenshot->id,
                'url' => $latestScreenshot->hasValidFilePath() ? asset('storage/' . $latestScreenshot->file_path) : null,
                'resolution' => $latestScreenshot->resolution,
                'captured_at' => $latestScreenshot->captured_at,
                'file_size' => $latestScreenshot->file_size
            ]
        ]);
    }

    public function health(): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'API is healthy',
            'timestamp' => now()->toISOString()
        ]);
    }

    public function exportActivities(Request $request): JsonResponse
    {
        $from = $request->get('from', today()->subDays(7)->toDateString());
        $to = $request->get('to', today()->addDay()->toDateString());

        $query = Client::with([
            'browserEvents' => function($q) use ($from, $to) {
                $q->whereBetween('created_at', [$from, $to])
                  ->orderBy('created_at', 'desc');
            },
            'processEvents' => function($q) use ($from, $to) {
                $q->whereBetween('created_at', [$from, $to])
                  ->orderBy('created_at', 'desc');
            },
            'urlEvents' => function($q) use ($from, $to) {
                $q->whereBetween('created_at', [$from, $to])
                  ->orderBy('created_at', 'desc');
            },
            'screenshots' => function($q) use ($from, $to) {
                $q->whereBetween('captured_at', [$from, $to])
                  ->orderBy('captured_at', 'desc');
            }
        ]);

        if ($request->has('client_id') && $request->client_id) {
            $query->where('client_id', $request->client_id);
        }

        $clients = $query->get();

        $exportData = [
            'export_date' => now()->toISOString(),
            'date_range' => [
                'from' => $from,
                'to' => $to
            ],
            'total_clients' => $clients->count(),
            'summary' => [
                'browser_events' => $clients->sum(fn($c) => $c->browserEvents->count()),
                'process_events' => $clients->sum(fn($c) => $c->processEvents->count()),
                'url_events' => $clients->sum(fn($c) => $c->urlEvents->count()),
                'screenshots' => $clients->sum(fn($c) => $c->screenshots->count()),
            ],
            'clients' => $clients->map(function($client) {
                return [
                    'client_id' => $client->client_id,
                    'hostname' => $client->hostname,
                    'username' => $client->username,
                    'ip_address' => $client->ip_address,
                    'os_info' => $client->os_info,
                    'browser_events' => $client->browserEvents->map(function($event) {
                        return [
                            'id' => $event->id,
                            'event_type' => $event->event_type,
                            'browser_name' => $event->browser_name,
                            'url' => $event->url,
                            'title' => $event->title,
                            'created_at' => $event->created_at->toISOString()
                        ];
                    }),
                    'process_events' => $client->processEvents->map(function($event) {
                        return [
                            'id' => $event->id,
                            'event_type' => $event->event_type,
                            'process_name' => $event->process_name,
                            'process_pid' => $event->process_pid,
                            'created_at' => $event->created_at->toISOString()
                        ];
                    }),
                    'url_events' => $client->urlEvents->map(function($event) {
                        return [
                            'id' => $event->id,
                            'event_type' => $event->event_type,
                            'url' => $event->url,
                            'page_title' => $event->page_title,
                            'start_time' => $event->start_time,
                            'end_time' => $event->end_time,
                            'duration' => $event->duration,
                            'created_at' => $event->created_at->toISOString()
                        ];
                    }),
                    'screenshots' => $client->screenshots->map(function($screenshot) {
                        return [
                            'id' => $screenshot->id,
                            'filename' => $screenshot->filename,
                            'resolution' => $screenshot->resolution,
                            'file_size' => $screenshot->file_size,
                            'captured_at' => $screenshot->captured_at->toISOString()
                        ];
                    })
                ];
            })
        ];

        return response()->json($exportData)
            ->header('Content-Disposition', 'attachment; filename="tenjo-activities-' . date('Y-m-d') . '.json"');
    }
}
