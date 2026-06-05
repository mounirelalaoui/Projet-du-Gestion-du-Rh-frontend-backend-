<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Conge;
use App\Models\Personnel;

class CongeSeeder extends Seeder
{
    public function run(): void
    {
        $personnelIds = Personnel::pluck('idPersonnel', 'matricule');
        $conges = [
            [
                'idPersonnel' => $personnelIds['FORM-001'] ?? null,
                'date_debut' => '2026-06-03',
                'date_fin' => '2026-06-07',
                'date_demande' => '2026-05-20',
                'type_conge' => 'annuel',
                'statut' => 'en_attente',
            ],
            [
                'idPersonnel' => $personnelIds['FORM-002'] ?? null,
                'date_debut' => '2026-07-15',
                'date_fin' => '2026-07-18',
                'date_demande' => '2026-05-18',
                'type_conge' => 'maladie',
                'statut' => 'approuve',
            ],
        ];

        foreach ($conges as $conge) {
            if (!$conge['idPersonnel']) {
                continue;
            }

            Conge::updateOrCreate(
                [
                    'idPersonnel' => $conge['idPersonnel'],
                    'date_debut' => $conge['date_debut'],
                    'date_fin' => $conge['date_fin'],
                ],
                $conge
            );
        }
    }
}
