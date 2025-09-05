<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Screenshot extends Model
{
    protected $fillable = [
        'client_id',
        'filename',
        'file_path',
        'resolution',
        'monitor',
        'file_size',
        'captured_at'
    ];

    protected $casts = [
        'captured_at' => 'datetime',
        'file_size' => 'integer',
        'monitor' => 'integer'
    ];

    public function client(): BelongsTo
    {
        return $this->belongsTo(Client::class);
    }

    public function getUrlAttribute(): string
    {
        return asset('storage/screenshots/' . $this->filename);
    }

    public function getFileSizeHumanAttribute(): string
    {
        if (!$this->file_size) {
            return 'Unknown';
        }

        $bytes = $this->file_size;
        $units = ['B', 'KB', 'MB', 'GB'];

        for ($i = 0; $bytes > 1024 && $i < count($units) - 1; $i++) {
            $bytes /= 1024;
        }

        return round($bytes, 2) . ' ' . $units[$i];
    }

    public function getFilePathAttribute($value): ?string
    {
        return $value;
    }

    public function hasValidFilePath(): bool
    {
        return !empty($this->attributes['file_path']);
    }
}
