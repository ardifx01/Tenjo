<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Client;
use App\Models\BrowserEvent;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class BrowserEventController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'client_id' => 'required|string',
            'event_type' => 'required|string|in:browser_started,browser_closed,page_visit,tab_opened,tab_closed',
            'browser_name' => 'required|string',
            'timestamp' => 'required|date',
            'url' => 'string|nullable',
            'title' => 'string|nullable',
            'start_time' => 'date',
            'duration' => 'integer|min:0'
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
                'browser_name' => $request->browser_name,
            ];

            // Handle different event types
            if ($request->event_type === 'browser_started') {
                $eventData['start_time'] = $request->timestamp;
            } elseif ($request->event_type === 'browser_closed') {
                $eventData['end_time'] = $request->timestamp;

                if ($request->has('start_time')) {
                    $eventData['start_time'] = $request->start_time;
                }

                if ($request->has('duration')) {
                    $eventData['duration'] = $request->duration;
                }
            } elseif (in_array($request->event_type, ['page_visit', 'tab_opened', 'tab_closed'])) {
                // For page visits and tab events, use created_at timestamp
                $eventData['created_at'] = $request->timestamp;

                if ($request->has('url')) {
                    $eventData['url'] = $request->url;
                }

                if ($request->has('title')) {
                    $eventData['title'] = $request->title;
                }
            }

            $browserEvent = BrowserEvent::create($eventData);

            // Update client last seen
            $client->updateLastSeen();

            return response()->json([
                'success' => true,
                'browser_event_id' => $browserEvent->id,
                'message' => 'Browser event recorded successfully'
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to record browser event: ' . $e->getMessage()
            ], 500);
        }
    }

    public function index(Request $request): JsonResponse
    {
        $query = BrowserEvent::with('client');

        // Filter by client
        if ($request->has('client_id')) {
            $client = Client::where('client_id', $request->client_id)->first();
            if ($client) {
                $query->where('client_id', $client->id);
            }
        }

        // Filter by browser name
        if ($request->has('browser_name')) {
            $query->where('browser_name', 'like', '%' . $request->browser_name . '%');
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

        $browserEvents = $query->orderBy('start_time', 'desc')
            ->paginate($request->get('per_page', 20));

        return response()->json([
            'success' => true,
            'browser_events' => $browserEvents
        ]);
    }

    public function show(BrowserEvent $browserEvent): JsonResponse
    {
        $browserEvent->load('client');

        return response()->json([
            'success' => true,
            'browser_event' => $browserEvent
        ]);
    }
}
