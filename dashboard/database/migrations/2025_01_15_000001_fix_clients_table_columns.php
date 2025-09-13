<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Fix clients table column names to match what the client sends
        Schema::table('clients', function (Blueprint $table) {
            // Check if columns exist before adding them
            if (!Schema::hasColumn('clients', 'first_seen')) {
                $table->timestamp('first_seen')->nullable()->after('last_seen');
            }
        });

        // Update existing records to use correct column names
        DB::statement("UPDATE clients SET first_seen = first_seen_at WHERE first_seen IS NULL AND first_seen_at IS NOT NULL");
        DB::statement("UPDATE clients SET last_seen = last_seen_at WHERE last_seen IS NULL AND last_seen_at IS NOT NULL");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('clients', function (Blueprint $table) {
            if (Schema::hasColumn('clients', 'first_seen')) {
                $table->dropColumn('first_seen');
            }
        });
    }
};