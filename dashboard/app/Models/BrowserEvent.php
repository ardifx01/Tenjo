<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class BrowserEvent extends Model
{
    protected $fillable = [
        'client_id',
        'event_type',
        'browser_name',
        'url',
        'title',
        'start_time',
        'end_time',
        'duration'
    ];

    protected $casts = [
        'start_time' => 'datetime',
        'end_time' => 'datetime'
    ];

    public function client(): BelongsTo
    {
        return $this->belongsTo(Client::class);
    }

    public function getDurationHumanAttribute(): string
    {
        if (!$this->duration) {
            return 'Unknown';
        }

        $seconds = $this->duration;
        $hours = floor($seconds / 3600);
        $minutes = floor(($seconds % 3600) / 60);
        $secs = $seconds % 60;

        if ($hours > 0) {
            return sprintf('%02d:%02d:%02d', $hours, $minutes, $secs);
        } else {
            return sprintf('%02d:%02d', $minutes, $secs);
        }
    }
}
