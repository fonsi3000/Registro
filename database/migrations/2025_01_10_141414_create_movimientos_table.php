<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('movimientos', function (Blueprint $table) {
            $table->id();
            $table->string('contenido_qr')->unique();    // Agregamos ->unique() para evitar duplicados
            $table->enum('tipo', ['entrada', 'salida']);
            $table->timestamp('fecha_hora');
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('movimientos');
    }
};
