<!-- resources/views/filament/resources/movimiento-resource/pages/view-movimiento.blade.php -->
<x-filament-panels::page>
    <div class="space-y-6">
        <div class="filament-resource-details">
            <!-- Información del equipo -->
            <x-filament::card>
                <div class="space-y-4">
                    <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
                        <div>
                            <h3 class="text-lg font-medium">Equipo</h3>
                            <p class="mt-1">{{ $record->contenido_qr }}</p>
                        </div>
                        <div>
                            <h3 class="text-lg font-medium">Estado Actual</h3>
                            <div class="mt-1">
                                @if($record->tipo === 'entrada')
                                    <x-filament::badge color="success">Entrada</x-filament::badge>
                                @else
                                    <x-filament::badge color="danger">Salida</x-filament::badge>
                                @endif
                            </div>
                        </div>
                        <div>
                            <h3 class="text-lg font-medium">Última Actualización</h3>
                            <p class="mt-1">{{ $record->fecha_hora->format('d/m/Y H:i:s') }}</p>
                        </div>
                    </div>
                </div>
            </x-filament::card>

            <!-- Scanner QR -->
            <x-filament::card class="mt-6">
                <h3 class="text-lg font-medium mb-4">Escanear QR</h3>
                <div id="reader" class="w-full"></div>
                <div id="result" class="mt-4 text-center text-lg"></div>
            </x-filament::card>
        </div>
    </div>

    <script src="https://unpkg.com/html5-qrcode"></script>
    <script>
        function onScanSuccess(decodedText, decodedResult) {
            document.getElementById('result').textContent = decodedText;
            // Emitir evento a Livewire
            @this.dispatch('qr-scanned', decodedText);
        }

        function onScanFailure(error) {
            console.warn(`Escaneo fallido: ${error}`);
        }

        let html5QrcodeScanner = new Html5QrcodeScanner(
            "reader",
            { fps: 10, qrbox: { width: 250, height: 250 } }
        );
        html5QrcodeScanner.render(onScanSuccess, onScanFailure);
    </script>
</x-filament-panels::page>