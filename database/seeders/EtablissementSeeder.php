<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Etablissement;

class EtablissementSeeder extends Seeder
{
    public function run(): void
    {
        $etablissements = [
            [
                'nom' => 'OFPPT Casa',
                'ville' => 'Casablanca',
            ],
            [
                'nom' => 'OFPPT Rabat',
                'ville' => 'Rabat',
            ],
            [
                'nom' => 'OFPPT Tanger',
                'ville' => 'Tanger',
            ]
        ];

        foreach ($etablissements as $etablissement) {
            Etablissement::updateOrCreate(
                ['nom' => $etablissement['nom']],
                $etablissement
            );
        }
    }
}
