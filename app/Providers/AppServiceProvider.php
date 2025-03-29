<?php

namespace App\Providers;

use Illuminate\Support\Facades\URL;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Forzar el esquema y la URL raíz para todas las URLs generadas por Laravel
        URL::forceScheme('http');
        URL::forceRootUrl(config('app.url'));
    }
}
