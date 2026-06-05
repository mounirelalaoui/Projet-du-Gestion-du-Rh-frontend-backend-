# Project Automation Report

- Generated at: 2026-05-20 22:43:52
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

