<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Personnel;
use App\Models\Etablissement;
use App\Models\Specialite;
use App\Models\Diplome;
use App\Models\Absence;
use App\Models\Conge;
use App\Models\Seance;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;

class DatabaseDemoSeeder extends Seeder
{
    public function run(): void
    {
        // Disable foreign key checks for clean seeding
        DB::statement('SET FOREIGN_KEY_CHECKS=0;');
        
        // Truncate existing tables
        User::truncate();
        Personnel::truncate();
        Etablissement::truncate();
        Specialite::truncate();
        Diplome::truncate();
        Absence::truncate();
        Conge::truncate();
        Seance::truncate();
        DB::table('obtenir')->truncate();
        DB::table('enseigner')->truncate();
        
        DB::statement('SET FOREIGN_KEY_CHECKS=1;');

        // 1. Seed Etablissements
        $etabs = [
            ['nom' => 'ISTA NTIC Sidi Maârouf', 'ville' => 'Casablanca'],
            ['nom' => 'ISTA Agdal', 'ville' => 'Rabat'],
            ['nom' => 'ISTA Route de l\'Aéroport', 'ville' => 'Tanger'],
            ['nom' => 'ISTA Hay Riad', 'ville' => 'Rabat'],
            ['nom' => 'ISTA Bab Doukkala', 'ville' => 'Marrakech'],
        ];
        $etabModels = [];
        foreach ($etabs as $etab) {
            $etabModels[] = Etablissement::create($etab);
        }

        // 2. Seed Specialites
        $specs = [
            ['nom_specialite' => 'Développement Digital', 'type_specialite' => 'enseignee'],
            ['nom_specialite' => 'Infrastructure Digitale', 'type_specialite' => 'enseignee'],
            ['nom_specialite' => 'Gestion des Entreprises', 'type_specialite' => 'enseignee'],
            ['nom_specialite' => 'Intelligence Artificielle', 'type_specialite' => 'enseignee'],
            ['nom_specialite' => 'Administration des RH', 'type_specialite' => 'origine'],
            ['nom_specialite' => 'Génie Logiciel', 'type_specialite' => 'origine'],
        ];
        $specModels = [];
        foreach ($specs as $spec) {
            $specModels[] = Specialite::create($spec);
        }

        // 3. Seed Diplomes
        $diplomes = [
            ['nom_diplome' => 'Doctorat en Informatique'],
            ['nom_diplome' => 'Master Professionnel'],
            ['nom_diplome' => 'Licence Fondamentale'],
            ['nom_diplome' => 'Diplôme d\'Ingénieur d\'État'],
            ['nom_diplome' => 'Diplôme de Technicien Spécialisé (DTS)'],
        ];
        $diplomeModels = [];
        foreach ($diplomes as $diplome) {
            $diplomeModels[] = Diplome::create($diplome);
        }

        // Let's get reference IDs
        $etabIds = collect($etabModels)->pluck('idEtab')->toArray();
        $specIds = collect($specModels)->pluck('idSpecialite', 'nom_specialite')->toArray();
        $diplomeIds = collect($diplomeModels)->pluck('idDiplome')->toArray();

        // 4. Create the required Admin Personnel & User
        // Nom : Ahmed El Idrissi
        // Email : admin@test.local
        // Mot de passe : Admin123@
        $adminPersonnel = Personnel::create([
            'matricule' => 'ADM-001',
            'cin' => 'EE112233',
            'nom' => 'El Idrissi',
            'prenom' => 'Ahmed',
            'nom_prenom' => 'Ahmed El Idrissi',
            'type_personnel' => 'administratif',
            'statut' => 'permanent',
            'date_naissance' => '1980-05-12',
            'lieu_naissance' => 'Casablanca',
            'situation_familiale' => 'marié',
            'nombre_enfant' => 2,
            'adresse_actuelle' => 'Gauthier, Casablanca',
            'telephone' => '0661234567',
            'grade' => 'Directeur de Complexe',
            'echelon' => 'Exceptionnel',
            'fonction' => 'Directeur',
            'contact_nom' => 'Khadija El Idrissi',
            'contact_telephone' => '0669876543',
            'idEtab' => $etabIds[0], // ISTA NTIC Casablanca
            'idSpecialite' => $specIds['Administration des RH'] ?? null,
        ]);

        $adminUser = User::create([
            'username' => 'admin',
            'email' => 'admin@test.local',
            'password' => Hash::make('Admin123@'),
            'Role' => 'directeur du complexe',
            'idPersonnel' => $adminPersonnel->idPersonnel,
        ]);

        // 5. Create the required Manager Personnel & User
        // Nom : Youssef Benali
        // Email : manager@test.local
        // Mot de passe : Manager123@
        $managerPersonnel = Personnel::create([
            'matricule' => 'MGR-001',
            'cin' => 'FF445566',
            'nom' => 'Benali',
            'prenom' => 'Youssef',
            'nom_prenom' => 'Youssef Benali',
            'type_personnel' => 'administratif',
            'statut' => 'permanent',
            'date_naissance' => '1985-09-24',
            'lieu_naissance' => 'Rabat',
            'situation_familiale' => 'marié',
            'nombre_enfant' => 1,
            'adresse_actuelle' => 'Agdal, Rabat',
            'telephone' => '0662345678',
            'grade' => 'Chef de Service RH',
            'echelon' => 'Principal',
            'fonction' => 'Gestionnaire RH',
            'contact_nom' => 'Fatima Benali',
            'contact_telephone' => '0668765432',
            'idEtab' => $etabIds[1], // ISTA Agdal
            'idSpecialite' => $specIds['Administration des RH'] ?? null,
        ]);

        $managerUser = User::create([
            'username' => 'manager',
            'email' => 'manager@test.local',
            'password' => Hash::make('Manager123@'),
            'Role' => 'gestionnaire CFMR',
            'idPersonnel' => $managerPersonnel->idPersonnel,
        ]);

        // 6. Create 30 employees (20 formateurs, 10 administratifs)
        $moroccanNames = [
            ['nom' => 'Alami', 'prenom' => 'Karim'],
            ['nom' => 'Berrada', 'prenom' => 'Nadia'],
            ['nom' => 'Jahidi', 'prenom' => 'Soufiane'],
            ['nom' => 'El Mansouri', 'prenom' => 'Meryem'],
            ['nom' => 'Chraibi', 'prenom' => 'Anass'],
            ['nom' => 'Tazi', 'prenom' => 'Salma'],
            ['nom' => 'Amrani', 'prenom' => 'Mohamed'],
            ['nom' => 'Benjelloun', 'prenom' => 'Hind'],
            ['nom' => 'Kadiri', 'prenom' => 'Yassine'],
            ['nom' => 'Sabri', 'prenom' => 'Laila'],
            ['nom' => 'Filali', 'prenom' => 'Othmane'],
            ['nom' => 'Tahiri', 'prenom' => 'Meriem'],
            ['nom' => 'Malki', 'prenom' => 'Reda'],
            ['nom' => 'Ait Ali', 'prenom' => 'Fatima-Zahra'],
            ['nom' => 'Bennis', 'prenom' => 'Adnane'],
            ['nom' => 'Slaoui', 'prenom' => 'Kenza'],
            ['nom' => 'Naji', 'prenom' => 'Zakaria'],
            ['nom' => 'Idrissi', 'prenom' => 'Zineb'],
            ['nom' => 'Ouazzani', 'prenom' => 'Hamza'],
            ['nom' => 'Bouazzaoui', 'prenom' => 'Sanaa'],
            ['nom' => 'Rami', 'prenom' => 'Tariq'],
            ['nom' => 'Haddad', 'prenom' => 'Houda'],
            ['nom' => 'Alaoui', 'prenom' => 'Taha'],
            ['nom' => 'Belkhayat', 'prenom' => 'Sara'],
            ['nom' => 'Fassi', 'prenom' => 'Marouane'],
            ['nom' => 'Sadiki', 'prenom' => 'Bouchra'],
            ['nom' => 'Nassiri', 'prenom' => 'Khalid'],
            ['nom' => 'Yousfi', 'prenom' => 'Asmae'],
            ['nom' => 'Semlali', 'prenom' => 'Walid'],
            ['nom' => 'Kabbaj', 'prenom' => 'Imane'],
        ];

        $cities = ['Casablanca', 'Rabat', 'Tanger', 'Marrakech', 'Fes'];
        $grades = ['Junior', 'Senior', 'Principal', 'Chef de service', 'Hors Grade'];
        $situations = ['célibataire', 'marié', 'divorcé'];
        $specialtyNames = ['Développement Digital', 'Infrastructure Digitale', 'Gestion des Entreprises', 'Intelligence Artificielle'];

        $personnelsCreated = [];

        for ($i = 0; $i < 30; $i++) {
            $isFormateur = ($i < 20); // 20 formateurs, 10 administratifs
            $info = $moroccanNames[$i];
            
            $typePersonnel = $isFormateur ? 'formateur' : 'administratif';
            $statut = ($i % 3 === 0) ? 'vacataire' : 'permanent';
            
            $nom = $info['nom'];
            $prenom = $info['prenom'];
            $nomPrenom = $prenom . ' ' . $nom;
            
            $cinPrefix = chr(65 + ($i % 26)) . chr(65 + (($i + 3) % 26));
            $cin = $cinPrefix . str_pad($i * 12345, 6, '0', STR_PAD_LEFT);
            
            $matriculePrefix = $isFormateur ? 'FORM-' : 'ADM-';
            $matricule = $matriculePrefix . str_pad($i + 2, 3, '0', STR_PAD_LEFT);
            
            $phone = '06' . str_pad($i * 987654 + 60000000, 8, '0', STR_PAD_LEFT);
            $email = strtolower($prenom . '.' . $nom) . '@test.local';
            
            $etabId = $etabIds[$i % count($etabIds)];
            
            // Random origin specialty
            $originSpec = $isFormateur ? $specIds[$specialtyNames[$i % count($specialtyNames)]] : $specIds['Administration des RH'];
            
            $birthYear = 1975 + ($i % 25);
            $birthMonth = str_pad(($i % 12) + 1, 2, '0', STR_PAD_LEFT);
            $birthDay = str_pad(($i % 28) + 1, 2, '0', STR_PAD_LEFT);
            
            $p = Personnel::create([
                'matricule' => $matricule,
                'cin' => $cin,
                'nom' => $nom,
                'prenom' => $prenom,
                'nom_prenom' => $nomPrenom,
                'type_personnel' => $typePersonnel,
                'statut' => $statut,
                'date_naissance' => "$birthYear-$birthMonth-$birthDay",
                'lieu_naissance' => $cities[$i % count($cities)],
                'situation_familiale' => $situations[$i % count($situations)],
                'nombre_enfant' => ($i % 3 === 0) ? 0 : ($i % 3),
                'adresse_actuelle' => 'Rue ' . ($i + 10) . ', ' . $cities[$i % count($cities)],
                'telephone' => $phone,
                'grade' => $grades[$i % count($grades)],
                'echelon' => ($i % 10) + 1,
                'fonction' => $isFormateur ? 'Formateur d\'Informatique' : 'Agent Administratif',
                'contact_nom' => $moroccanNames[(30 - $i - 1)]['prenom'] . ' ' . $moroccanNames[(30 - $i - 1)]['nom'],
                'contact_telephone' => '06' . str_pad(($i + 5) * 876543 + 60000000, 8, '0', STR_PAD_LEFT),
                'creneaux' => $isFormateur ? [
                    'Lundi' => ['8:30-13:00', '14:00-18:30'],
                    'Mardi' => ['8:30-13:00'],
                    'Mercredi' => ['14:00-18:30'],
                ] : null,
                'type' => $typePersonnel,
                'idEtab' => $etabId,
                'idSpecialite' => $originSpec,
            ]);

            // Sync random diplomes (1 or 2 per personnel)
            $p->diplomes()->sync([
                $diplomeIds[$i % count($diplomeIds)],
                $diplomeIds[($i + 2) % count($diplomeIds)]
            ]);

            // If formateur, sync enseignee specialities
            if ($isFormateur) {
                $p->specialites()->sync([
                    $specIds[$specialtyNames[$i % count($specialtyNames)]],
                    $specIds[$specialtyNames[($i + 1) % count($specialtyNames)]]
                ]);
            }

            $personnelsCreated[] = $p;
        }

        // 7. Seed Conges (leaves)
        $congeTypes = ['annuel', 'maladie', 'maternité', 'exceptionnel', 'sans_solde'];
        $congeStatuses = ['en_attente', 'approuvé', 'refusé'];
        
        // Let's create about 15 leaves
        for ($k = 0; $k < 15; $k++) {
            $p = $personnelsCreated[$k * 2]; // even index personnels
            
            $startDay = ($k % 20) + 1;
            $startMonth = '06';
            $startDateStr = "2026-$startMonth-" . str_pad($startDay, 2, '0', STR_PAD_LEFT);
            
            $endDay = $startDay + ($k % 10) + 1;
            $endDateStr = "2026-$startMonth-" . str_pad($endDay, 2, '0', STR_PAD_LEFT);
            
            Conge::create([
                'idPersonnel' => $p->idPersonnel,
                'date_debut' => $startDateStr,
                'date_fin' => $endDateStr,
                'date_demande' => "2026-05-" . str_pad(($k % 25) + 1, 2, '0', STR_PAD_LEFT),
                'type_conge' => $congeTypes[$k % count($congeTypes)],
                'statut' => $congeStatuses[$k % count($congeStatuses)],
            ]);
        }

        // 8. Seed Absences
        $absenceMotifs = ['maladie', 'absence injustifiée', 'personnel', 'retard'];
        // Let's create about 20 absences
        for ($m = 0; $m < 20; $m++) {
            $p = $personnelsCreated[$m % count($personnelsCreated)];
            
            $day = ($m % 28) + 1;
            $month = ($m % 2 === 0) ? '04' : '05';
            
            Absence::create([
                'idPersonnel' => $p->idPersonnel,
                'date_absence' => "2026-$month-" . str_pad($day, 2, '0', STR_PAD_LEFT),
                'motif' => $absenceMotifs[$m % count($absenceMotifs)],
            ]);
        }

        // 9. Seed Seances (weekly timetable sessions)
        $modules = [
            'Développement Digital' => ['Développement Front-end', 'Programmation JavaScript', 'Conception Web', 'Base de Données'],
            'Infrastructure Digitale' => ['Réseaux Informatiques', 'Administration Linux', 'Sécurité Informatique', 'Cloud Computing'],
            'Gestion des Entreprises' => ['Comptabilité Générale', 'Marketing Digital', 'Management RH', 'Droit des Affaires'],
            'Intelligence Artificielle' => ['Python pour l\'IA', 'Machine Learning', 'Deep Learning', 'Data Visualisation']
        ];
        
        $salles = ['Salle A1', 'Salle A2', 'Salle B1', 'Lab Informatique 1', 'Lab Réseaux', 'Amphi B'];
        
        // Seed seances for 10 formateurs
        for ($s = 0; $s < 10; $s++) {
            $p = $personnelsCreated[$s]; // Formateurs
            
            $specName = $specialtyNames[$s % count($specialtyNames)];
            $modList = $modules[$specName];
            
            // Map specialty to safe ASCII prefixes
            $specPrefix = 'DD';
            if ($specName === 'Infrastructure Digitale') {
                $specPrefix = 'ID';
            } elseif ($specName === 'Gestion des Entreprises') {
                $specPrefix = 'GE';
            } elseif ($specName === 'Intelligence Artificielle') {
                $specPrefix = 'IA';
            }
            
            // Generate 3 seances per formateur
            for ($x = 0; $x < 3; $x++) {
                $day = ($x * 2 + 1); // 1, 3, 5
                
                $startTimes = ['08:30:00', '10:30:00', '14:00:00'];
                $endTimes = ['10:30:00', '12:30:00', '16:00:00'];
                
                Seance::create([
                    'idPersonnel' => $p->idPersonnel,
                    'matricule' => $p->matricule,
                    'full_name' => $p->nom_prenom,
                    'jour' => $day,
                    'heure_debut' => $startTimes[$x],
                    'heure_fin' => $endTimes[$x],
                    'module' => $modList[$x % count($modList)],
                    'salle' => $salles[($s + $x) % count($salles)],
                    'groupe' => $specPrefix . ($s * 10 + 100 + $x),
                    'etablissement' => Etablissement::find($p->idEtab)->nom,
                    'date' => '2026-05-' . (25 + $day), // A mock date matching that day of the week in May 2026
                    'type' => 'cours',
                ]);
            }
        }
        
        echo "DatabaseDemoSeeder completed successfully!" . PHP_EOL;
    }
}
