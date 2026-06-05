function ConvertFrom-JsonSafe {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        $raw = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($raw)) {
            return $null
        }

        $raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        $null
    }
}

function Get-DirectManifestMap {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootPath,
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )

    $map = @{}

    foreach ($manifest in $Config.ManifestFiles) {
        $candidate = Join-Path -Path $RootPath -ChildPath $manifest
        if (Test-Path -LiteralPath $candidate) {
            $map[$manifest] = $candidate
        }
    }

    $map
}

function Get-JavaScriptDependencies {
    param($PackageJson)

    if (-not $PackageJson) {
        return @()
    }

    $names = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($property in @('dependencies', 'devDependencies', 'peerDependencies')) {
        if ($PackageJson.PSObject.Properties.Name -contains $property) {
            foreach ($name in $PackageJson.$property.PSObject.Properties.Name) {
                [void]$names.Add($name)
            }
        }
    }

    @($names) | Sort-Object
}

function Get-ComposerDependencies {
    param($ComposerJson)

    if (-not $ComposerJson) {
        return @()
    }

    $names = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($property in @('require', 'require-dev')) {
        if ($ComposerJson.PSObject.Properties.Name -contains $property) {
            foreach ($name in $ComposerJson.$property.PSObject.Properties.Name) {
                [void]$names.Add($name)
            }
        }
    }

    @($names) | Sort-Object
}

function Get-PythonDependencies {
    param(
        [string]$RequirementsPath,
        [string]$PyprojectPath
    )

    $names = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)

    if ($RequirementsPath -and (Test-Path -LiteralPath $RequirementsPath)) {
        $lines = Get-Content -LiteralPath $RequirementsPath -ErrorAction SilentlyContinue
        foreach ($line in $lines) {
            $trimmed = $line.Trim()
            if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith('#')) {
                continue
            }

            $name = ($trimmed -split '[<>=~!\[]', 2)[0].Trim()
            if (-not [string]::IsNullOrWhiteSpace($name)) {
                [void]$names.Add($name)
            }
        }
    }

    if ($PyprojectPath -and (Test-Path -LiteralPath $PyprojectPath)) {
        $content = Get-Content -LiteralPath $PyprojectPath -Raw -ErrorAction SilentlyContinue
        $matches = [regex]::Matches($content, '([A-Za-z0-9_.-]+)\s*=')
        foreach ($match in $matches) {
            $candidate = $match.Groups[1].Value
            if ($candidate -notmatch '^(project|tool|build-system|name|version|description|authors|dependencies)$') {
                continue
            }
        }
    }

    @($names) | Sort-Object
}

function Get-JavaDependencies {
    param(
        [string]$PomPath,
        [string]$GradlePath
    )

    $names = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)

    if ($PomPath -and (Test-Path -LiteralPath $PomPath)) {
        try {
            [xml]$pom = Get-Content -LiteralPath $PomPath -Raw -ErrorAction Stop
            $artifactNodes = $pom.SelectNodes('//*[local-name()="dependency"]/*[local-name()="artifactId"]')
            foreach ($node in $artifactNodes) {
                if ($node.InnerText) {
                    [void]$names.Add($node.InnerText)
                }
            }
        }
        catch {
        }
    }

    if ($GradlePath -and (Test-Path -LiteralPath $GradlePath)) {
        $content = Get-Content -LiteralPath $GradlePath -Raw -ErrorAction SilentlyContinue
        $matches = [regex]::Matches($content, '["'']([A-Za-z0-9_.-]+):([A-Za-z0-9_.-]+):([A-Za-z0-9_.-]+)["'']')
        foreach ($match in $matches) {
            [void]$names.Add($match.Groups[2].Value)
        }
    }

    @($names) | Sort-Object
}

function Get-ProjectDependencies {
    param(
        [hashtable]$ManifestMap,
        $PackageJson,
        $ComposerJson
    )

    $dependencies = [ordered]@{
        JavaScript = @(Get-JavaScriptDependencies -PackageJson $PackageJson)
        PHP        = @(Get-ComposerDependencies -ComposerJson $ComposerJson)
        Python     = @(Get-PythonDependencies -RequirementsPath $ManifestMap['requirements.txt'] -PyprojectPath $ManifestMap['pyproject.toml'])
        Java       = @(Get-JavaDependencies -PomPath $ManifestMap['pom.xml'] -GradlePath $ManifestMap['build.gradle'])
    }

    [pscustomobject]$dependencies
}

function Get-FrameworksForProject {
    param(
        [hashtable]$ManifestMap,
        $PackageJson,
        $ComposerJson,
        [string[]]$FileRelativePaths
    )

    $frameworks = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    $jsDependencies = Get-JavaScriptDependencies -PackageJson $PackageJson
    $phpDependencies = Get-ComposerDependencies -ComposerJson $ComposerJson

    if ($ManifestMap.ContainsKey('package.json')) {
        [void]$frameworks.Add('Node')
    }

    if ($jsDependencies -contains 'react') {
        [void]$frameworks.Add('React')
    }

    if (($jsDependencies -contains 'next') -or $ManifestMap.Keys -contains 'next.config.js' -or $ManifestMap.Keys -contains 'next.config.ts' -or $ManifestMap.Keys -contains 'next.config.mjs') {
        [void]$frameworks.Add('NextJs')
        [void]$frameworks.Add('React')
    }

    if ($jsDependencies -contains 'vue') {
        [void]$frameworks.Add('Vue')
    }

    if (($jsDependencies -contains '@angular/core') -or $ManifestMap.Keys -contains 'angular.json') {
        [void]$frameworks.Add('Angular')
    }

    if ($jsDependencies -contains 'express') {
        [void]$frameworks.Add('Express')
        [void]$frameworks.Add('Node')
    }

    if (($jsDependencies -contains '@nestjs/core') -or $ManifestMap.Keys -contains 'nest-cli.json') {
        [void]$frameworks.Add('NestJS')
        [void]$frameworks.Add('Node')
    }

    $hasPhpFiles = @($FileRelativePaths | Where-Object { $_ -like '*.php' }).Count -gt 0
    $hasMeaningfulComposerManifest = $ManifestMap.Keys -contains 'composer.json' -and $ComposerJson -and $ComposerJson.PSObject.Properties.Count -gt 0

    if (($phpDependencies -contains 'laravel/framework') -or $ManifestMap.Keys -contains 'artisan') {
        [void]$frameworks.Add('Laravel')
        [void]$frameworks.Add('PHP')
    }
    elseif ($hasMeaningfulComposerManifest -or $hasPhpFiles) {
        [void]$frameworks.Add('PHP')
        [void]$frameworks.Add('PHPNative')
    }

    $requirementsText = ''
    if ($ManifestMap.ContainsKey('requirements.txt')) {
        $requirementsText = Get-Content -LiteralPath $ManifestMap['requirements.txt'] -Raw -ErrorAction SilentlyContinue
    }

    $pyprojectText = ''
    if ($ManifestMap.ContainsKey('pyproject.toml')) {
        $pyprojectText = Get-Content -LiteralPath $ManifestMap['pyproject.toml'] -Raw -ErrorAction SilentlyContinue
    }

    if (($ManifestMap.Keys -contains 'manage.py') -or ($requirementsText -match '(?im)^\s*django') -or ($pyprojectText -match '(?i)django')) {
        [void]$frameworks.Add('Django')
        [void]$frameworks.Add('Python')
    }
    elseif ($ManifestMap.Keys -contains 'requirements.txt' -or $ManifestMap.Keys -contains 'pyproject.toml' -or $ManifestMap.Keys -contains 'Pipfile') {
        [void]$frameworks.Add('Python')
    }

    $javaText = ''
    foreach ($manifestName in @('pom.xml', 'build.gradle', 'build.gradle.kts')) {
        if ($ManifestMap.ContainsKey($manifestName)) {
            $javaText += (Get-Content -LiteralPath $ManifestMap[$manifestName] -Raw -ErrorAction SilentlyContinue) + "`n"
        }
    }

    if ($javaText -match '(?i)spring-boot') {
        [void]$frameworks.Add('SpringBoot')
        [void]$frameworks.Add('Java')
    }
    elseif ($ManifestMap.Keys -contains 'pom.xml' -or $ManifestMap.Keys -contains 'build.gradle' -or $ManifestMap.Keys -contains 'build.gradle.kts') {
        [void]$frameworks.Add('Java')
    }

    if (($ManifestMap.Keys -contains 'tsconfig.json') -or ($jsDependencies -contains 'typescript')) {
        [void]$frameworks.Add('TypeScript')
    }

    if ($ManifestMap.Keys -contains 'vite.config.js' -or $ManifestMap.Keys -contains 'vite.config.ts' -or $ManifestMap.Keys -contains 'vite.config.mjs') {
        [void]$frameworks.Add('Vite')
    }

    @($frameworks) | Sort-Object
}

function Get-LanguagesForProject {
    param(
        [string[]]$FileRelativePaths,
        [string[]]$Frameworks
    )

    $languages = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    $extensionMap = @{
        '.php'  = 'PHP'
        '.js'   = 'JavaScript'
        '.jsx'  = 'JavaScript'
        '.ts'   = 'TypeScript'
        '.tsx'  = 'TypeScript'
        '.py'   = 'Python'
        '.java' = 'Java'
        '.vue'  = 'Vue'
        '.html' = 'HTML'
        '.css'  = 'CSS'
        '.scss' = 'CSS'
    }

    foreach ($file in $FileRelativePaths) {
        $extension = [System.IO.Path]::GetExtension($file)
        if ($extensionMap.ContainsKey($extension)) {
            [void]$languages.Add($extensionMap[$extension])
        }
    }

    foreach ($framework in $Frameworks) {
        switch ($framework) {
            'Laravel'     { [void]$languages.Add('PHP') }
            'React'       { [void]$languages.Add('JavaScript') }
            'NextJs'      { [void]$languages.Add('JavaScript') }
            'Vue'         { [void]$languages.Add('JavaScript') }
            'Angular'     { [void]$languages.Add('TypeScript') }
            'NestJS'      { [void]$languages.Add('TypeScript') }
            'Django'      { [void]$languages.Add('Python') }
            'SpringBoot'  { [void]$languages.Add('Java') }
            'TypeScript'  { [void]$languages.Add('TypeScript') }
        }
    }

    @($languages) | Sort-Object
}

function Get-PackageManagersForProject {
    param(
        [hashtable]$ManifestMap,
        $ComposerJson,
        [string[]]$FileRelativePaths
    )

    $managers = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)

    if ($ManifestMap.ContainsKey('package.json')) {
        if (Test-Path -LiteralPath (Join-Path -Path (Split-Path -Parent $ManifestMap['package.json']) -ChildPath 'package-lock.json')) {
            [void]$managers.Add('npm')
        }
        if (Test-Path -LiteralPath (Join-Path -Path (Split-Path -Parent $ManifestMap['package.json']) -ChildPath 'yarn.lock')) {
            [void]$managers.Add('yarn')
        }
        if (Test-Path -LiteralPath (Join-Path -Path (Split-Path -Parent $ManifestMap['package.json']) -ChildPath 'pnpm-lock.yaml')) {
            [void]$managers.Add('pnpm')
        }
        if ($managers.Count -eq 0) {
            [void]$managers.Add('npm')
        }
    }

    $hasPhpFiles = @($FileRelativePaths | Where-Object { $_ -like '*.php' }).Count -gt 0
    $hasMeaningfulComposerManifest = $ManifestMap.ContainsKey('composer.json') -and $ComposerJson -and $ComposerJson.PSObject.Properties.Count -gt 0

    if ($hasMeaningfulComposerManifest -or $hasPhpFiles) {
        [void]$managers.Add('composer')
    }

    if ($ManifestMap.ContainsKey('requirements.txt') -or $ManifestMap.ContainsKey('manage.py') -or $ManifestMap.ContainsKey('Pipfile') -or $ManifestMap.ContainsKey('pyproject.toml')) {
        [void]$managers.Add('pip')
    }

    @($managers) | Sort-Object
}

function Get-ProjectRole {
    param(
        [string[]]$Frameworks
    )

    $frontendFrameworks = @('React', 'NextJs', 'Vue', 'Angular')
    $backendFrameworks = @('Express', 'NestJS', 'Laravel', 'Django', 'SpringBoot', 'PHP', 'PHPNative', 'Python')

    $hasFrontend = $false
    foreach ($framework in $frontendFrameworks) {
        if ($Frameworks -contains $framework) {
            $hasFrontend = $true
            break
        }
    }

    $hasBackend = $false
    foreach ($framework in $backendFrameworks) {
        if ($Frameworks -contains $framework) {
            $hasBackend = $true
            break
        }
    }

    $hasStandaloneNodeBackend = ($Frameworks -contains 'Node') -and -not $hasFrontend

    if ($hasFrontend -and $hasBackend) { return 'FullStack' }
    if ($hasFrontend) { return 'Frontend' }
    if ($hasBackend -or $hasStandaloneNodeBackend) { return 'Backend' }
    'Unknown'
}

function Get-LaunchCommands {
    param(
        [string]$RootPath,
        [string[]]$Frameworks,
        [hashtable]$ManifestMap,
        $PackageJson
    )

    $commands = New-Object 'System.Collections.Generic.List[object]'
    $relativeRoot = ''

    try {
        $relativeRoot = Get-RelativePath -BasePath (Split-Path -Parent $RootPath) -TargetPath $RootPath
    }
    catch {
        $relativeRoot = '.'
    }

    if ($Frameworks -contains 'Laravel') {
        $commands.Add([pscustomobject]@{ Step = 'Install PHP dependencies'; Command = 'composer install' })
        $commands.Add([pscustomobject]@{ Step = 'Prepare environment'; Command = 'Copy-Item .env.example .env' })
        $commands.Add([pscustomobject]@{ Step = 'Generate app key'; Command = 'php artisan key:generate' })
        $commands.Add([pscustomobject]@{ Step = 'Run migrations'; Command = 'php artisan migrate' })
        $commands.Add([pscustomobject]@{ Step = 'Start backend'; Command = 'php artisan serve' })
    }
    elseif ($Frameworks -contains 'PHPNative') {
        $commands.Add([pscustomobject]@{ Step = 'Install PHP dependencies'; Command = 'composer install' })
    }

    if ($Frameworks -contains 'React' -or $Frameworks -contains 'Vue' -or $Frameworks -contains 'Angular' -or $Frameworks -contains 'NextJs' -or $Frameworks -contains 'Node' -or $Frameworks -contains 'NestJS') {
        $installCommand = 'npm install'
        if (Test-Path -LiteralPath (Join-Path -Path $RootPath -ChildPath 'yarn.lock')) {
            $installCommand = 'yarn install'
        }
        elseif (Test-Path -LiteralPath (Join-Path -Path $RootPath -ChildPath 'pnpm-lock.yaml')) {
            $installCommand = 'pnpm install'
        }

        $commands.Add([pscustomobject]@{ Step = 'Install JavaScript dependencies'; Command = $installCommand })

        if ($PackageJson -and $PackageJson.PSObject.Properties.Name -contains 'scripts') {
            $scriptNames = $PackageJson.scripts.PSObject.Properties.Name

            if ($scriptNames -contains 'dev') {
                $commands.Add([pscustomobject]@{ Step = 'Start development server'; Command = (($installCommand -split ' ')[0] + ' run dev') })
            }
            elseif ($scriptNames -contains 'start:dev') {
                $commands.Add([pscustomobject]@{ Step = 'Start development server'; Command = (($installCommand -split ' ')[0] + ' run start:dev') })
            }
            elseif ($scriptNames -contains 'start') {
                $commands.Add([pscustomobject]@{ Step = 'Start application'; Command = (($installCommand -split ' ')[0] + ' run start') })
            }
        }
    }

    if ($Frameworks -contains 'Django') {
        $commands.Add([pscustomobject]@{ Step = 'Install Python dependencies'; Command = 'pip install -r requirements.txt' })
        $commands.Add([pscustomobject]@{ Step = 'Run development server'; Command = 'python manage.py runserver' })
    }
    elseif ($Frameworks -contains 'Python') {
        $commands.Add([pscustomobject]@{ Step = 'Install Python dependencies'; Command = 'pip install -r requirements.txt' })
    }

    if ($Frameworks -contains 'SpringBoot') {
        if (Test-Path -LiteralPath (Join-Path -Path $RootPath -ChildPath 'mvnw.cmd')) {
            $commands.Add([pscustomobject]@{ Step = 'Run Spring Boot'; Command = '.\mvnw.cmd spring-boot:run' })
        }
        elseif (Test-Path -LiteralPath (Join-Path -Path $RootPath -ChildPath 'gradlew.bat')) {
            $commands.Add([pscustomobject]@{ Step = 'Run Spring Boot'; Command = '.\gradlew.bat bootRun' })
        }
        else {
            $commands.Add([pscustomobject]@{ Step = 'Run Spring Boot'; Command = 'mvn spring-boot:run' })
        }
    }

    $commands
}

function Get-CategoryMatches {
    param(
        [string[]]$RelativeFiles,
        [hashtable]$Config
    )

    $result = [ordered]@{}

    foreach ($category in $Config.CategoryPatterns.Keys) {
        $categoryItems = New-Object 'System.Collections.Generic.List[string]'
        foreach ($file in $RelativeFiles) {
            foreach ($pattern in $Config.CategoryPatterns[$category]) {
                if ($file -match $pattern) {
                    [void]$categoryItems.Add([string]$file)
                    break
                }
            }
        }

        $unique = $categoryItems | Sort-Object -Unique
        $result[$category] = [pscustomobject]@{
            Count  = @($unique).Count
            Sample = @($unique | Select-Object -First 20)
        }
    }

    [pscustomobject]$result
}

function Get-CriticalFilesForProject {
    param(
        [string]$RootPath,
        [string[]]$Frameworks,
        [hashtable]$Config
    )

    $relativeFiles = New-Object 'System.Collections.Generic.List[string]'
    $directFiles = Get-ChildItem -LiteralPath $RootPath -File -Force -ErrorAction SilentlyContinue

    foreach ($name in $Config.RootFiles.Common) {
        $candidate = Join-Path -Path $RootPath -ChildPath $name
        if (Test-Path -LiteralPath $candidate) {
            $relativeFiles.Add($name)
        }
    }

    foreach ($framework in $Frameworks) {
        switch ($framework) {
            'React' {
                foreach ($name in $Config.RootFiles.JavaScript) {
                    $candidate = Join-Path -Path $RootPath -ChildPath $name
                    if (Test-Path -LiteralPath $candidate) {
                        $relativeFiles.Add($name)
                    }
                }
            }
            'NextJs' {
                foreach ($name in $Config.RootFiles.JavaScript) {
                    $candidate = Join-Path -Path $RootPath -ChildPath $name
                    if (Test-Path -LiteralPath $candidate) {
                        $relativeFiles.Add($name)
                    }
                }
            }
            'Vue' {
                foreach ($name in $Config.RootFiles.JavaScript) {
                    $candidate = Join-Path -Path $RootPath -ChildPath $name
                    if (Test-Path -LiteralPath $candidate) {
                        $relativeFiles.Add($name)
                    }
                }
            }
            'Angular' {
                foreach ($name in $Config.RootFiles.JavaScript) {
                    $candidate = Join-Path -Path $RootPath -ChildPath $name
                    if (Test-Path -LiteralPath $candidate) {
                        $relativeFiles.Add($name)
                    }
                }
            }
            'NestJS' {
                foreach ($name in $Config.RootFiles.JavaScript) {
                    $candidate = Join-Path -Path $RootPath -ChildPath $name
                    if (Test-Path -LiteralPath $candidate) {
                        $relativeFiles.Add($name)
                    }
                }
            }
            'Node' {
                foreach ($name in $Config.RootFiles.JavaScript) {
                    $candidate = Join-Path -Path $RootPath -ChildPath $name
                    if (Test-Path -LiteralPath $candidate) {
                        $relativeFiles.Add($name)
                    }
                }
            }
            'Laravel' {
                foreach ($name in $Config.RootFiles.PHP) {
                    $candidate = Join-Path -Path $RootPath -ChildPath $name
                    if (Test-Path -LiteralPath $candidate) {
                        $relativeFiles.Add($name)
                    }
                }
            }
            'PHPNative' {
                foreach ($name in $Config.RootFiles.PHP) {
                    $candidate = Join-Path -Path $RootPath -ChildPath $name
                    if (Test-Path -LiteralPath $candidate) {
                        $relativeFiles.Add($name)
                    }
                }
            }
            'Django' {
                foreach ($name in $Config.RootFiles.Python) {
                    $candidate = Join-Path -Path $RootPath -ChildPath $name
                    if (Test-Path -LiteralPath $candidate) {
                        $relativeFiles.Add($name)
                    }
                }
            }
            'Python' {
                foreach ($name in $Config.RootFiles.Python) {
                    $candidate = Join-Path -Path $RootPath -ChildPath $name
                    if (Test-Path -LiteralPath $candidate) {
                        $relativeFiles.Add($name)
                    }
                }
            }
            'SpringBoot' {
                foreach ($name in $Config.RootFiles.Java) {
                    $candidate = Join-Path -Path $RootPath -ChildPath $name
                    if (Test-Path -LiteralPath $candidate) {
                        $relativeFiles.Add($name)
                    }
                }
            }
        }
    }

    $relativeFiles | Sort-Object -Unique
}

function Get-KeepDirectoriesForProject {
    param(
        [string]$RootPath,
        [string[]]$Frameworks,
        [hashtable]$Config
    )

    $candidates = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($name in $Config.KeepDirectories.Common) {
        [void]$candidates.Add($name)
    }

    foreach ($framework in $Frameworks) {
        if ($Config.KeepDirectories.ContainsKey($framework)) {
            foreach ($name in $Config.KeepDirectories[$framework]) {
                [void]$candidates.Add($name)
            }
        }
    }

    $result = New-Object 'System.Collections.Generic.List[string]'
    foreach ($name in (@($candidates) | Sort-Object)) {
        $candidate = Join-Path -Path $RootPath -ChildPath $name
        if (Test-Path -LiteralPath $candidate) {
            $result.Add($name)
        }
    }

    $result
}

function Get-ProjectIssues {
    param(
        [string]$WorkspaceRoot,
        [string]$RootPath,
        [string]$RelativeRoot,
        [string[]]$Frameworks,
        [hashtable]$ManifestMap,
        $PackageJson,
        $ComposerJson,
        [string[]]$AllProjectRoots,
        [string[]]$RelativeFiles
    )

    $issues = New-Object 'System.Collections.Generic.List[object]'
    $projectLabel = if ([string]::IsNullOrWhiteSpace($RelativeRoot) -or $RelativeRoot -eq '.') { '.' } else { $RelativeRoot }

    $envPath = Join-Path -Path $RootPath -ChildPath '.env'
    $envExamplePath = Join-Path -Path $RootPath -ChildPath '.env.example'
    if ((Test-Path -LiteralPath $envPath) -and -not (Test-Path -LiteralPath $envExamplePath)) {
        $issues.Add((New-IssueRecord -Severity 'Medium' -Code 'MissingEnvExample' -Message 'A .env file exists without a matching .env.example template.' -Path (Get-RelativePath -BasePath $WorkspaceRoot -TargetPath $envPath) -Project $projectLabel))
    }

    if ($ManifestMap.ContainsKey('package.json')) {
        $lockfiles = @('package-lock.json', 'yarn.lock', 'pnpm-lock.yaml') | Where-Object {
            Test-Path -LiteralPath (Join-Path -Path $RootPath -ChildPath $_)
        }

        if (@($lockfiles).Count -eq 0) {
            $issues.Add((New-IssueRecord -Severity 'Medium' -Code 'MissingJavaScriptLockfile' -Message 'package.json is present but no lockfile was found (package-lock.json, yarn.lock or pnpm-lock.yaml).' -Path $projectLabel -Project $projectLabel))
        }

        if (@($lockfiles).Count -gt 1) {
            $issues.Add((New-IssueRecord -Severity 'Low' -Code 'MultipleJavaScriptLockfiles' -Message ('Multiple JavaScript lockfiles were detected: ' + (@($lockfiles) -join ', ') + '.') -Path $projectLabel -Project $projectLabel))
        }
    }

    if ($ManifestMap.ContainsKey('composer.json') -and -not (Test-Path -LiteralPath (Join-Path -Path $RootPath -ChildPath 'composer.lock'))) {
        $issues.Add((New-IssueRecord -Severity 'Medium' -Code 'MissingComposerLock' -Message 'composer.json is present without composer.lock.' -Path $projectLabel -Project $projectLabel))
    }

    if ($ManifestMap.ContainsKey('composer.json')) {
        $rawComposer = Get-Content -LiteralPath $ManifestMap['composer.json'] -Raw -ErrorAction SilentlyContinue
        if ([string]::IsNullOrWhiteSpace($rawComposer) -or $rawComposer.Trim() -eq '{}' -or $rawComposer.Trim() -eq '{ }') {
            $issues.Add((New-IssueRecord -Severity 'Medium' -Code 'EmptyComposerManifest' -Message 'composer.json exists but appears empty or placeholder-only.' -Path (Get-RelativePath -BasePath $WorkspaceRoot -TargetPath $ManifestMap['composer.json']) -Project $projectLabel))
        }
    }

    if ($Frameworks -contains 'Laravel') {
        $routeFiles = @(
            Join-Path -Path $RootPath -ChildPath 'routes\web.php'
            Join-Path -Path $RootPath -ChildPath 'routes\api.php'
        ) | Where-Object { Test-Path -LiteralPath $_ }

        foreach ($routeFile in $routeFiles) {
            $content = Get-Content -LiteralPath $routeFile -Raw -ErrorAction SilentlyContinue
            $matches = [regex]::Matches($content, 'view\(\s*[''"]([^''""]+)[''"]\s*\)')
            foreach ($match in $matches) {
                $viewName = $match.Groups[1].Value
                $viewPath = Join-Path -Path $RootPath -ChildPath ('resources\views\' + ($viewName -replace '\.', '\') + '.blade.php')
                if (-not (Test-Path -LiteralPath $viewPath)) {
                    $issues.Add((New-IssueRecord -Severity 'High' -Code 'MissingLaravelView' -Message ('Route references missing Blade view "' + $viewName + '".') -Path (Get-RelativePath -BasePath $WorkspaceRoot -TargetPath $routeFile) -Project $projectLabel))
                }
            }
        }

        if ($ComposerJson -and $ComposerJson.PSObject.Properties.Name -contains 'scripts') {
            $scriptsJson = ($ComposerJson.scripts | ConvertTo-Json -Depth 5)
            $hasPackageJsonHere = Test-Path -LiteralPath (Join-Path -Path $RootPath -ChildPath 'package.json')
            $childJavaScriptProject = $AllProjectRoots | Where-Object {
                $_ -ne $RootPath -and (Test-StartsWithPath -Path $_ -Root $RootPath) -and (Test-Path -LiteralPath (Join-Path -Path $_ -ChildPath 'package.json'))
            } | Select-Object -First 1

            if ($scriptsJson -match 'npm\s+(install|run)' -and -not $hasPackageJsonHere -and $childJavaScriptProject) {
                $issues.Add((New-IssueRecord -Severity 'Medium' -Code 'NestedFrontendComposerScripts' -Message 'composer.json references npm commands in a directory without package.json while a nested frontend project exists.' -Path (Get-RelativePath -BasePath $WorkspaceRoot -TargetPath $ManifestMap['composer.json']) -Project $projectLabel))
            }
        }
    }

    $suspiciousDirectories = Get-ChildItem -LiteralPath $RootPath -Directory -Force -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -match '[{}]'
    }
    foreach ($directory in $suspiciousDirectories) {
        $files = Get-ChildItem -LiteralPath $directory.FullName -Recurse -File -Force -ErrorAction SilentlyContinue
        if (@($files).Count -eq 0) {
            $issues.Add((New-IssueRecord -Severity 'Low' -Code 'SuspiciousEmptyDirectory' -Message ('Suspicious empty directory name detected: ' + $directory.Name) -Path (Get-RelativePath -BasePath $WorkspaceRoot -TargetPath $directory.FullName) -Project $projectLabel))
        }
    }

    $testsPath = Join-Path -Path $RootPath -ChildPath 'tests'
    if (($Frameworks -contains 'Laravel' -or $Frameworks -contains 'Django' -or $Frameworks -contains 'SpringBoot' -or $Frameworks -contains 'NestJS' -or $Frameworks -contains 'Express') -and -not (Test-Path -LiteralPath $testsPath)) {
        $issues.Add((New-IssueRecord -Severity 'Low' -Code 'MissingTestsDirectory' -Message 'No tests directory was detected for this backend project.' -Path $projectLabel -Project $projectLabel))
    }

    $exampleTests = $RelativeFiles | Where-Object { $_ -match 'ExampleTest' }
    if (@($exampleTests).Count -gt 0 -and @($RelativeFiles | Where-Object { $_ -match 'tests?[\\/].+\.(php|js|ts|py|java)$' }).Count -le 1) {
        $issues.Add((New-IssueRecord -Severity 'Low' -Code 'MinimalTestCoverage' -Message 'Only example or placeholder tests were detected.' -Path $projectLabel -Project $projectLabel))
    }

    $issues
}

function Get-GeneratedArtifacts {
    param(
        [string]$SourcePath,
        [hashtable]$Config,
        [string[]]$AdditionalSkipRoots = @()
    )

    $root = Resolve-AbsolutePath -Path $SourcePath
    $stack = New-Object 'System.Collections.Generic.Stack[string]'
    $stack.Push($root)
    $directories = New-Object 'System.Collections.Generic.List[object]'
    $files = New-Object 'System.Collections.Generic.List[object]'

    while ($stack.Count -gt 0) {
        $current = $stack.Pop()
        $children = Get-ChildItem -LiteralPath $current -Force -ErrorAction SilentlyContinue

        foreach ($child in $children) {
            if (Test-PathInRoots -Path $child.FullName -Roots $AdditionalSkipRoots) {
                continue
            }

            if ($child.PSIsContainer) {
                $kind = $null
                if (Test-DirectoryNameInSet -Name $child.Name -Set $Config.GeneratedDirectories) {
                    $kind = 'Generated'
                }
                elseif (Test-DirectoryNameInSet -Name $child.Name -Set $Config.WorkspaceClutterDirectories) {
                    $kind = 'WorkspaceClutter'
                }

                if ($kind) {
                    $directories.Add([pscustomobject]@{
                        Kind         = $kind
                        Name         = $child.Name
                        RelativePath = Get-RelativePath -BasePath $root -TargetPath $child.FullName
                        FullPath     = $child.FullName
                    })
                    continue
                }

                $stack.Push($child.FullName)
                continue
            }

            if (Test-DirectoryNameInSet -Name $child.Name -Set $Config.GeneratedFileNames) {
                $files.Add([pscustomobject]@{
                    Kind         = 'GeneratedFile'
                    Name         = $child.Name
                    RelativePath = Get-RelativePath -BasePath $root -TargetPath $child.FullName
                    FullPath     = $child.FullName
                })
                continue
            }

            foreach ($pattern in $Config.ExcludedFilePatterns) {
                if ($child.Name -like $pattern) {
                    $files.Add([pscustomobject]@{
                        Kind         = 'GeneratedFile'
                        Name         = $child.Name
                        RelativePath = Get-RelativePath -BasePath $root -TargetPath $child.FullName
                        FullPath     = $child.FullName
                    })
                    break
                }
            }
        }
    }

    [pscustomobject]@{
        Directories = $directories
        Files       = $files
    }
}

function Get-ProjectDescriptors {
    param(
        [string]$SourcePath,
        [hashtable]$Config,
        [string[]]$AdditionalSkipRoots = @()
    )

    $root = Resolve-AbsolutePath -Path $SourcePath
    $manifestFiles = Get-ProjectTreeItems -Path $root -Config $Config -ItemType File -AdditionalSkipRoots $AdditionalSkipRoots |
        Where-Object { $Config.ManifestFiles -contains $_.Name }

    $rootSet = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    [void]$rootSet.Add($root)
    foreach ($manifestFile in $manifestFiles) {
        [void]$rootSet.Add($manifestFile.DirectoryName)
    }

    $allRoots = @($rootSet) | Sort-Object Length, @{ Expression = { $_ } }
    $descriptors = New-Object 'System.Collections.Generic.List[object]'

    foreach ($candidateRoot in $allRoots) {
        $manifestMap = Get-DirectManifestMap -RootPath $candidateRoot -Config $Config
        $hasManifest = $manifestMap.Keys.Count -gt 0
        $hasSourceDirectories = @(Get-ChildItem -LiteralPath $candidateRoot -Directory -Force -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -in @('src', 'app', 'routes', 'public', 'config', 'database')
        }).Count -gt 0

        if (-not $hasManifest -and -not $hasSourceDirectories) {
            continue
        }

        $nestedRoots = $allRoots | Where-Object {
            $_ -ne $candidateRoot -and (Test-StartsWithPath -Path $_ -Root $candidateRoot)
        }

        $packageJson = $null
        if ($manifestMap.ContainsKey('package.json')) {
            $packageJson = ConvertFrom-JsonSafe -Path $manifestMap['package.json']
        }

        $composerJson = $null
        if ($manifestMap.ContainsKey('composer.json')) {
            $composerJson = ConvertFrom-JsonSafe -Path $manifestMap['composer.json']
        }

        $files = Get-ProjectTreeItems -Path $candidateRoot -Config $Config -ItemType File -AdditionalSkipRoots $nestedRoots
        $relativeFiles = @($files | ForEach-Object { Get-RelativePath -BasePath $candidateRoot -TargetPath $_.FullName })
        $frameworks = Get-FrameworksForProject -ManifestMap $manifestMap -PackageJson $packageJson -ComposerJson $composerJson -FileRelativePaths $relativeFiles
        $languages = Get-LanguagesForProject -FileRelativePaths $relativeFiles -Frameworks $frameworks
        $packageManagers = Get-PackageManagersForProject -ManifestMap $manifestMap -ComposerJson $composerJson -FileRelativePaths $relativeFiles
        $dependencies = Get-ProjectDependencies -ManifestMap $manifestMap -PackageJson $packageJson -ComposerJson $composerJson
        $criticalFiles = Get-CriticalFilesForProject -RootPath $candidateRoot -Frameworks $frameworks -Config $Config
        $keepDirectories = Get-KeepDirectoriesForProject -RootPath $candidateRoot -Frameworks $frameworks -Config $Config
        $role = Get-ProjectRole -Frameworks $frameworks
        $categoryMatches = Get-CategoryMatches -RelativeFiles $relativeFiles -Config $Config
        $launchCommands = Get-LaunchCommands -RootPath $candidateRoot -Frameworks $frameworks -ManifestMap $manifestMap -PackageJson $packageJson
        $relativeRoot = if ($candidateRoot -eq $root) { '.' } else { Get-RelativePath -BasePath $root -TargetPath $candidateRoot }
        $issues = Get-ProjectIssues -WorkspaceRoot $root -RootPath $candidateRoot -RelativeRoot $relativeRoot -Frameworks $frameworks -ManifestMap $manifestMap -PackageJson $packageJson -ComposerJson $composerJson -AllProjectRoots $allRoots -RelativeFiles $relativeFiles

        $environmentFiles = @($files | Where-Object { $_.Name -like '.env*' } | ForEach-Object {
            Get-RelativePath -BasePath $candidateRoot -TargetPath $_.FullName
        })

        $configFiles = @($relativeFiles | Where-Object { $_ -match '(\.config\.|^tsconfig\.json$|^package\.json$|^composer\.json$|^pyproject\.toml$|^pom\.xml$|[\\/]config[\\/])' } | Select-Object -Unique)

        $descriptors.Add([pscustomobject]@{
            RootPath         = $candidateRoot
            RelativeRoot     = $relativeRoot
            Role             = $role
            Frameworks       = $frameworks
            Languages        = $languages
            PackageManagers  = $packageManagers
            Dependencies     = $dependencies
            Categories       = $categoryMatches
            CriticalFiles    = $criticalFiles
            EnvironmentFiles = $environmentFiles
            ConfigFiles      = $configFiles
            KeepDirectories  = $keepDirectories
            KeepFiles        = $criticalFiles
            NestedRoots      = $nestedRoots
            LaunchCommands   = $launchCommands
            Issues           = $issues
            FileCount        = @($files).Count
        })
    }

    $descriptors
}

function New-ProjectAnalysis {
    param(
        [string]$SourcePath,
        [string]$OutputPath,
        [hashtable]$Config
    )

    $resolvedSource = Resolve-AbsolutePath -Path $SourcePath
    $skipRoots = @()

    if ($OutputPath -and (Test-Path -LiteralPath $OutputPath)) {
        $resolvedOutput = Resolve-AbsolutePath -Path $OutputPath
        if (Test-StartsWithPath -Path $resolvedOutput -Root $resolvedSource) {
            $skipRoots += $resolvedOutput
        }
    }

    $generatedArtifacts = Get-GeneratedArtifacts -SourcePath $resolvedSource -Config $Config -AdditionalSkipRoots $skipRoots
    $projects = Get-ProjectDescriptors -SourcePath $resolvedSource -Config $Config -AdditionalSkipRoots $skipRoots

    $frameworks = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    $languages = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    $packageManagers = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    $issues = New-Object 'System.Collections.Generic.List[object]'
    $criticalFiles = New-Object 'System.Collections.Generic.List[string]'
    $envFiles = New-Object 'System.Collections.Generic.List[string]'
    $launchPlans = New-Object 'System.Collections.Generic.List[object]'

    foreach ($project in $projects) {
        foreach ($framework in $project.Frameworks) { [void]$frameworks.Add($framework) }
        foreach ($language in $project.Languages) { [void]$languages.Add($language) }
        foreach ($manager in $project.PackageManagers) { [void]$packageManagers.Add($manager) }
        foreach ($issue in $project.Issues) { $issues.Add($issue) }

        foreach ($file in $project.CriticalFiles) {
            $path = if ($project.RelativeRoot -eq '.') { $file } else { Join-Path -Path $project.RelativeRoot -ChildPath $file }
            $criticalFiles.Add($path)
        }

        foreach ($envFile in $project.EnvironmentFiles) {
            $path = if ($project.RelativeRoot -eq '.') { $envFile } else { Join-Path -Path $project.RelativeRoot -ChildPath $envFile }
            $envFiles.Add($path)
        }

        if (@($project.LaunchCommands).Count -gt 0) {
            $launchPlans.Add([pscustomobject]@{
                Project = $project.RelativeRoot
                Role    = $project.Role
                Commands = $project.LaunchCommands
            })
        }
    }

    foreach ($generatedDirectory in $generatedArtifacts.Directories) {
        $severity = if ($generatedDirectory.Kind -eq 'Generated') { 'Low' } else { 'Info' }
        $issues.Add((New-IssueRecord -Severity $severity -Code 'GeneratedDirectoryPresent' -Message ('Detected removable directory: ' + $generatedDirectory.RelativePath) -Path $generatedDirectory.RelativePath -Project '.'))
    }

    foreach ($generatedFile in $generatedArtifacts.Files) {
        $issues.Add((New-IssueRecord -Severity 'Low' -Code 'GeneratedFilePresent' -Message ('Detected removable file: ' + $generatedFile.RelativePath) -Path $generatedFile.RelativePath -Project '.'))
    }

    $workspaceFiles = Get-ProjectTreeItems -Path $resolvedSource -Config $Config -ItemType File -AdditionalSkipRoots $skipRoots
    $workspaceBytes = (@($workspaceFiles | Measure-Object -Property Length -Sum).Sum)

    [pscustomobject]@{
        GeneratedAt = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        SourcePath  = $resolvedSource
        OutputPath  = $OutputPath
        ProjectName = Split-Path -Path $resolvedSource -Leaf
        Stack       = [pscustomobject]@{
            Frameworks      = @($frameworks) | Sort-Object
            Languages       = @($languages) | Sort-Object
            PackageManagers = @($packageManagers) | Sort-Object
        }
        Projects = $projects
        EnvironmentFiles = $envFiles | Sort-Object -Unique
        CriticalFiles = $criticalFiles | Sort-Object -Unique
        GeneratedArtifacts = $generatedArtifacts
        Issues = $issues
        LaunchPlans = $launchPlans
        Workspace = [pscustomobject]@{
            FileCount   = @($workspaceFiles).Count
            TotalBytes  = $workspaceBytes
            HumanSize   = Get-HumanSize -Bytes $workspaceBytes
            ProjectRoots = @($projects).Count
        }
        Outputs = $null
        Reports = $null
    }
}
