<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Carbon\Carbon;

class Client extends Model
{
    protected $fillable = [
        'hostname',
        'client_id',
        'ip_address',
        'username',
        'os_info',
        'status',
        'last_seen',
        'first_seen',
        'timezone'
    ];

    protected $casts = [
        'os_info' => 'array',
        'last_seen' => 'datetime',
        'first_seen' => 'datetime'
    ];

    public function screenshots(): HasMany
    {
        return $this->hasMany(Screenshot::class);
    }

    public function browserEvents(): HasMany
    {
        return $this->hasMany(BrowserEvent::class);
    }

    public function processEvents(): HasMany
    {
        return $this->hasMany(ProcessEvent::class);
    }

    public function urlEvents(): HasMany
    {
        return $this->hasMany(UrlEvent::class);
    }

    public function isOnline(): bool
    {
        if (!$this->last_seen) {
            return false;
        }

        return $this->last_seen->diffInMinutes(now()) <= 5;
    }

    public function getStatusAttribute(): string
    {
        if ($this->isOnline()) {
            return 'active';
        }

        return 'offline';
    }

    public function updateLastSeen(): void
    {
        $this->update([
            'last_seen' => now(),
            'status' => 'active'
        ]);
    }

    public function getTodayScreenshots()
    {
        return $this->screenshots()
            ->whereDate('captured_at', today())
            ->orderBy('captured_at', 'desc');
    }

    public function getTodayBrowserActivity()
    {
        return $this->browserEvents()
            ->whereDate('created_at', today())
            ->orderBy('start_time', 'desc');
    }

    public function getTodayProcessActivity()
    {
        return $this->processEvents()
            ->whereDate('created_at', today())
            ->orderBy('start_time', 'desc');
    }

    public function getOsDisplayName(): string
    {
        if (!$this->os_info || !is_array($this->os_info)) {
            return 'Unknown';
        }

        $name = $this->os_info['name'] ?? 'Unknown';
        $version = $this->os_info['version'] ?? '';
        $platform = $this->os_info['platform'] ?? '';

        if ($version) {
            return $name . ' ' . $version;
        }

        return $name;
    }

    public function getOsPlatform(): string
    {
        if (!$this->os_info || !is_array($this->os_info)) {
            return 'Unknown';
        }

        return $this->os_info['platform'] ?? $this->os_info['name'] ?? 'Unknown';
    }
}
