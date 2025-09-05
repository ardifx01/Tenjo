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
        Schema::create('screenshots', function (Blueprint $table) {
            $table->id();
            $table->foreignId('client_id')->constrained()->onDelete('cascade');
            $table->string('filename');
            $table->string('file_path');
            $table->string('resolution');
            $table->integer('monitor')->default(1);
            $table->integer('file_size')->nullable();
            $table->timestamp('captured_at');
            $table->timestamps();

            $table->index(['client_id', 'captured_at']);
            $table->index('captured_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('screenshots');
    }
};
