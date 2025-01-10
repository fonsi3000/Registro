<?php

namespace App\Filament\Resources\MovimientoResource\Widgets;

use App\Models\Movimiento;
use Filament\Widgets\Widget;
use Filament\Notifications\Notification;

class LatestMovimientosWidget extends Widget
{
    protected static string $view = 'filament.resources.movimiento-resource.widgets.latest-movimientos-widget';

    public ?string $qrContent = null;
    public bool $showRegistrationForm = false;
    public bool $equipoEncontrado = false;
    public ?array $equipoData = null;

    protected int | string | array $columnSpan = 'full';

    public function handleQrScanned($content)
    {
        if (empty($content)) {
            return;
        }

        $this->qrContent = $content;

        $equipo = Movimiento::where('contenido_qr', $content)->first();

        if ($equipo) {
            $this->equipoEncontrado = true;
            $this->equipoData = [
                'contenido_qr' => $equipo->contenido_qr,
                'tipo' => $equipo->tipo,
                'fecha_hora' => $equipo->fecha_hora->format('d/m/Y H:i:s')
            ];
            $this->showRegistrationForm = false;

            Notification::make()
                ->title('Equipo encontrado')
                ->success()
                ->send();
        } else {
            $this->equipoEncontrado = false;
            $this->equipoData = null;
            $this->showRegistrationForm = true;

            Notification::make()
                ->title('Equipo no registrado')
                ->warning()
                ->send();
        }
    }

    public function registrarMovimiento($tipo)
    {
        if (empty($this->qrContent)) {
            Notification::make()
                ->title('Error')
                ->body('Ingrese o escanee un código QR primero')
                ->danger()
                ->send();
            return;
        }

        try {
            $movimiento = Movimiento::registrarMovimiento(
                $this->qrContent,
                $tipo
            );

            Notification::make()
                ->title($tipo === 'entrada' ? '¡Entrada registrada!' : '¡Salida registrada!')
                ->success()
                ->send();

            // Limpiar el formulario después de registrar
            $this->resetForm();
        } catch (\Exception $e) {
            Notification::make()
                ->title('Error al procesar')
                ->body('Ha ocurrido un error al procesar el registro')
                ->danger()
                ->send();
        }
    }

    public function registrarEntrada()
    {
        $this->registrarMovimiento('entrada');
    }

    public function registrarSalida()
    {
        $this->registrarMovimiento('salida');
    }

    public function resetForm()
    {
        $this->reset(['qrContent', 'showRegistrationForm', 'equipoEncontrado', 'equipoData']);
    }

    public function updated($property)
    {
        if ($property === 'qrContent' && !empty($this->qrContent)) {
            $this->handleQrScanned($this->qrContent);
        }
    }
}
