<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Api\Traits\ClientValidation;
use App\Models\Client;
use App\Models\BrowserEvent;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class BrowserEventController extends Controller
{
    use ClientValidation;

    public function store(Request $request): JsonResponse
    {
        $validationRules = array_merge($this->getCommonEventValidationRules(), [
            'event_type' => 'required|string|in:browser_started,browser_closed,page_visit,tab_opened,tab_closed',
            'browser_name' => 'required|string',
            'url' => 'string|nullable',
            'title' => 'string|nullable',
        ]);

        $request->validate($validationRules);

        $client = $this->validateAndGetClient($request);

        if ($this->clientValidationFailed($client)) {
            return $client; // Return the error response
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

        // Apply common filters (client_id, event_type, date range)
        $query = $this->applyCommonFilters($query, $request);

        // Filter by browser name (specific to browser events)
        if ($request->has('browser_name')) {
            $query->where('browser_name', 'like', '%' . $request->browser_name . '%');
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
