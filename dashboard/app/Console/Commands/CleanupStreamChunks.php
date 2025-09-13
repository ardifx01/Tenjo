<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;
use Carbon\Carbon;

class CleanupStreamChunks extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'tenjo:cleanup-streams {--days=7 : Number of days to keep stream chunks} {--dry-run : Show what would be deleted without actually deleting}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Cleanup old stream chunks to save storage space';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $daysToKeep = $this->option('days');
        $dryRun = $this->option('dry-run');

        $this->info("🧹 Starting stream chunks cleanup...");
        $this->info("📅 Keeping files newer than {$daysToKeep} days");

        if ($dryRun) {
            $this->warn("🔍 DRY RUN MODE - No files will be deleted");
        }

        $cutoffDate = Carbon::now()->subDays($daysToKeep);
        $this->info("📆 Cutoff date: {$cutoffDate->format('Y-m-d H:i:s')}");

        $streamChunksPath = storage_path('app/private/stream_chunks');

        if (!is_dir($streamChunksPath)) {
            $this->error("❌ Stream chunks directory not found: {$streamChunksPath}");
            return 1;
        }

        $totalSize = 0;
        $totalFiles = 0;
        $deletedSize = 0;
        $deletedFiles = 0;
        $clientsProcessed = 0;

        // Get all client directories
        $clientDirs = glob($streamChunksPath . '/*', GLOB_ONLYDIR);

        foreach ($clientDirs as $clientDir) {
            $clientId = basename($clientDir);
            $clientsProcessed++;

            $this->info("🔍 Processing client: {$clientId}");

            // Get all chunk files in client directory
            $chunkFiles = glob($clientDir . '/*.chunk');

            foreach ($chunkFiles as $chunkFile) {
                $fileTime = filemtime($chunkFile);
                $fileSize = filesize($chunkFile);
                $totalSize += $fileSize;
                $totalFiles++;

                if ($fileTime < $cutoffDate->timestamp) {
                    $deletedSize += $fileSize;
                    $deletedFiles++;

                    if (!$dryRun) {
                        unlink($chunkFile);
                        $this->line("  🗑️  Deleted: " . basename($chunkFile) . " (" . $this->formatBytes($fileSize) . ")");
                    } else {
                        $this->line("  🔍 Would delete: " . basename($chunkFile) . " (" . $this->formatBytes($fileSize) . ")");
                    }
                }
            }

            // Remove empty client directories
            if (!$dryRun && is_dir($clientDir) && count(glob($clientDir . '/*')) === 0) {
                rmdir($clientDir);
                $this->line("  📁 Removed empty directory: {$clientId}");
            }
        }

        $this->newLine();
        $this->info("📊 Cleanup Summary:");
        $this->table(
            ['Metric', 'Value'],
            [
                ['Clients processed', $clientsProcessed],
                ['Total files found', number_format($totalFiles)],
                ['Total size found', $this->formatBytes($totalSize)],
                ['Files ' . ($dryRun ? 'to delete' : 'deleted'), number_format($deletedFiles)],
                ['Space ' . ($dryRun ? 'to free' : 'freed'), $this->formatBytes($deletedSize)],
                ['Files remaining', number_format($totalFiles - $deletedFiles)],
                ['Space remaining', $this->formatBytes($totalSize - $deletedSize)],
            ]
        );

        if ($dryRun) {
            $this->warn("💡 Run without --dry-run to actually delete the files");
        } else {
            $this->info("✅ Cleanup completed successfully!");
        }

        return 0;
    }

    /**
     * Format bytes to human readable format
     */
    private function formatBytes($bytes, $precision = 2)
    {
        $units = array('B', 'KB', 'MB', 'GB', 'TB');

        for ($i = 0; $bytes > 1024 && $i < count($units) - 1; $i++) {
            $bytes /= 1024;
        }

        return round($bytes, $precision) . ' ' . $units[$i];
    }
}
