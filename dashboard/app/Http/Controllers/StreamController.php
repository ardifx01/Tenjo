<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Client;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class StreamController extends Controller
{
    protected static $streamConnections = [];

    public function startStream(Request $request, $clientId)
    {
        $quality = $request->input('quality', 'medium');

        $client = Client::where('client_id', $clientId)->first();
        if (!$client) {
            return response()->json(['error' => 'Client not found'], 404);
        }

        // Store stream request in cache/database
        cache()->put("stream_request_{$clientId}", [
            'quality' => $quality,
            'timestamp' => now()
        ], 300); // 5 minutes

        return response()->json(['success' => true, 'message' => 'Stream started']);
    }

    public function stopStream(Request $request, $clientId)
    {
        // Remove stream request
        cache()->forget("stream_request_{$clientId}");

        return response()->json(['success' => true, 'message' => 'Stream stopped']);
    }

    public function getStreamRequest($clientId)
    {
        $streamRequest = cache()->get("stream_request_{$clientId}");

        if ($streamRequest) {
            return response()->json($streamRequest);
        }

        return response()->json(['streaming' => false]);
    }

    public function getStreamStatus($clientId)
    {
        $streamRequest = cache()->get("stream_request_{$clientId}");

        return response()->json([
            'should_stream' => $streamRequest ? true : false,
            'quality' => $streamRequest['quality'] ?? 'medium',
            'timestamp' => $streamRequest['timestamp'] ?? null
        ]);
    }

    public function uploadVideoChunk(Request $request, $clientId)
    {
        try {
            $videoChunk = $request->input('video_chunk');
            $sequence = $request->input('sequence', 0);
            $quality = $request->input('quality', 'medium');
            $streamType = $request->input('stream_type', 'video');

            if (!$videoChunk) {
                return response()->json(['error' => 'No video chunk provided'], 400);
            }

            // Store video chunk temporarily (for live streaming)
            $chunkKey = "video_chunk_{$clientId}_{$sequence}";
            cache()->put($chunkKey, [
                'video_chunk' => $videoChunk,
                'sequence' => $sequence,
                'quality' => $quality,
                'timestamp' => now(),
                'stream_type' => $streamType
            ], 30); // Keep for 30 seconds

            // Store latest video chunk for dashboard
            cache()->put("latest_video_{$clientId}", [
                'video_chunk' => $videoChunk,
                'sequence' => $sequence,
                'quality' => $quality,
                'timestamp' => now(),
                'stream_type' => $streamType
            ], 60);

            Log::info("Video chunk received from client {$clientId}, sequence: {$sequence}");

            return response()->json(['success' => true]);

        } catch (\Exception $e) {
            Log::error("Error uploading video chunk: " . $e->getMessage());
            return response()->json(['error' => 'Failed to upload video chunk'], 500);
        }
    }

    public function uploadScreenshotChunk(Request $request, $clientId)
    {
        try {
            $screenshot = $request->input('screenshot');
            $sequence = $request->input('sequence', 0);
            $quality = $request->input('quality', 'medium');
            $streamType = $request->input('stream_type', 'screenshot');

            if (!$screenshot) {
                return response()->json(['error' => 'No screenshot provided'], 400);
            }

            // Store screenshot chunk
            $chunkKey = "screenshot_chunk_{$clientId}_{$sequence}";
            cache()->put($chunkKey, [
                'screenshot' => $screenshot,
                'sequence' => $sequence,
                'quality' => $quality,
                'timestamp' => now(),
                'stream_type' => $streamType
            ], 30);

            // Store latest screenshot for dashboard
            cache()->put("latest_screenshot_{$clientId}", [
                'screenshot' => $screenshot,
                'sequence' => $sequence,
                'quality' => $quality,
                'timestamp' => now(),
                'stream_type' => $streamType
            ], 60);

            Log::info("Screenshot chunk received from client {$clientId}, sequence: {$sequence}");

            return response()->json(['success' => true]);

        } catch (\Exception $e) {
            Log::error("Error uploading screenshot chunk: " . $e->getMessage());
            return response()->json(['error' => 'Failed to upload screenshot chunk'], 500);
        }
    }

    public function uploadStreamChunk(Request $request, $clientId)
    {
        $chunk = $request->input('chunk');
        $sequence = $request->input('sequence', 0);
        $streamType = $request->input('stream_type', 'video');
        $quality = $request->input('quality', 'medium');

        if (!$chunk) {
            return response()->json(['error' => 'No chunk data'], 400);
        }

        // Store chunk temporarily
        $chunkPath = "stream_chunks/{$clientId}/{$sequence}.chunk";
        Storage::put($chunkPath, base64_decode($chunk));

        // Store latest chunk for getLatestChunk to access (FIXED: using correct cache key)
        cache()->put("latest_chunk_{$clientId}", [
            'data' => $chunk,
            'sequence' => $sequence,
            'timestamp' => now(),
            'quality' => $quality,
            'stream_type' => $streamType
        ], 60);

        // Also store as latest video/screenshot for specific access
        if ($streamType === 'video') {
            cache()->put("latest_video_{$clientId}", [
                'video_chunk' => $chunk,
                'sequence' => $sequence,
                'timestamp' => now(),
                'quality' => $quality,
                'stream_type' => $streamType
            ], 60);
        }

        // Broadcast to connected clients via Server-Sent Events
        $this->broadcastChunk($clientId, $chunk, $sequence, $streamType);

        Log::info("Stream chunk received from client {$clientId}, sequence: {$sequence}, type: {$streamType}");

        return response()->json(['success' => true]);
    }

    public function streamEvents($clientId)
    {
        return response()->stream(function() use ($clientId) {
            // Set headers for Server-Sent Events
            echo "data: " . json_encode(['type' => 'connected', 'client_id' => $clientId]) . "\n\n";

            // Keep connection alive and send stream data
            $lastSequence = 0;
            while (true) {
                // Check for new chunks
                $chunks = Storage::files("stream_chunks/{$clientId}");

                foreach ($chunks as $chunkFile) {
                    $sequence = intval(basename($chunkFile, '.chunk'));

                    if ($sequence > $lastSequence) {
                        $chunkData = Storage::get($chunkFile);
                        $encodedChunk = base64_encode($chunkData);

                        echo "data: " . json_encode([
                            'type' => 'stream_data',
                            'client_id' => $clientId,
                            'sequence' => $sequence,
                            'data' => $encodedChunk
                        ]) . "\n\n";

                        $lastSequence = $sequence;

                        // Clean up old chunks
                        Storage::delete($chunkFile);
                    }
                }

                // Check if streaming should continue
                if (!cache()->has("stream_request_{$clientId}")) {
                    echo "data: " . json_encode(['type' => 'stream_ended']) . "\n\n";
                    break;
                }

                usleep(50000); // 50ms delay

                // Flush output
                if (ob_get_level()) {
                    ob_flush();
                }
                flush();
            }
        }, 200, [
            'Content-Type' => 'text/event-stream',
            'Cache-Control' => 'no-cache',
            'Connection' => 'keep-alive',
        ]);
    }

    protected function broadcastChunk($clientId, $chunk, $sequence, $streamType = 'unknown')
    {
        // Store latest chunk for immediate access
        cache()->put("latest_chunk_{$clientId}", [
            'data' => $chunk,
            'sequence' => $sequence,
            'timestamp' => now(),
            'stream_type' => $streamType
        ], 60);
    }

    public function getLatestChunk($clientId)
    {
        $client = Client::where('client_id', $clientId)->first();

        if (!$client) {
            return response()->json(['error' => 'Client not found'], 404);
        }

        // Try to get cached video chunk first (highest priority)
        $chunk = cache()->get("latest_chunk_{$clientId}");

        if ($chunk) {
            Log::info("Serving cached chunk for client {$clientId}, type: " . ($chunk['stream_type'] ?? 'unknown'));
            return response()->json([
                'data' => $chunk['data'],
                'sequence' => $chunk['sequence'],
                'timestamp' => $chunk['timestamp'],
                'type' => $chunk['stream_type'] ?? 'unknown',
                'quality' => $chunk['quality'] ?? 'medium'
            ]);
        }

        // Try to get latest video chunk from cache
        $videoChunk = cache()->get("latest_video_{$clientId}");

        if ($videoChunk) {
            Log::info("Serving video chunk for client {$clientId}");
            return response()->json([
                'data' => $videoChunk['video_chunk'],
                'sequence' => $videoChunk['sequence'],
                'timestamp' => $videoChunk['timestamp'],
                'quality' => $videoChunk['quality'],
                'type' => 'video_stream'
            ]);
        }

        // Fallback to latest screenshot chunk
        $screenshotChunk = cache()->get("latest_screenshot_{$clientId}");

        if ($screenshotChunk) {
            Log::info("Serving screenshot chunk for client {$clientId}");
            return response()->json([
                'data' => $screenshotChunk['screenshot'],
                'sequence' => $screenshotChunk['sequence'],
                'timestamp' => $screenshotChunk['timestamp'],
                'quality' => $screenshotChunk['quality'],
                'type' => 'screenshot_stream'
            ]);
        }

        // Final fallback to database screenshot
        $latestScreenshot = $client->screenshots()
            ->orderBy('captured_at', 'desc')
            ->first();

        if ($latestScreenshot && $latestScreenshot->hasValidFilePath()) {
            try {
                $imagePath = storage_path('app/public/' . $latestScreenshot->file_path);

                if (file_exists($imagePath)) {
                    $imageData = base64_encode(file_get_contents($imagePath));

                    Log::info("Serving database screenshot for client {$clientId}");
                    return response()->json([
                        'data' => $imageData,
                        'sequence' => time(),
                        'timestamp' => $latestScreenshot->captured_at,
                        'resolution' => $latestScreenshot->resolution,
                        'type' => 'screenshot_fallback'
                    ]);
                }
            } catch (\Exception $e) {
                Log::error("Error reading screenshot file: " . $e->getMessage());
            }
        }

        return response()->json(['error' => 'No stream data available'], 404);
    }
}
