<?php

namespace App\Http\Controllers\Api\Traits;

use App\Models\Client;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

trait ClientValidation
{
    /**
     * Validate and get client by client_id
     *
     * @param Request $request
     * @return Client|JsonResponse
     */
    protected function validateAndGetClient(Request $request)
    {
        if (!$request->has('client_id')) {
            return response()->json([
                'success' => false,
                'message' => 'Client ID is required'
            ], 400);
        }

        $client = Client::where('client_id', $request->client_id)->first();

        if (!$client) {
            return response()->json([
                'success' => false,
                'message' => 'Client not found'
            ], 404);
        }

        return $client;
    }

    /**
     * Check if client validation failed (returns JsonResponse)
     *
     * @param mixed $clientOrResponse
     * @return bool
     */
    protected function clientValidationFailed($clientOrResponse): bool
    {
        return $clientOrResponse instanceof JsonResponse;
    }

    /**
     * Apply common filters to query
     *
     * @param \Illuminate\Database\Eloquent\Builder $query
     * @param Request $request
     * @param string $clientRelationColumn
     * @return \Illuminate\Database\Eloquent\Builder
     */
    protected function applyCommonFilters($query, Request $request, string $clientRelationColumn = 'client_id')
    {
        // Filter by client
        if ($request->has('client_id')) {
            $client = Client::where('client_id', $request->client_id)->first();
            if ($client) {
                $query->where($clientRelationColumn, $client->id);
            }
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

        return $query;
    }

    /**
     * Get common validation rules for events
     *
     * @return array
     */
    protected function getCommonEventValidationRules(): array
    {
        return [
            'client_id' => 'required|string',
            'event_type' => 'required|string',
            'timestamp' => 'required|date',
            'start_time' => 'date',
            'duration' => 'integer|min:0'
        ];
    }
}
