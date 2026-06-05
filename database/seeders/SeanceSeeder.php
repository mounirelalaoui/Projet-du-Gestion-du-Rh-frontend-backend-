<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Personnel;
use App\Models\Seance;

class SeanceSeeder extends Seeder
{
    public function run(): void
    {
        $amine = Personnel::where('matricule', 'FORM-001')->first();
        $sara = Personnel::where('matricule', 'FORM-002')->first();

        $seances = [
            [
                'personnel' => $amine,
                'matricule' => 'FORM-001',
                'full_name' => 'Amine Test',
                'jour' => 1,
                'heure_debut' => '08:30:00',
                'heure_fin' => '10:30:00',
                'module' => 'Développement Digital',
                'salle' => 'Salle A1',
                'groupe' => 'DD101',
                'type' => 'cours',
                'etablissement' => 'OFPPT Casa',
                'date' => '2026-05-26',
            ],
            [
                'personnel' => $amine,
                'matricule' => 'FORM-001',
                'full_name' => 'Amine Test',
                'jour' => 3,
                'heure_debut' => '14:00:00',
                'heure_fin' => '16:00:00',
                'module' => 'Gestion Entreprise',
                'salle' => 'Salle B2',
                'groupe' => 'GE201',
                'type' => 'cours',
                'etablissement' => 'OFPPT Casa',
                'date' => '2026-05-28',
            ],
            [
                'personnel' => $sara,
                'matricule' => 'FORM-002',
                'full_name' => 'Sara Ali',
                'jour' => 2,
                'heure_debut' => '10:30:00',
                'heure_fin' => '12:30:00',
                'module' => 'Infrastructure Digitale',
                'salle' => 'Lab R1',
                'groupe' => 'ID110',
                'type' => 'cours',
                'etablissement' => 'OFPPT Rabat',
                'date' => '2026-05-27',
            ],
        ];

        foreach ($seances as $seance) {
            $personnel = $seance['personnel'];
            unset($seance['personnel']);

            if (!$personnel) {
                continue;
            }

            $payload = array_merge($seance, [
                'idPersonnel' => $personnel->idPersonnel,
            ]);

            Seance::updateOrCreate(
                [
                    'idPersonnel' => $payload['idPersonnel'],
                    'jour' => $payload['jour'],
                    'heure_debut' => $payload['heure_debut'],
                    'module' => $payload['module'],
                    'date' => $payload['date'],
                ],
                $payload
            );
        }
    }
}
