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
        Schema::create('clients', function (Blueprint $table) {
            $table->id();
            $table->string('hostname');
            $table->string('client_id')->unique();
            $table->string('ip_address');
            $table->string('username');
            $table->json('os_info');
            $table->enum('status', ['active', 'inactive', 'offline'])->default('offline');
            $table->timestamp('last_seen')->nullable();
            $table->timestamp('first_seen')->nullable();
            $table->string('timezone')->default('Asia/Jakarta');
            $table->timestamps();

            $table->index(['status', 'last_seen']);
            $table->index('hostname');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('clients');
    }
};
