<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Specialite;

class SpecialiteSeeder extends Seeder
{
    public function run(): void
    {
        $specialites = [
            ['nom_specialite' => 'Développement Digital', 'type_specialite' => 'enseignee'],
            ['nom_specialite' => 'Gestion Entreprise', 'type_specialite' => 'enseignee'],
            ['nom_specialite' => 'Infrastructure Digitale', 'type_specialite' => 'enseignee'],
            ['nom_specialite' => 'Administration RH', 'type_specialite' => 'origine'],
        ];

        foreach ($specialites as $specialite) {
            Specialite::updateOrCreate(
                ['nom_specialite' => $specialite['nom_specialite']],
                $specialite
            );
        }
    }
}
