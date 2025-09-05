<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Client;
use App\Models\Screenshot;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class ScreenshotController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'client_id' => 'required|string',
            'image_data' => 'required|string',
            'resolution' => 'required|string',
            'monitor' => 'integer|min:1',
            'timestamp' => 'required|date'
        ]);

        $client = Client::where('client_id', $request->client_id)->first();

        if (!$client) {
            return response()->json([
                'success' => false,
                'message' => 'Client not found'
            ], 404);
        }

        try {
            // Decode base64 image
            $imageData = base64_decode($request->image_data);

            if (!$imageData) {
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid image data'
                ], 400);
            }

            // Generate filename
            $filename = sprintf(
                '%s_%s_%d.jpg',
                $client->client_id,
                date('Y-m-d_H-i-s', strtotime($request->timestamp)),
                $request->monitor ?? 1
            );

            // Store image
            $path = 'screenshots/' . $filename;
            Storage::disk('public')->put($path, $imageData);

            // Create screenshot record
            $screenshot = Screenshot::create([
                'client_id' => $client->id,
                'filename' => $filename,
                'file_path' => $path,
                'resolution' => $request->resolution,
                'monitor' => $request->monitor ?? 1,
                'file_size' => strlen($imageData),
                'captured_at' => $request->timestamp
            ]);

            // Update client last seen
            $client->updateLastSeen();

            return response()->json([
                'success' => true,
                'screenshot_id' => $screenshot->id,
                'message' => 'Screenshot uploaded successfully'
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to upload screenshot: ' . $e->getMessage()
            ], 500);
        }
    }

    public function upload(Request $request): JsonResponse
    {
        $request->validate([
            'file' => 'required|image|max:10240', // Max 10MB
            'client_id' => 'required|string',
            'resolution' => 'string',
            'monitor' => 'integer|min:1'
        ]);

        $client = Client::where('client_id', $request->client_id)->first();

        if (!$client) {
            return response()->json([
                'success' => false,
                'message' => 'Client not found'
            ], 404);
        }

        try {
            $file = $request->file('file');

            // Generate filename
            $filename = sprintf(
                '%s_%s_%d.%s',
                $client->client_id,
                now()->format('Y-m-d_H-i-s'),
                $request->monitor ?? 1,
                $file->getClientOriginalExtension()
            );

            // Store file
            $path = $file->storeAs('screenshots', $filename, 'public');

            // Create screenshot record
            $screenshot = Screenshot::create([
                'client_id' => $client->id,
                'filename' => $filename,
                'file_path' => $path,
                'resolution' => $request->resolution ?? 'unknown',
                'monitor' => $request->monitor ?? 1,
                'file_size' => $file->getSize(),
                'captured_at' => now()
            ]);

            // Update client last seen
            $client->updateLastSeen();

            return response()->json([
                'success' => true,
                'screenshot_id' => $screenshot->id,
                'url' => Storage::url($path),
                'message' => 'Screenshot uploaded successfully'
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to upload screenshot: ' . $e->getMessage()
            ], 500);
        }
    }

    public function index(Request $request): JsonResponse
    {
        $query = Screenshot::with('client');

        // Filter by client
        if ($request->has('client_id')) {
            $client = Client::where('client_id', $request->client_id)->first();
            if ($client) {
                $query->where('client_id', $client->id);
            }
        }

        // Filter by date range
        if ($request->has('from')) {
            $query->where('captured_at', '>=', $request->from);
        }

        if ($request->has('to')) {
            $query->where('captured_at', '<=', $request->to);
        }

        $screenshots = $query->orderBy('captured_at', 'desc')
            ->paginate($request->get('per_page', 20));

        return response()->json([
            'success' => true,
            'screenshots' => $screenshots
        ]);
    }

    public function show(Screenshot $screenshot): JsonResponse
    {
        $screenshot->load('client');

        return response()->json([
            'success' => true,
            'screenshot' => $screenshot
        ]);
    }

    public function destroy(Screenshot $screenshot): JsonResponse
    {
        try {
            // Delete file from storage if file_path exists
            if ($screenshot->hasValidFilePath()) {
                Storage::disk('public')->delete($screenshot->file_path);
            }

            // Delete record
            $screenshot->delete();

            return response()->json([
                'success' => true,
                'message' => 'Screenshot deleted successfully'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete screenshot: ' . $e->getMessage()
            ], 500);
        }
    }
}
