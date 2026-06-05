# Project Automation Report

- Generated at: 2026-05-20 22:43:28
- Source path: `C:\xampp\htdocs\Projet-du-Gestion-du-Rh`
- Workspace size: 1.22 MB
- Detected project roots: 2
- Frameworks: Laravel, Node, PHP, React, Vite
- Languages: CSS, HTML, JavaScript, PHP, Python
- Package managers: composer, npm

## Summary

- Total issues: 21
- High severity issues: 1
- Medium severity issues: 3
- Critical files tracked: 17
- Environment files tracked: 2

## Frontend Analysis

- `ofppt-rh-frontend` -> Node, React, Vite
  - Components: 24, Hooks: 3, Services: 10, Routes: 2
  - Managers: composer, npm

## Backend Analysis

- `.` -> Laravel, PHP
  - Controllers: 21, Models: 8, Services: 1, Routes/APIs: 4/1
  - Managers: composer
- `ofppt-rh-frontend` -> Node, React, Vite
  - Controllers: 0, Models: 0, Services: 10, Routes/APIs: 2/0
  - Managers: composer, npm

## Detected Issues

- [High] Route references missing Blade view "welcome". (`routes\web.php`)
- [Info] Detected removable directory: .postman (`.postman`)
- [Info] Detected removable directory: .qodo (`.qodo`)
- [Info] Detected removable directory: artifacts (`artifacts`)
- [Info] Detected removable directory: cleaned_project_source (`cleaned_project_source`)
- [Info] Detected removable directory: docs (`docs`)
- [Info] Detected removable directory: postman (`postman`)
- [Low] Detected removable directory: .git (`.git`)
- [Low] Detected removable directory: .vscode (`.vscode`)
- [Low] Detected removable directory: bootstrap\cache (`bootstrap\cache`)
- [Low] Detected removable directory: ofppt-rh-frontend\.git (`ofppt-rh-frontend\.git`)
- [Low] Detected removable directory: ofppt-rh-frontend\dist (`ofppt-rh-frontend\dist`)
- [Low] Detected removable directory: ofppt-rh-frontend\node_modules (`ofppt-rh-frontend\node_modules`)
- [Low] Detected removable directory: storage\framework\cache (`storage\framework\cache`)
- [Low] Detected removable directory: storage\logs (`storage\logs`)
- [Low] Detected removable directory: vendor (`vendor`)
- [Low] Detected removable file: .phpunit.result.cache (`.phpunit.result.cache`)
- [Low] Detected removable file: cleaned_project_source.zip (`cleaned_project_source.zip`)
- [Medium] A .env file exists without a matching .env.example template. (`.env`)
- [Medium] A .env file exists without a matching .env.example template. (`ofppt-rh-frontend\.env`)
- [Medium] composer.json references npm commands in a directory without package.json while a nested frontend project exists. (`composer.json`)

## Dependencies

- `.`
  - PHP: fakerphp/faker, laravel/breeze, laravel/framework, laravel/pail, laravel/pint, laravel/sail, laravel/sanctum, laravel/tinker, maatwebsite/excel, mockery/mockery, mpdf/mpdf, nunomaduro/collision, php, phpunit/phpunit
- `ofppt-rh-frontend`
  - JavaScript: @emailjs/browser, @eslint/js, @tailwindcss/vite, @types/node, @types/react, @types/react-dom, @vitejs/plugin-react, autoprefixer, axios, babel-plugin-react-compiler, date-fns, eslint, eslint-plugin-react, eslint-plugin-react-hooks, exceljs

## Launch Commands

- `.`
  - Install PHP dependencies: `composer install`
  - Prepare environment: `Copy-Item .env.example .env`
  - Generate app key: `php artisan key:generate`
  - Run migrations: `php artisan migrate`
  - Start backend: `php artisan serve`
- `ofppt-rh-frontend`
  - Install JavaScript dependencies: `npm install`
  - Start development server: `npm run dev`

## Clean Export

- Cleaned source: `C:\xampp\htdocs\Projet-du-Gestion-du-Rh\artifacts\project-automation\20260520-224322\cleaned_project_source`
- ZIP: `C:\xampp\htdocs\Projet-du-Gestion-du-Rh\artifacts\project-automation\20260520-224322\cleaned_project_source.zip`
- Cleaned size: 1.14 MB
- Files copied: 222

```text
app/
  Exceptions/
    Handler.php
  Helpers/
    ApiResponse.php
  Http/
    Controllers/
      Auth/
      AbsenceController.php
      AuthController.php
      CongeController.php
      Controller.php
      DashboardController.php
      DiplomeController.php
      EmploiTempsController.php
      EtablissementController.php
      ImportEmploiController.php
      PersonnelController.php
      PlanningImportController.php
      ProfileController.php
      SeanceController.php
      SpecialiteController.php
      UserController.php
    Middleware/
      CheckRole.php
      CorsMiddleware.php
      EnsureEmailIsVerified.php
      RoleMiddleware.php
    Requests/
      StoreAbsenceRequest.php
      StoreCongeRequest.php
      StoreDiplomeRequest.php
      StoreEtablissementRequest.php
      StorePersonnelRequest.php
      StoreSpecialiteRequest.php
      StoreUserRequest.php
      UpdateAbsenceRequest.php
      UpdateCongeRequest.php
      UpdateDiplomeRequest.php
      UpdateEtablissementRequest.php
      UpdatePersonnelRequest.php
      UpdateSpecialiteRequest.php
      UpdateUserRequest.php
    Resources/
      AbsenceResource.php
      AdministratifResource.php
      CongeResource.php
      DiplomeResource.php
      EtablissementResource.php
      FormateurPermanentResource.php
      FormateurResource.php
      FormateurVacataireResource.php
      PersonnelResource.php
      SeanceResource.php
      SpecialiteResource.php
      UserResource.php
  Imports/
    EmploiTempsImport.php
  Models/
    Absence.php
    Conge.php
    Diplome.php
    Etablissement.php
    Personnel.php
    Seance.php
    Specialite.php
    User.php
  Providers/
    AppServiceProvider.php
  Traits/
    ApiResponds.php
bootstrap/
  cache/
    .gitignore
  app.php
  providers.php
config/
  app.php
  auth.php
  cache.php
  cors.php
  database.php
  excel.php
  filesystems.php
  logging.php
  mail.php
  queue.php
  sanctum.php
  services.php
  session.php
database/
  factories/
    UserFactory.php
  migrations/
    0001_01_01_000001_create_cache_table.php
    0001_01_01_000002_create_jobs_table.php
    2026_04_09_114128_create_etablissements_table.php
    2026_04_10_113955_create_specialites_table.php
    2026_04_11_004002_create_diplomes_table.php
    2026_04_11_004116_create_personnels_table.php
    2026_04_12_002824_create_users_table.php
    2026_04_12_002958_create_absences_table.php
    2026_04_12_113945_create_conges_table.php
    2026_04_13_114029_create_obtenir_table.php
    2026_04_13_114031_create_enseigner_table.php
    2026_04_15_082412_create_sessions_table.php
    2026_04_16_104242_create_personal_access_tokens_table.php
    2026_04_29_104428_add_matricule_and_creneaux_to_personnels_table.php
    2026_04_29_105626_make_personnel_fields_nullable_for_import.php
    2026_04_29_110004_fix_user_roles_enum.php
    2026_04_29_190724_create_seances_table.php
    2026_04_30_064302_update_seances_table_to_timetable_schema.php
  schema/
    mysql-schema.sql
  seeders/
    AbsenceSeeder.php
    AdminUserSeeder.php
    DatabaseSeeder.php
    EtablissementSeeder.php
    PersonnelSeeder.php
    UserSeeder.php
  .gitignore
ofppt-rh-frontend/
  public/
    vite.svg
  src/
    {assets/
      {images,icons},components/
    assets/
      react.svg
    components/
      common/
      layout/
      ui/
      AuthGuard.jsx
    context/
      AuthContext.jsx
      TimetableContext.jsx
    data/
    hooks/
      useAuth.js
      useDynamicFilters.js
      useFetch.js
    pages/
      Absences/
      Administratifs/
      Auth/
      Conges/
      Dashboard/
      Emploi/
      Formateurs/
      Personnel/
      Profile/
      Users/
    routes/
      AppRoutes.jsx
      ProtectedRoute.jsx
    services/
      api.js
      authService.js
      axiosInstance.js
      crudServices.js
      emailService.js
      ExcelService.js
      googleFormsService.js
      notificationStore.js
      pdfService.js
      scheduleService.js
    utils/
      constants.js
      helpers.js
    App.css
    App.jsx
    index.css
    main.jsx
  .env.example
  .gitignore
  eslint.config.js
  index.html
  package-lock.json
  package.json
  README.md
  vite.config.js
public/
  .htaccess
  favicon.ico
  index.php
  robots.txt
resources/
  views/
    .gitkeep
routes/
  api.php
  auth.php
  console.php
  web.php
services/
  password_service.py
storage/
  app/
    private/
      .gitignore
    public/
      .gitignore
    .gitignore
  framework/
    cache/
      data/
      .gitignore
    sessions/
      .gitignore
    testing/
      .gitignore
    views/
      .gitignore
    .gitignore
  logs/
    .gitignore
tests/
  Feature/
  Unit/
    ExampleTest.php
  TestCase.php
.editorconfig
.env.example
.gitattributes
.gitignore
artisan
composer.json
composer.lock
phpunit.xml
README.md
setup.ps1
setup.sh
```

