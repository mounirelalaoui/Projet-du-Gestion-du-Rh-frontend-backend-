# ProjectAutomation

Application PowerShell modulaire pour Windows 10/11 qui automatise :

- l'analyse d'un projet full-stack
- la détection de stack et frameworks
- l'inventaire frontend/backend
- l'identification des artefacts générés
- l'export d'une version nettoyée du code source
- la génération d'un rapport Markdown et JSON
- la création d'un ZIP prêt à partager

## Structure

```text
tools/ProjectAutomation/
  Config/ProjectAutomation.Config.psd1
  Private/
    Common.ps1
    Analysis.ps1
    Export.ps1
    Report.ps1
  ProjectAutomation.psm1
  Invoke-ProjectAutomation.ps1
  README.md
```

## Stacks supportées

- React
- Next.js
- Vue
- Angular
- Node.js
- Express
- NestJS
- Laravel
- Django
- Spring Boot
- PHP natif
- TypeScript
- Python

Les détections sont heuristiques : l'outil inspecte les manifests (`package.json`, `composer.json`, `requirements.txt`, `pom.xml`, etc.), les dépendances et la structure du code.

## Usage

Depuis la racine du dépôt :

```powershell
pwsh -File .\tools\ProjectAutomation\Invoke-ProjectAutomation.ps1 -SourcePath .
```

Avec un dossier de sortie explicite :

```powershell
pwsh -File .\tools\ProjectAutomation\Invoke-ProjectAutomation.ps1 `
  -SourcePath . `
  -OutputPath .\artifacts\project-automation\latest
```

Analyse sans export :

```powershell
pwsh -File .\tools\ProjectAutomation\Invoke-ProjectAutomation.ps1 `
  -SourcePath . `
  -SkipExport
```

Nettoyage destructif "in place" en plus de l'analyse :

```powershell
pwsh -File .\tools\ProjectAutomation\Invoke-ProjectAutomation.ps1 `
  -SourcePath . `
  -EnableInPlaceCleanup
```

## Sorties

L'outil génère dans le dossier de sortie :

- `project-report.md`
- `project-report.json`
- `cleaned_project_source/`
- `cleaned_project_source.zip`

## Principes de nettoyage

Exclusion automatique des artefacts courants :

- `node_modules`
- `vendor`
- `dist`
- `build`
- `.next`
- `coverage`
- `.cache`
- logs et fichiers temporaires
- dossiers IDE et workspace non essentiels

Conservation intelligente basée sur la stack détectée :

- `src`, `app`, `routes`, `config`, `database`, `public`, `resources`, `tests`
- fichiers critiques comme `package.json`, `composer.json`, `README.md`, `vite.config.*`, `next.config.*`, `tsconfig.json`
- génération de `.env.example` si seul `.env` existe

## Notes

- Le mode par défaut est sûr : il produit un export nettoyé sans modifier le dépôt source.
- Le nettoyage sur place doit être utilisé avec précaution.
- Le rapport signale aussi des incohérences fréquentes : lockfiles manquants, `.env.example` absent, vues Laravel manquantes, manifests vides, répertoires suspects.
