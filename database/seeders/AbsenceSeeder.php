<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Absence;
use App\Models\Personnel;

class AbsenceSeeder extends Seeder
{
    public function run(): void
    {
        $personnelIds = Personnel::pluck('idPersonnel', 'matricule');
        $absences = [
            [
                'date_absence' => '2026-04-01',
                'motif' => 'maladie',
                'idPersonnel' => $personnelIds['FORM-001'] ?? null,
            ],
            [
                'date_absence' => '2026-04-10',
                'motif' => 'congé',
                'idPersonnel' => $personnelIds['FORM-001'] ?? null,
            ],
            [
                'date_absence' => '2026-04-15',
                'motif' => 'absence injustifiée',
                'idPersonnel' => $personnelIds['FORM-002'] ?? null,
            ]
        ];

        foreach ($absences as $absence) {
            if (!$absence['idPersonnel']) {
                continue;
            }

            Absence::updateOrCreate(
                [
                    'idPersonnel' => $absence['idPersonnel'],
                    'date_absence' => $absence['date_absence'],
                ],
                $absence
            );
        }
    }
}
