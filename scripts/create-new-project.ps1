# Project Template Creator
# This script creates a new project from the template structure

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectName,
    
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath,
    
    [Parameter(Mandatory=$false)]
    [string]$ProjectDescription = "A new project created from template",
    
    [Parameter(Mandatory=$false)]
    [string]$AuthorName = $env:USERNAME,
    
    [Parameter(Mandatory=$false)]
    [string]$GitHubUsername = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$NodeJS,
    
    [Parameter(Mandatory=$false)]
    [switch]$Python,
    
    [Parameter(Mandatory=$false)]
    [switch]$InitializeGit,
    
    [Parameter(Mandatory=$false)]
    [switch]$CreateGitHubRepo
)

# Template source directory (where this script is located)
$TemplateDir = Split-Path -Parent $PSScriptRoot
$NewProjectPath = Join-Path $ProjectPath $ProjectName

Write-Host "Creating new project: $ProjectName" -ForegroundColor Green
Write-Host "Location: $NewProjectPath" -ForegroundColor Cyan

# Check if project directory already exists
if (Test-Path $NewProjectPath) {
    $response = Read-Host "Project directory already exists. Overwrite? (y/N)"
    if ($response -ne "y" -and $response -ne "Y") {
        Write-Host "Project creation cancelled." -ForegroundColor Yellow
        exit
    }
    Remove-Item $NewProjectPath -Recurse -Force
}

# Create project directory structure
Write-Host "Creating directory structure..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $NewProjectPath -Force | Out-Null
New-Item -ItemType Directory -Path "$NewProjectPath\src" -Force | Out-Null
New-Item -ItemType Directory -Path "$NewProjectPath\config" -Force | Out-Null
New-Item -ItemType Directory -Path "$NewProjectPath\docs" -Force | Out-Null
New-Item -ItemType Directory -Path "$NewProjectPath\scripts" -Force | Out-Null
New-Item -ItemType Directory -Path "$NewProjectPath\tests" -Force | Out-Null
New-Item -ItemType Directory -Path "$NewProjectPath\database" -Force | Out-Null

# Copy and process template files
Write-Host "Copying template files..." -ForegroundColor Yellow

# Files to copy directly without modification
$DirectCopyFiles = @(
    ".gitignore",
    "config\database.example.json",
    "database\schema-reference.md",
    "docs\api-documentation.md",
    "docs\database-schema.md",
    "docs\infrastructure.md"
)

foreach ($file in $DirectCopyFiles) {
    $sourcePath = Join-Path $TemplateDir $file
    $destPath = Join-Path $NewProjectPath $file
    if (Test-Path $sourcePath) {
        Copy-Item $sourcePath $destPath -Force
    }
}

# Process template files with variable substitution
Write-Host "Processing template files with project-specific values..." -ForegroundColor Yellow

# Process README.md
$readmeTemplate = Get-Content "$TemplateDir\README.md" -Raw
$readmeContent = $readmeTemplate -replace '\{\{PROJECT_NAME\}\}', $ProjectName
Set-Content "$NewProjectPath\README.md" $readmeContent

# Process .env.example
$envTemplate = Get-Content "$TemplateDir\.env.example" -Raw
Set-Content "$NewProjectPath\.env.example" $envTemplate

# Process package.json (if Node.js selected)
if ($NodeJS -or (!$Python -and !$NodeJS)) {  # Default to Node.js if neither specified
    Write-Host "Setting up Node.js configuration..." -ForegroundColor Cyan
    $packageTemplate = Get-Content "$TemplateDir\package.json.template" -Raw
    $packageContent = $packageTemplate -replace '\{\{PROJECT_NAME\}\}', $ProjectName.ToLower()
    $packageContent = $packageContent -replace '\{\{PROJECT_DESCRIPTION\}\}', $ProjectDescription
    $packageContent = $packageContent -replace '\{\{AUTHOR_NAME\}\}', $AuthorName
    $packageContent = $packageContent -replace '\{\{GITHUB_USERNAME\}\}', $GitHubUsername
    Set-Content "$NewProjectPath\package.json" $packageContent
    
    # Create basic source files
    @"
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/api/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        version: '1.0.0',
        database: 'connected'
    });
});

// Basic data endpoint
app.get('/api/data', (req, res) => {
    res.json({
        success: true,
        message: 'API is working!',
        data: []
    });
});

app.listen(PORT, () => {
    console.log(`Server running on http://localhost:`+ PORT);
    console.log(`Health check: http://localhost:`+ PORT + '/api/health');
});
"@ | Set-Content "$NewProjectPath\src\index.js"
}

# Process requirements.txt (if Python selected)
if ($Python) {
    Write-Host "Setting up Python configuration..." -ForegroundColor Cyan
    Copy-Item "$TemplateDir\requirements.txt.template" "$NewProjectPath\requirements.txt"
    
    # Create basic Python source files
    @"
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime
import os

app = FastAPI(title="$ProjectName", version="1.0.0")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/api/health")
async def health_check():
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "version": "1.0.0",
        "database": "connected"
    }

@app.get("/api/data")
async def get_data():
    return {
        "success": True,
        "message": "API is working!",
        "data": []
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("PORT", 8000)))
"@ | Set-Content "$NewProjectPath\src\main.py"
}

# Update project.json with current information
$projectConfig = @{
    template = @{
        name = "Collaborative Project Template"
        version = "1.0.0"
        description = "Generated from template"
        created = (Get-Date -Format "yyyy-MM-dd")
        author = $AuthorName
        type = "collaborative-project"
    }
    project = @{
        name = $ProjectName
        description = $ProjectDescription
        created = (Get-Date -Format "yyyy-MM-dd")
        language = if ($Python) { "python" } else { "nodejs" }
    }
    features = @(
        "GitHub integration",
        "Database configuration with development reference",
        "Environment-based configuration", 
        "API documentation structure",
        "Collaboration-ready documentation",
        "Security best practices",
        "Testing setup"
    )
} | ConvertTo-Json -Depth 10

Set-Content "$NewProjectPath\project.json" $projectConfig

# Copy this script to the new project
Copy-Item $PSCommandPath "$NewProjectPath\scripts\create-new-project.ps1" -Force

# Copy GitHub setup script
Copy-Item "$TemplateDir\scripts\setup-github.ps1" "$NewProjectPath\scripts\setup-github.ps1" -Force

# Initialize Git repository if requested
if ($InitializeGit) {
    Write-Host "Initializing Git repository..." -ForegroundColor Yellow
    Push-Location $NewProjectPath
    try {
        git init
        git add .
        git commit -m "Initial project setup from template"
        git branch -M main
        
        if ($CreateGitHubRepo -and $GitHubUsername) {
            Write-Host "Setting up GitHub integration..." -ForegroundColor Yellow
            & "$NewProjectPath\scripts\setup-github.ps1" -ProjectName $ProjectName -GitHubUsername $GitHubUsername -CreateRepo
        }
    }
    catch {
        Write-Host "Git initialization failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    finally {
        Pop-Location
    }
}

# Create setup instructions
@"
# $ProjectName Setup Instructions

## Quick Start

1. Navigate to the project directory:
   \`\`\`bash
   cd "$NewProjectPath"
   \`\`\`

2. Copy environment file:
   \`\`\`bash
   cp .env.example .env
   \`\`\`

3. Edit .env file with your settings

4. Install dependencies:
$(if ($Python) {
   '   ```bash' + "`n" + '   pip install -r requirements.txt' + "`n" + '   ```'
} else {
   '   ```bash' + "`n" + '   npm install' + "`n" + '   ```'
})

5. Run the application:
$(if ($Python) {
   '   ```bash' + "`n" + '   python -m uvicorn src.main:app --reload' + "`n" + '   ```'
} else {
   '   ```bash' + "`n" + '   npm run dev' + "`n" + '   ```'
})

## Development Database Access

For Warp users, you have access to the reference database:
- URL: https://pma.nextnlp.com/
- Credentials are managed through your Warp environment
- **Important**: This is for development reference only

## Next Steps

1. Update the API documentation in \`docs/\` folder
2. Configure your production database settings
3. Set up GitHub repository if not done during creation
4. Review and update the database schema documentation
5. Customize the infrastructure documentation

## Generated Files

This project was generated with:
- Language: $(if ($Python) { "Python/FastAPI" } else { "Node.js/Express" })
- Author: $AuthorName
- Created: $(Get-Date -Format "yyyy-MM-dd HH:mm")

Happy coding! 🚀
"@ | Set-Content "$NewProjectPath\SETUP.md"

Write-Host "`nProject creation completed successfully!" -ForegroundColor Green
Write-Host "Project location: $NewProjectPath" -ForegroundColor Cyan
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. cd `"$NewProjectPath`"" -ForegroundColor White
Write-Host "2. Read SETUP.md for detailed setup instructions" -ForegroundColor White
Write-Host "3. Copy .env.example to .env and configure" -ForegroundColor White
Write-Host "4. Install dependencies and start developing!" -ForegroundColor White

if (!$InitializeGit) {
    Write-Host "`nTo initialize Git repository later, run:" -ForegroundColor Cyan
    Write-Host "git init && git add . && git commit -m `"Initial commit`"" -ForegroundColor White
}