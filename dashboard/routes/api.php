<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ClientController;
use App\Http\Controllers\Api\ScreenshotController;
use App\Http\Controllers\Api\BrowserEventController;
use App\Http\Controllers\Api\ProcessEventController;
use App\Http\Controllers\Api\UrlEventController;
use App\Http\Controllers\StreamController;

// Add CORS middleware for production
Route::middleware(['cors'])->group(function () {

// Activity export
Route::get('/activities/export', [ClientController::class, 'exportActivities']);

// Health check
Route::get('/health', [ClientController::class, 'health']);

// Client routes
Route::prefix('clients')->group(function () {
    Route::post('/register', [ClientController::class, 'register']);
    Route::post('/heartbeat', [ClientController::class, 'heartbeat']);
    Route::get('/', [ClientController::class, 'index']);
    Route::get('/{clientId}', [ClientController::class, 'show']);
    Route::get('/{clientId}/settings', [ClientController::class, 'getSettings']);
    Route::get('/{clientId}/latest-screenshot', [ClientController::class, 'getLatestScreenshot']);
    Route::put('/{clientId}/status', [ClientController::class, 'updateStatus']);
    
    // Add status endpoint for dashboard
    Route::get('/status', function () {
        $clients = \App\Models\Client::all()->map(function($client) {
            return [
                'client_id' => $client->client_id,
                'is_online' => $client->isOnline(),
                'last_seen_human' => $client->last_seen ? $client->last_seen->diffForHumans() : 'Never'
            ];
        });
        
        return response()->json($clients);
    });
});

// Streaming endpoints
Route::prefix('stream')->group(function () {
    // Client endpoints
    Route::get('/request/{clientId}', [StreamController::class, 'getStreamRequest']);
    Route::post('/chunk/{clientId}', [StreamController::class, 'uploadStreamChunk']);

    // Dashboard endpoints
    Route::post('/start/{clientId}', [StreamController::class, 'startStream']);
    Route::post('/stop/{clientId}', [StreamController::class, 'stopStream']);
    Route::get('/events/{clientId}', [StreamController::class, 'streamEvents']);
    Route::get('/latest/{clientId}', [StreamController::class, 'getLatestChunk']);

    // WebSocket support
    Route::get('/websocket-url', function () {
        $wsUrl = config('app.websocket_url', 'ws://103.129.149.67:6001');
        return response()->json(['websocket_url' => $wsUrl]);
    });
});

// Screenshot routes
Route::prefix('screenshots')->group(function () {
    Route::post('/', [ScreenshotController::class, 'store']);
    Route::post('/upload', [ScreenshotController::class, 'upload']);
    Route::get('/', [ScreenshotController::class, 'index']);
    Route::get('/{screenshot}', [ScreenshotController::class, 'show']);
    Route::delete('/{screenshot}', [ScreenshotController::class, 'destroy']);
});

// Browser Events routes
Route::prefix('browser-events')->group(function () {
    Route::post('/', [BrowserEventController::class, 'store']);
    Route::get('/', [BrowserEventController::class, 'index']);
    Route::get('/{event}', [BrowserEventController::class, 'show']);
});

// Process Events routes
Route::prefix('process-events')->group(function () {
    Route::post('/', [ProcessEventController::class, 'store']);
    Route::get('/', [ProcessEventController::class, 'index']);
    Route::get('/{event}', [ProcessEventController::class, 'show']);
});

// URL Events routes
Route::prefix('url-events')->group(function () {
    Route::post('/', [UrlEventController::class, 'store']);
    Route::get('/', [UrlEventController::class, 'index']);
    Route::get('/{event}', [UrlEventController::class, 'show']);
});

// System stats endpoint
Route::post('/system-stats', function (Request $request) {
    $request->validate(['client_id' => 'required|string']);

    return response()->json([
        'success' => true,
        'message' => 'System stats received'
    ]);
});

// Protected routes (with Sanctum authentication)
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', function (Request $request) {
        return $request->user();
    });
});

}); // End CORS middleware group