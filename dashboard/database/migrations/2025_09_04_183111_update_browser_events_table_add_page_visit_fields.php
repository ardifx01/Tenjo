<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('browser_events', function (Blueprint $table) {
            // Add new columns for page visit tracking
            $table->text('url')->nullable()->after('browser_name');
            $table->string('title')->nullable()->after('url');
        });

        // For SQLite, we need to recreate the table to remove constraints
        // But for now, we'll handle validation in the application layer
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('browser_events', function (Blueprint $table) {
            $table->dropColumn(['url', 'title']);
        });
    }
};
