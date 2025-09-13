<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Api\Traits\ClientValidation;
use App\Models\Client;
use App\Models\ProcessEvent;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class ProcessEventController extends Controller
{
    use ClientValidation;

    public function store(Request $request): JsonResponse
    {
        $validationRules = array_merge($this->getCommonEventValidationRules(), [
            'event_type' => 'required|string|in:process_started,process_ended',
            'process_name' => 'required|string',
            'process_pid' => 'required|integer',
            'system_info' => 'array'
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

        // Apply common filters (client_id, event_type, date range)
        $query = $this->applyCommonFilters($query, $request);

        // Filter by process name (specific to process events)
        if ($request->has('process_name')) {
            $query->where('process_name', 'like', '%' . $request->process_name . '%');
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
