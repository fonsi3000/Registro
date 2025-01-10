<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Movimiento extends Model
{
    use HasFactory;

    protected $fillable = [
        'contenido_qr',
        'tipo',
        'fecha_hora'
    ];

    protected $casts = [
        'fecha_hora' => 'datetime'
    ];

    // Método para registrar o actualizar un movimiento
    public static function registrarMovimiento($contenidoQr, $tipo)
    {
        return self::updateOrCreate(
            ['contenido_qr' => $contenidoQr], // Buscar por contenido_qr
            [
                'tipo' => $tipo,
                'fecha_hora' => now()
            ]
        );
    }
}
