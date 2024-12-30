<?php

namespace App\Filament\Resources;

use App\Filament\Resources\UserResource\Pages;
use App\Filament\Resources\UserResource\RelationManagers;
use App\Models\User;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;
use Illuminate\Support\Facades\Hash;

class UserResource extends Resource
{
   protected static ?string $model = User::class;

   protected static ?string $navigationIcon = 'heroicon-o-users';
   protected static ?string $modelLabel = 'Usuario';
   protected static ?string $pluralModelLabel = 'Usuarios';
   protected static ?int $navigationSort = 1;

   public static function form(Form $form): Form
   {
       return $form
           ->schema([
               Forms\Components\TextInput::make('name')
                   ->required()
                   ->maxLength(255),
               Forms\Components\TextInput::make('email')
                   ->email()
                   ->required()
                   ->maxLength(255),
               Forms\Components\DateTimePicker::make('created_at')
                   ->label('Fecha de Creación')
                   ->default(now())
                   ->required()
                   ->disabled(),
               Forms\Components\TextInput::make('password')
                   ->password()
                   ->required(fn (string $operation): bool => $operation === 'create')
                   ->maxLength(255)
                   ->dehydrateStateUsing(fn ($state) => 
                       filled($state) ? Hash::make($state) : null
                   )
                   ->dehydrated(fn ($state) => filled($state)),
               Forms\Components\Select::make('roles')
                   ->relationship('roles', 'name')
                   ->required()
                   ->preload(),
               Forms\Components\Toggle::make('is_active')
                   ->required()
                   ->default(true)
           ]);
   }

   public static function table(Table $table): Table
   {
       return $table
           ->columns([
               Tables\Columns\TextColumn::make('name')
                   ->searchable(),
               Tables\Columns\TextColumn::make('email')
                   ->searchable(),
               Tables\Columns\TextColumn::make('roles.name')
                   ->badge(),
               Tables\Columns\IconColumn::make('is_active')
                   ->boolean(),
               Tables\Columns\TextColumn::make('created_at')
                   ->label('Fecha de Creación')
                   ->dateTime()
                   ->sortable(),
               Tables\Columns\TextColumn::make('updated_at')
                   ->dateTime()
                   ->sortable()
                   ->toggleable(isToggledHiddenByDefault: true),
           ])
           ->filters([
               //
           ])
           ->actions([
               Tables\Actions\EditAction::make(),
           ])
           ->bulkActions([
               Tables\Actions\BulkActionGroup::make([
                   Tables\Actions\DeleteBulkAction::make(),
               ]),
           ]);
   }

   public static function getRelations(): array
   {
       return [
           //
       ];
   }

   public static function getPages(): array
   {
       return [
           'index' => Pages\ListUsers::route('/'),
           'create' => Pages\CreateUser::route('/create'),
           'edit' => Pages\EditUser::route('/{record}/edit'),
       ];
   }
}