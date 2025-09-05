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
        Schema::create('process_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('client_id')->constrained()->onDelete('cascade');
            $table->enum('event_type', ['process_started', 'process_ended']);
            $table->string('process_name');
            $table->integer('process_pid');
            $table->timestamp('start_time')->nullable();
            $table->timestamp('end_time')->nullable();
            $table->integer('duration')->nullable(); // in seconds
            $table->json('system_info')->nullable();
            $table->timestamps();

            $table->index(['client_id', 'start_time']);
            $table->index(['process_name', 'start_time']);
            $table->index('start_time');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('process_events');
    }
};
