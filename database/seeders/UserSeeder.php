<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        $users = [
            [
                'username' => 'admin',
                'email' => 'admin@test.com',
                'password' => Hash::make('123456'),
                'Role' => 'directeur du complexe',
                'idPersonnel' => null,
            ],
            [
                'username' => 'gestionnaire',
                'email' => 'gestion@test.com',
                'password' => Hash::make('123456'),
                'Role' => 'gestionnaire CFMR',
                'idPersonnel' => null,
            ],
        ];

        foreach ($users as $user) {
            User::updateOrCreate(
                ['email' => $user['email']],
                $user
            );
        }
    }
}
