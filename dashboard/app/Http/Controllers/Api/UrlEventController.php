<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Client;
use App\Models\UrlEvent;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class UrlEventController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'client_id' => 'required|string',
            'event_type' => 'required|string|in:url_opened,url_closed',
            'url' => 'required|string',
            'timestamp' => 'required|date',
            'start_time' => 'date',
            'duration' => 'integer|min:0',
            'page_title' => 'string|max:500'
        ]);

        $client = Client::where('client_id', $request->client_id)->first();

        if (!$client) {
            return response()->json([
                'success' => false,
                'message' => 'Client not found'
            ], 404);
        }

        try {
            $eventData = [
                'client_id' => $client->id,
                'event_type' => $request->event_type,
                'url' => $request->url,
                'page_title' => $request->page_title
            ];

            if ($request->event_type === 'url_opened') {
                $eventData['start_time'] = $request->timestamp;
            } elseif ($request->event_type === 'url_closed') {
                $eventData['end_time'] = $request->timestamp;

                if ($request->has('start_time')) {
                    $eventData['start_time'] = $request->start_time;
                }

                if ($request->has('duration')) {
                    $eventData['duration'] = $request->duration;
                }
            }

            $urlEvent = UrlEvent::create($eventData);

            // Update client last seen
            $client->updateLastSeen();

            return response()->json([
                'success' => true,
                'url_event_id' => $urlEvent->id,
                'message' => 'URL event recorded successfully'
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to record URL event: ' . $e->getMessage()
            ], 500);
        }
    }

    public function index(Request $request): JsonResponse
    {
        $query = UrlEvent::with('client');

        // Filter by client
        if ($request->has('client_id')) {
            $client = Client::where('client_id', $request->client_id)->first();
            if ($client) {
                $query->where('client_id', $client->id);
            }
        }

        // Filter by URL/domain
        if ($request->has('url')) {
            $query->where('url', 'like', '%' . $request->url . '%');
        }

        // Filter by event type
        if ($request->has('event_type')) {
            $query->where('event_type', $request->event_type);
        }

        // Filter by date range
        if ($request->has('from')) {
            $query->where('start_time', '>=', $request->from);
        }

        if ($request->has('to')) {
            $query->where('start_time', '<=', $request->to);
        }

        $urlEvents = $query->orderBy('start_time', 'desc')
            ->paginate($request->get('per_page', 20));

        return response()->json([
            'success' => true,
            'url_events' => $urlEvents
        ]);
    }

    public function show(UrlEvent $urlEvent): JsonResponse
    {
        $urlEvent->load('client');

        return response()->json([
            'success' => true,
            'url_event' => $urlEvent
        ]);
    }
}
