<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Schedule automatic cleanup of stream chunks every week
Schedule::command('tenjo:cleanup-streams', ['--days=7'])
    ->weekly()
    ->sundays()
    ->at('02:00')
    ->description('Weekly cleanup of old stream chunks (older than 7 days)')
    ->emailOutputOnFailure(config('mail.admin_email', 'admin@tenjo.app'));

// Schedule daily cleanup for very old files (older than 30 days)
Schedule::command('tenjo:cleanup-streams', ['--days=30'])
    ->daily()
    ->at('03:00')
    ->description('Daily cleanup of very old stream chunks (older than 30 days)')
    ->when(function () {
        // Only run if storage is getting full (more than 5GB)
        $streamPath = storage_path('app/private/stream_chunks');
        if (!is_dir($streamPath)) return false;

        $totalSize = 0;
        $iterator = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($streamPath));
        foreach ($iterator as $file) {
            if ($file->isFile()) {
                $totalSize += $file->getSize();
            }
        }

        // Run cleanup if storage > 5GB (5 * 1024 * 1024 * 1024 bytes)
        return $totalSize > 5368709120;
    });

// Emergency cleanup for extremely old files (older than 1 day) if storage > 10GB
Schedule::command('tenjo:cleanup-streams', ['--days=1'])
    ->hourly()
    ->description('Emergency cleanup when storage is critically full')
    ->when(function () {
        $streamPath = storage_path('app/private/stream_chunks');
        if (!is_dir($streamPath)) return false;

        $totalSize = 0;
        $iterator = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($streamPath));
        foreach ($iterator as $file) {
            if ($file->isFile()) {
                $totalSize += $file->getSize();
            }
        }

        // Emergency cleanup if storage > 10GB
        return $totalSize > 10737418240;
    });
