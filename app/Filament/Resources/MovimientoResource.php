<?php

namespace App\Filament\Resources;

use App\Filament\Resources\MovimientoResource\Pages;
use App\Models\Movimiento;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Actions\Action;
use Filament\Support\Enums\FontWeight;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

class MovimientoResource extends Resource
{
    protected static ?string $model = Movimiento::class;
    protected static ?string $navigationIcon = 'heroicon-o-qr-code';
    protected static ?string $navigationLabel = 'Control de Equipos';
    protected static ?string $modelLabel = 'Equipo';
    protected static ?string $pluralModelLabel = 'Equipos';
    protected static ?int $navigationSort = 1;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make()
                    ->schema([
                        Forms\Components\TextInput::make('contenido_qr')
                            ->label('Código QR')
                            ->required()
                            ->unique(ignoreRecord: true)
                            ->placeholder('Escanee o ingrese el código QR')
                            ->maxLength(255),

                        Forms\Components\Select::make('tipo')
                            ->label('Estado')
                            ->options([
                                'entrada' => 'Entrada',
                                'salida' => 'Salida',
                            ])
                            ->required()
                            ->native(false),

                        Forms\Components\DateTimePicker::make('fecha_hora')
                            ->label('Fecha y Hora')
                            ->required()
                            ->default(now())
                            ->seconds(false)
                            ->timezone('America/Bogota'),
                    ])
                    ->columns(2)
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('contenido_qr')
                    ->label('Equipo')
                    ->searchable()
                    ->sortable()
                    ->weight(FontWeight::Bold)
                    ->copyable()
                    ->copyMessage('Código QR copiado')
                    ->copyMessageDuration(1500),

                TextColumn::make('tipo')
                    ->label('Estado')
                    ->badge()
                    ->color(fn(string $state): string => match ($state) {
                        'entrada' => 'success',
                        'salida' => 'danger',
                    })
                    ->icon(fn(string $state): string => match ($state) {
                        'entrada' => 'heroicon-o-arrow-down-circle',
                        'salida' => 'heroicon-o-arrow-up-circle',
                    }),

                TextColumn::make('fecha_hora')
                    ->label('Última actualización')
                    ->dateTime('d/m/Y H:i:s')
                    ->sortable()
                    ->description(fn(Movimiento $record): string => $record->created_at->diffForHumans()),
            ])
            ->defaultSort('fecha_hora', 'desc')
            ->filters([
                Tables\Filters\SelectFilter::make('tipo')
                    ->options([
                        'entrada' => 'Dentro',
                        'salida' => 'Fuera',
                    ])
                    ->label('Estado')
                    ->indicator('Estado'),

                Tables\Filters\Filter::make('fecha_hora')
                    ->form([
                        Forms\Components\DatePicker::make('desde')
                            ->label('Desde'),
                        Forms\Components\DatePicker::make('hasta')
                            ->label('Hasta'),
                    ])
                    ->query(function (Builder $query, array $data): Builder {
                        return $query
                            ->when(
                                $data['desde'],
                                fn(Builder $query, $date): Builder => $query->whereDate('fecha_hora', '>=', $date),
                            )
                            ->when(
                                $data['hasta'],
                                fn(Builder $query, $date): Builder => $query->whereDate('fecha_hora', '<=', $date),
                            );
                    })
            ])
            ->actions([
                Tables\Actions\ActionGroup::make([
                    Tables\Actions\ViewAction::make(),
                    Tables\Actions\EditAction::make(),
                    Tables\Actions\Action::make('entrada')
                        ->label('Registrar Entrada')
                        ->icon('heroicon-o-arrow-down-circle')
                        ->color('success')
                        ->requiresConfirmation()
                        ->action(function (Movimiento $record) {
                            $record->update([
                                'tipo' => 'entrada',
                                'fecha_hora' => now()
                            ]);
                        }),
                    Tables\Actions\Action::make('salida')
                        ->label('Registrar Salida')
                        ->icon('heroicon-o-arrow-up-circle')
                        ->color('danger')
                        ->requiresConfirmation()
                        ->action(function (Movimiento $record) {
                            $record->update([
                                'tipo' => 'salida',
                                'fecha_hora' => now()
                            ]);
                        }),
                ]),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make()
                        ->requiresConfirmation(),
                ]),
            ])
            ->emptyStateActions([
                Tables\Actions\CreateAction::make()
                    ->label('Registrar nuevo equipo'),
            ])
            ->striped()
            ->poll('10s');
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListMovimientos::route('/'),
            'create' => Pages\CreateMovimiento::route('/create'),
            'view' => Pages\ViewMovimiento::route('/{record}'),
            'edit' => Pages\EditMovimiento::route('/{record}/edit'),
        ];
    }

    public static function getNavigationBadge(): ?string
    {
        return static::getModel()::where('tipo', 'salida')->count() . ' fuera';
    }

    public static function getNavigationBadgeColor(): string|null
    {
        return static::getModel()::where('tipo', 'salida')->count() > 0 ? 'warning' : 'success';
    }
}
