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
        if (!Schema::hasColumn('specialites', 'type_specialite')) {
            Schema::table('specialites', function (Blueprint $table) {
                $table->enum('type_specialite', ['origine', 'enseignee'])
                    ->default('enseignee')
                    ->after('nom_specialite');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasColumn('specialites', 'type_specialite')) {
            Schema::table('specialites', function (Blueprint $table) {
                $table->dropColumn('type_specialite');
            });
        }
    }
};
