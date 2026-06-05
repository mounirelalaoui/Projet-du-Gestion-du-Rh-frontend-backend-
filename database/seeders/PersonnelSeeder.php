<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Etablissement;
use App\Models\Personnel;
use App\Models\Specialite;

class PersonnelSeeder extends Seeder
{
    public function run(): void
    {
        $etabIds = Etablissement::pluck('idEtab', 'nom');
        $specialiteIds = Specialite::pluck('idSpecialite', 'nom_specialite');

        $personnels = [
            [
                'matricule' => 'FORM-001',
                'cin' => 'AA12345',
                'nom' => 'Amine',
                'prenom' => 'Test',
                'nom_prenom' => 'Amine Test',
                'type' => 'formateur',
                'type_personnel' => 'formateur',
                'statut' => 'permanent',
                'date_naissance' => '1995-01-01',
                'lieu_naissance' => 'Casablanca',
                'situation_familiale' => 'single',
                'nombre_enfant' => 0,
                'adresse_actuelle' => 'Casablanca',
                'grade' => 'Senior',
                'echelon' => 3,
                'fonction' => 'Developer',
                'telephone' => '0600000000',
                'idEtab' => $etabIds['OFPPT Casa'] ?? null,
                'specialites' => ['Développement Digital', 'Gestion Entreprise']
            ],
            [
                'matricule' => 'FORM-002',
                'cin' => 'BB67890',
                'nom' => 'Sara',
                'prenom' => 'Ali',
                'nom_prenom' => 'Sara Ali',
                'type' => 'formateur',
                'type_personnel' => 'formateur',
                'statut' => 'vacataire',
                'date_naissance' => '2000-01-01',
                'lieu_naissance' => 'Rabat',
                'situation_familiale' => 'single',
                'nombre_enfant' => 0,
                'adresse_actuelle' => 'Rabat',
                'grade' => 'Junior',
                'echelon' => 2,
                'fonction' => 'Developer',
                'telephone' => '0700000000',
                'idEtab' => $etabIds['OFPPT Rabat'] ?? null,
                'specialites' => ['Infrastructure Digitale']
            ],
            [
                'matricule' => 'ADM-001',
                'cin' => 'CC24680',
                'nom' => 'Youssef',
                'prenom' => 'Bennani',
                'nom_prenom' => 'Youssef Bennani',
                'type' => 'administratif',
                'type_personnel' => 'administratif',
                'statut' => 'permanent',
                'date_naissance' => '1989-06-15',
                'lieu_naissance' => 'Tanger',
                'situation_familiale' => 'married',
                'nombre_enfant' => 2,
                'adresse_actuelle' => 'Tanger',
                'grade' => 'Chef de service',
                'echelon' => 4,
                'fonction' => 'Gestion RH',
                'telephone' => '0611223344',
                'idEtab' => $etabIds['OFPPT Tanger'] ?? null,
                'specialites' => []
            ],
        ];

        foreach ($personnels as $data) {
            $specialites = $data['specialites'];
            unset($data['specialites']);

            $personnel = Personnel::updateOrCreate(
                ['cin' => $data['cin']],
                $data
            );

            $specIds = collect($specialites)
                ->map(fn ($name) => $specialiteIds[$name] ?? null)
                ->filter()
                ->values()
                ->all();

            $personnel->specialites()->sync($specIds);
        }
    }
}
