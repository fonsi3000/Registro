<?php

namespace App\Filament\Resources\MovimientoResource\Pages;

use App\Filament\Resources\MovimientoResource;
use Filament\Actions;
use Filament\Resources\Pages\ViewRecord;
use Filament\Notifications\Notification;
use Livewire\Attributes\On;

class ViewMovimiento extends ViewRecord
{
    protected static string $resource = MovimientoResource::class;

    public ?string $qrContent = null;

    protected function getHeaderActions(): array
    {
        return [
            Actions\Action::make('entrada')
                ->label('Registrar Entrada')
                ->color('success')
                ->icon('heroicon-o-arrow-down-circle')
                ->action('registrarEntrada')
                ->requiresConfirmation(),
            Actions\Action::make('salida')
                ->label('Registrar Salida')
                ->color('danger')
                ->icon('heroicon-o-arrow-up-circle')
                ->action('registrarSalida')
                ->requiresConfirmation(),
            Actions\EditAction::make(),
        ];
    }

    public function registrarEntrada()
    {
        $this->record->update([
            'tipo' => 'entrada',
            'fecha_hora' => now()
        ]);

        Notification::make()
            ->title('¡Entrada registrada!')
            ->success()
            ->send();

        $this->refresh();
    }

    public function registrarSalida()
    {
        $this->record->update([
            'tipo' => 'salida',
            'fecha_hora' => now()
        ]);

        Notification::make()
            ->title('¡Salida registrada!')
            ->success()
            ->send();

        $this->refresh();
    }

    #[On('qr-scanned')]
    public function handleQrScanned($qrContent)
    {
        if ($qrContent !== $this->record->contenido_qr) {
            Notification::make()
                ->title('QR no coincide')
                ->body('El QR escaneado no corresponde a este equipo')
                ->danger()
                ->send();
            return;
        }

        $this->qrContent = $qrContent;

        Notification::make()
            ->title('QR verificado')
            ->success()
            ->send();
    }

    protected function getViewData(): array
    {
        return [
            'record' => $this->record,
            'qrContent' => $this->qrContent,
        ];
    }
}
