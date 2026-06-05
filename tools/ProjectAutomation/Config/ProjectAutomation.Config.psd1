@{
    GeneratedDirectories = @(
        '.git',
        '.svn',
        '.hg',
        'node_modules',
        'vendor',
        'dist',
        'build',
        '.next',
        'out',
        'coverage',
        '.cache',
        '.turbo',
        '.idea',
        '.vscode',
        'logs',
        'log',
        'tmp',
        'temp',
        'cache',
        'bin',
        'obj',
        'target'
    )

    WorkspaceClutterDirectories = @(
        '.postman',
        '.qodo',
        'postman',
        'docs',
        'artifacts',
        'cleaned_project_source'
    )

    GeneratedFileNames = @(
        '.phpunit.result.cache',
        'npm-debug.log',
        'yarn-error.log',
        'pnpm-debug.log',
        'Thumbs.db',
        '.DS_Store'
    )

    ExcludedFilePatterns = @(
        '*.log',
        '*.tmp',
        '*.temp',
        '*.cache',
        '*.bak',
        '*.zip'
    )

    ManifestFiles = @(
        'package.json',
        'composer.json',
        'requirements.txt',
        'pyproject.toml',
        'Pipfile',
        'manage.py',
        'pom.xml',
        'build.gradle',
        'build.gradle.kts',
        'settings.gradle',
        'settings.gradle.kts',
        'angular.json',
        'nest-cli.json',
        'vite.config.js',
        'vite.config.ts',
        'vite.config.mjs',
        'next.config.js',
        'next.config.ts',
        'next.config.mjs',
        'artisan'
    )

    SensitiveEnvironmentKeyPatterns = @(
        'KEY',
        'SECRET',
        'TOKEN',
        'PASSWORD',
        'PASS',
        'PRIVATE',
        'CERT',
        'API_KEY',
        'APP_KEY'
    )

    RootFiles = @{
        Common = @(
            '.editorconfig',
            '.gitattributes',
            '.gitignore',
            '.env.example',
            'README.md',
            'README',
            'README.txt',
            'Dockerfile',
            '.dockerignore',
            'docker-compose.yml',
            'setup.ps1',
            'setup.sh'
        )
        JavaScript = @(
            'package.json',
            'package-lock.json',
            'yarn.lock',
            'pnpm-lock.yaml',
            'tsconfig.json',
            'jsconfig.json',
            'vite.config.js',
            'vite.config.ts',
            'vite.config.mjs',
            'next.config.js',
            'next.config.ts',
            'next.config.mjs',
            'angular.json',
            'nest-cli.json',
            'eslint.config.js',
            'eslint.config.cjs',
            'eslint.config.mjs',
            'postcss.config.js',
            'tailwind.config.js',
            'index.html'
        )
        PHP = @(
            'composer.json',
            'composer.lock',
            'artisan',
            'phpunit.xml'
        )
        Python = @(
            'requirements.txt',
            'pyproject.toml',
            'poetry.lock',
            'Pipfile',
            'Pipfile.lock',
            'manage.py'
        )
        Java = @(
            'pom.xml',
            'mvnw',
            'mvnw.cmd',
            'build.gradle',
            'build.gradle.kts',
            'settings.gradle',
            'settings.gradle.kts',
            'gradlew',
            'gradlew.bat'
        )
    }

    KeepDirectories = @{
        Common = @(
            'src',
            'app',
            'routes',
            'controllers',
            'controller',
            'models',
            'model',
            'services',
            'service',
            'components',
            'component',
            'hooks',
            'hook',
            'middleware',
            'middlewares',
            'config',
            'public',
            'database',
            'migrations',
            'prisma',
            'resources',
            'bootstrap',
            'tests',
            'templates',
            'static',
            'api',
            'pages',
            'context',
            'utils',
            'store',
            'assets'
        )
        React = @('src', 'public')
        NextJs = @('src', 'public', 'app', 'pages')
        Vue = @('src', 'public')
        Angular = @('src', 'public')
        Node = @('src', 'config', 'routes', 'controllers', 'models', 'middleware', 'middlewares', 'prisma', 'public', 'tests')
        NestJS = @('src', 'test', 'prisma')
        Laravel = @('app', 'bootstrap', 'config', 'database', 'public', 'resources', 'routes', 'tests')
        Django = @('src', 'app', 'apps', 'templates', 'static', 'tests', 'config')
        SpringBoot = @('src', 'config')
        Python = @('src', 'app', 'tests')
        PHP = @('app', 'config', 'public', 'routes', 'resources', 'tests')
    }

    CategoryPatterns = @{
        Api = @(
            '(^|[\\/])api([\\/]|$)',
            'routes[\\/]api\.php$',
            'urls\.py$'
        )
        Routes = @(
            '(^|[\\/])routes?([\\/]|$)',
            'web\.php$',
            'api\.php$',
            'router\.(js|ts)$',
            'urls\.py$'
        )
        Services = @(
            '(^|[\\/])services?([\\/]|$)',
            '\.service\.(js|jsx|ts|tsx|php|py|java)$'
        )
        Hooks = @(
            '(^|[\\/])hooks?([\\/]|$)',
            '[\\/]use[A-Z][^\\/]*\.(js|jsx|ts|tsx)$'
        )
        Components = @(
            '(^|[\\/])components?([\\/]|$)',
            '\.component\.(js|jsx|ts|tsx|vue)$'
        )
        Middlewares = @(
            '(^|[\\/])middlewares?([\\/]|$)',
            'middleware'
        )
        Models = @(
            '(^|[\\/])models?([\\/]|$)',
            '\.model\.(js|ts|php|py|java)$',
            'entity'
        )
        Controllers = @(
            '(^|[\\/])controllers?([\\/]|$)',
            'Controller\.(php|py|java)$',
            'Controller[A-Za-z0-9_]*\.(js|ts)$'
        )
        Config = @(
            '(^|[\\/])config([\\/]|$)',
            '\.config\.(js|cjs|mjs|ts|json)$',
            'tsconfig\.json$',
            'package\.json$',
            'composer\.json$',
            'pyproject\.toml$',
            'pom\.xml$'
        )
    }
}
