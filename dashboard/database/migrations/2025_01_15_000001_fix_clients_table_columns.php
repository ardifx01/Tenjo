<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // The clients table already has the correct column names (first_seen, last_seen)
        // This migration was created to fix column names that were already correct
        // So we don't need to do anything here
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // No changes to reverse since no changes were made in up()
    }
};
