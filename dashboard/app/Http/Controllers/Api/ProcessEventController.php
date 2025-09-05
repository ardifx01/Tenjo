<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Client;
use App\Models\ProcessEvent;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class ProcessEventController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'client_id' => 'required|string',
            'event_type' => 'required|string|in:process_started,process_ended',
            'process_name' => 'required|string',
            'process_pid' => 'required|integer',
            'timestamp' => 'required|date',
            'start_time' => 'date',
            'duration' => 'integer|min:0',
            'system_info' => 'array'
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
                'process_name' => $request->process_name,
                'process_pid' => $request->process_pid,
                'system_info' => $request->system_info
            ];

            if ($request->event_type === 'process_started') {
                $eventData['start_time'] = $request->timestamp;
            } elseif ($request->event_type === 'process_ended') {
                $eventData['end_time'] = $request->timestamp;

                if ($request->has('start_time')) {
                    $eventData['start_time'] = $request->start_time;
                }

                if ($request->has('duration')) {
                    $eventData['duration'] = $request->duration;
                }
            }

            $processEvent = ProcessEvent::create($eventData);

            // Update client last seen
            $client->updateLastSeen();

            return response()->json([
                'success' => true,
                'process_event_id' => $processEvent->id,
                'message' => 'Process event recorded successfully'
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to record process event: ' . $e->getMessage()
            ], 500);
        }
    }

    public function index(Request $request): JsonResponse
    {
        $query = ProcessEvent::with('client');

        // Filter by client
        if ($request->has('client_id')) {
            $client = Client::where('client_id', $request->client_id)->first();
            if ($client) {
                $query->where('client_id', $client->id);
            }
        }

        // Filter by process name
        if ($request->has('process_name')) {
            $query->where('process_name', 'like', '%' . $request->process_name . '%');
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

        $processEvents = $query->orderBy('start_time', 'desc')
            ->paginate($request->get('per_page', 20));

        return response()->json([
            'success' => true,
            'process_events' => $processEvents
        ]);
    }

    public function show(ProcessEvent $processEvent): JsonResponse
    {
        $processEvent->load('client');

        return response()->json([
            'success' => true,
            'process_event' => $processEvent
        ]);
    }
}
