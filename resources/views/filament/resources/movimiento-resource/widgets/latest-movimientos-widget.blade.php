{{-- resources/views/filament/resources/movimiento-resource/widgets/latest-movimientos-widget.blade.php --}}
<x-filament-widgets::widget>
   <x-filament::section>
       <h2 class="text-3xl font-bold text-center mb-8 mt-8">Control de Equipos</h2>
   
       {{-- Campo de entrada del QR --}}
       <div class="mt-8 mb-20 py-4">
           <input
               type="text"
               wire:model.live="qrContent"
               wire:keydown.enter="handleQrScanned($event.target.value)"
               placeholder="Escriba o escanee el código QR"
               class="w-full p-5 border border-gray-300 rounded-lg text-xl shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all duration-200"
           />
       </div>

       {{-- Botones con estilo similar a la imagen --}}
       <div class="flex flex-col md:flex-row justify-center items-center gap-8 md:gap-24 py-4">
           <button
               wire:click="registrarEntrada"
               type="button"
               style="background-color: #22c55e;"
               class="w-40 h-16 rounded-lg text-white hover:opacity-90 hover:scale-105 transition-all duration-200 flex items-center justify-center shadow-lg px-4"
           >
               <div class="flex items-center justify-center space-x-2">
                   <svg class="h-6 w-6" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                       <path stroke-linecap="round" stroke-linejoin="round" d="M19 14l-7 7m0 0l-7-7m7 7V3" />
                   </svg>
                   <span class="text-base font-medium">Entrada</span>
               </div>
           </button>
       
           <button
               wire:click="registrarSalida"
               type="button"
               style="background-color: #ef4444;"
               class="w-40 h-16 rounded-lg text-white hover:opacity-90 hover:scale-105 transition-all duration-200 flex items-center justify-center shadow-lg px-4"
           >
               <div class="flex items-center justify-center space-x-2">
                   <svg class="h-6 w-6" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                       <path stroke-linecap="round" stroke-linejoin="round" d="M5 10l7-7m0 0l7 7m-7-7v18" />
                   </svg>
                   <span class="text-base font-medium">Salida</span>
               </div>
           </button>
       </div>
        
       {{-- Información del equipo encontrado con diseño mejorado --}}
       @if($equipoEncontrado && $equipoData)
           <div class="bg-white rounded-xl shadow-lg border border-gray-200 overflow-hidden mb-6 mt-12">
               <div class="px-6 py-4 bg-gray-50 border-b border-gray-200">
                   <div class="flex justify-between items-center">
                       <h3 class="text-lg font-semibold">Estado del Equipo</h3>
                       <span class="inline-flex items-center px-4 py-2 rounded-full text-sm font-semibold transition-colors 
                           {{ $equipoData['tipo'] === 'entrada' ? 'bg-green-100 text-green-800 hover:bg-green-200' : 'bg-red-100 text-red-800 hover:bg-red-200' }}">
                           @if($equipoData['tipo'] === 'entrada')
                               <svg class="w-5 h-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                   <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 13l-3 3m0 0l-3-3m3 3V8m0 13a9 9 0 110-18 9 9 0 010 18z" />
                               </svg>
                           @else
                               <svg class="w-5 h-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                   <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 11l3-3m0 0l3 3m-3-3v8m0-13a9 9 0 110 18 9 9 0 010-18z" />
                               </svg>
                           @endif
                           {{ ucfirst($equipoData['tipo']) }}
                       </span>
                   </div>
               </div>
               <div class="p-6 space-y-4">
                   <div class="flex items-center text-base">
                       <span class="text-gray-600 w-36 font-medium">Código QR:</span>
                       <span class="font-semibold">{{ $equipoData['contenido_qr'] }}</span>
                   </div>
                   <div class="flex items-center text-base">
                       <span class="text-gray-600 w-36 font-medium">Actualización:</span>
                       <span class="font-semibold">{{ $equipoData['fecha_hora'] }}</span>
                   </div>
               </div>
           </div>
       @endif

       {{-- Mensaje para equipo nuevo con diseño mejorado --}}
       @if($showRegistrationForm)
           <div class="rounded-xl bg-yellow-50 p-6 border border-yellow-200 shadow-sm mt-12">
               <div class="flex items-center">
                   <svg class="w-6 h-6 text-yellow-400 mr-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                       <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                   </svg>
                   <p class="text-base text-yellow-700 font-medium">
                       Equipo no registrado. Seleccione entrada o salida para registrarlo.
                   </p>
               </div>
           </div>
       @endif

       {{-- Botón de reinicio mejorado --}}
       @if($qrContent)
           <div class="flex justify-center mt-12">
               <button
                   wire:click="resetForm"
                   type="button"
                   class="px-8 py-4 bg-gray-500 text-white rounded-lg hover:bg-gray-600 hover:scale-105 transition-all duration-200 flex items-center shadow-md"
               >
                   <svg class="w-6 h-6 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                       <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                   </svg>
                   <span class="text-lg font-medium">Limpiar</span>
               </button>
           </div>
       @endif
   </x-filament::section>
</x-filament-widgets::widget>