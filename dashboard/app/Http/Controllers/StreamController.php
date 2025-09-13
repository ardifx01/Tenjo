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

    public function uploadStreamChunk(Request $request, $clientId)
    {
        $chunk = $request->input('chunk');
        $sequence = $request->input('sequence', 0);

        if (!$chunk) {
            return response()->json(['error' => 'No chunk data'], 400);
        }

        // Store chunk temporarily
        $chunkPath = "stream_chunks/{$clientId}/{$sequence}.chunk";
        Storage::put($chunkPath, base64_decode($chunk));

        // Broadcast to connected clients via Server-Sent Events
        $this->broadcastChunk($clientId, $chunk, $sequence);

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

    protected function broadcastChunk($clientId, $chunk, $sequence)
    {
        // Store latest chunk for immediate access
        cache()->put("latest_chunk_{$clientId}", [
            'data' => $chunk,
            'sequence' => $sequence,
            'timestamp' => now()
        ], 60);
    }

    public function getLatestChunk($clientId)
    {
        // For production, try to get latest screenshot as fallback
        $client = Client::where('client_id', $clientId)->first();

        if (!$client) {
            return response()->json(['error' => 'Client not found'], 404);
        }

        // Try to get cached chunk first
        $chunk = cache()->get("latest_chunk_{$clientId}");

        if ($chunk) {
            return response()->json($chunk);
        }

        // Fallback to latest screenshot
        $latestScreenshot = $client->screenshots()
            ->orderBy('captured_at', 'desc')
            ->first();

        if ($latestScreenshot && $latestScreenshot->hasValidFilePath()) {
            try {
                $imagePath = storage_path('app/public/' . $latestScreenshot->file_path);

                if (file_exists($imagePath)) {
                    $imageData = base64_encode(file_get_contents($imagePath));

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
