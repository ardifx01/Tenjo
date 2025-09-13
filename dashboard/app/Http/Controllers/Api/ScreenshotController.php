<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Controllers\Api\Traits\ClientValidation;
use App\Models\Client;
use App\Models\Screenshot;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class ScreenshotController extends Controller
{
    use ClientValidation;

    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'client_id' => 'required|string',
            'image_data' => 'required|string',
            'resolution' => 'required|string',
            'monitor' => 'integer|min:1',
            'timestamp' => 'required|date'
        ]);

        $client = $this->validateAndGetClient($request);

        if ($this->clientValidationFailed($client)) {
            return $client; // Return the error response
        }

        try {
            // Clean and decode base64 image
            $imageDataRaw = $request->image_data;

            // Remove data URL prefix if present (data:image/jpeg;base64,)
            if (strpos($imageDataRaw, ',') !== false) {
                $imageDataRaw = explode(',', $imageDataRaw)[1];
            }

            // Clean any whitespace
            $imageDataRaw = trim($imageDataRaw);

            // Validate base64
            if (!base64_decode($imageDataRaw, true)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid base64 image data'
                ], 400);
            }

            $imageData = base64_decode($imageDataRaw);

            if (!$imageData || strlen($imageData) < 100) {
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid or corrupted image data'
                ], 400);
            }

            // Validate image format by checking header
            $imageType = $this->getImageType($imageData);
            if (!$imageType) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unsupported image format'
                ], 400);
            }

            // Generate filename with proper extension
            $filename = sprintf(
                '%s_%s_%d.%s',
                $client->client_id,
                date('Y-m-d_H-i-s', strtotime($request->timestamp)),
                $request->monitor ?? 1,
                $imageType
            );

            // Ensure screenshots directory exists
            $directory = 'screenshots';
            if (!Storage::disk('public')->exists($directory)) {
                Storage::disk('public')->makeDirectory($directory);
            }

            // Store image
            $path = $directory . '/' . $filename;
            $stored = Storage::disk('public')->put($path, $imageData);

            if (!$stored) {
                return response()->json([
                    'success' => false,
                    'message' => 'Failed to store image file'
                ], 500);
            }

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
                'file_size' => strlen($imageData),
                'file_path' => $path,
                'message' => 'Screenshot uploaded successfully'
            ], 201);

        } catch (\Exception $e) {
            Log::error('Screenshot upload failed', [
                'client_id' => $request->client_id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to upload screenshot: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Detect image type from binary data
     */
    private function getImageType($imageData): ?string
    {
        $header = substr($imageData, 0, 12);

        // JPEG
        if (substr($header, 0, 3) === "\xFF\xD8\xFF") {
            return 'jpg';
        }

        // PNG
        if (substr($header, 0, 8) === "\x89\x50\x4E\x47\x0D\x0A\x1A\x0A") {
            return 'png';
        }

        // GIF
        if (substr($header, 0, 6) === "GIF87a" || substr($header, 0, 6) === "GIF89a") {
            return 'gif';
        }

        // WebP
        if (substr($header, 0, 4) === "RIFF" && substr($header, 8, 4) === "WEBP") {
            return 'webp';
        }

        // BMP
        if (substr($header, 0, 2) === "BM") {
            return 'bmp';
        }

        return null;
    }

    public function upload(Request $request): JsonResponse
    {
        $request->validate([
            'file' => 'required|image|max:10240', // Max 10MB
            'client_id' => 'required|string',
            'resolution' => 'string',
            'monitor' => 'integer|min:1'
        ]);

        $client = $this->validateAndGetClient($request);

        if ($this->clientValidationFailed($client)) {
            return $client; // Return the error response
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

        // Apply client filtering similar to other controllers
        if ($request->has('client_id')) {
            $client = Client::where('client_id', $request->client_id)->first();
            if ($client) {
                $query->where('client_id', $client->id);
            }
        }

        // Filter by date range (using captured_at instead of start_time)
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
