<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Api\Traits\ClientValidation;
use App\Models\Client;
use App\Models\UrlEvent;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class UrlEventController extends Controller
{
    use ClientValidation;

    public function store(Request $request): JsonResponse
    {
        $validationRules = array_merge($this->getCommonEventValidationRules(), [
            'event_type' => 'required|string|in:url_opened,url_closed',
            'url' => 'required|string',
            'page_title' => 'string|max:500'
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

        // Apply common filters (client_id, event_type, date range)
        $query = $this->applyCommonFilters($query, $request);

        // Filter by URL/domain (specific to URL events)
        if ($request->has('url')) {
            $query->where('url', 'like', '%' . $request->url . '%');
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
