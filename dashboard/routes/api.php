<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ClientController;
use App\Http\Controllers\Api\ScreenshotController;
use App\Http\Controllers\Api\BrowserEventController;
use App\Http\Controllers\Api\ProcessEventController;
use App\Http\Controllers\Api\UrlEventController;
use App\Http\Controllers\StreamController;

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
});

// Screenshot routes
Route::prefix('screenshots')->group(function () {
    Route::post('/', [ScreenshotController::class, 'store']);
    Route::post('/upload', [ScreenshotController::class, 'upload']);
    Route::get('/', [ScreenshotController::class, 'index']);
    Route::get('/{screenshot}', [ScreenshotController::class, 'show']);
    Route::delete('/{screenshot}', [ScreenshotController::class, 'destroy']);
});

// Screenshot routes - direct endpoint for client compatibility
Route::post('/screenshots', [ScreenshotController::class, 'store']);

// Browser events routes
Route::prefix('browser-events')->group(function () {
    Route::post('/', [BrowserEventController::class, 'store']);
    Route::get('/', [BrowserEventController::class, 'index']);
    Route::get('/{browserEvent}', [BrowserEventController::class, 'show']);
});

// Process events routes
Route::prefix('process-events')->group(function () {
    Route::post('/', [ProcessEventController::class, 'store']);
    Route::get('/', [ProcessEventController::class, 'index']);
    Route::get('/{processEvent}', [ProcessEventController::class, 'show']);
});

// Process stats routes - direct endpoint for client compatibility
Route::post('/process-stats', [ProcessEventController::class, 'store']);

// URL events routes
Route::prefix('url-events')->group(function () {
    Route::post('/', [UrlEventController::class, 'store']);
    Route::get('/', [UrlEventController::class, 'index']);
    Route::get('/{urlEvent}', [UrlEventController::class, 'show']);
});

// Streaming routes
Route::prefix('stream')->group(function () {
    Route::get('/requests', function (Request $request) {
        // Check if streaming is requested for a client
        $clientId = $request->get('client_id');

        // For now, return a simple response
        // In production, this would check database for streaming requests
        return response()->json([
            'stream_requested' => false,
            'quality' => 'medium'
        ]);
    });

    Route::get('/websocket-url', function () {
        // Return WebSocket URL for streaming
        $wsUrl = config('app.websocket_url', 'ws://localhost:6001');

        return response()->json([
            'websocket_url' => $wsUrl
        ]);
    });
});

// Protected routes (with Sanctum authentication)
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', function (Request $request) {
        return $request->user();
    });

    // Add protected admin routes here if needed
});
