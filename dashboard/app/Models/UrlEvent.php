<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UrlEvent extends Model
{
    protected $fillable = [
        'client_id',
        'event_type',
        'url',
        'start_time',
        'end_time',
        'duration',
        'page_title'
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

    public function getDomainAttribute(): string
    {
        $parsedUrl = parse_url($this->url);
        return $parsedUrl['host'] ?? $this->url;
    }
}
