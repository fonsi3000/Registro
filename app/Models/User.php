<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Spatie\Permission\Traits\HasRoles;
use Illuminate\Notifications\Notifiable;
use Filament\Panel;
use Filament\Models\Contracts\FilamentUser;

class User extends Authenticatable implements FilamentUser
{
   use HasFactory, HasRoles, Notifiable;

   protected $fillable = [
       'name',
       'email',
       'password',
       'is_active'
   ];

   protected $hidden = [
       'password',
       'remember_token',
   ];

   protected function casts(): array
   {
       return [
           'email_verified_at' => 'datetime',
           'password' => 'hashed',
           'is_active' => 'boolean',
       ];
   }

   public function canAccessPanel(Panel $panel): bool
   {
       return $this->is_active;
   }
}