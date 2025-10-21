<#
.SYNOPSIS
    Download and extract the Sysinternals Suite using multiple fallbacks:
    Invoke-WebRequest -> bitsadmin -> certutil

.DESCRIPTION
    Tries Invoke-WebRequest first. If that fails or is not available, tries bitsadmin.
    If bitsadmin is not available or fails, tries certutil as a last resort.
    Extracts the downloaded zip (using Expand-Archive or .NET fallback) and removes the zip.

.NOTES
    - Designed to work on a variety of Windows/PowerShell versions.
    - No admin required for default download folder (user Downloads).
    - Might need to run Set-ExecutionPolicy RemoteSigned if failing to run the script
#>

param(
    [string]$DownloadUrl = 'https://download.sysinternals.com/files/SysinternalsSuite.zip',
    [string]$DestinationFolder = "$env:USERPROFILE\Downloads\SysinternalsSuite",
    [switch]$KeepZip  # if present, do not remove the downloaded zip
)

function Write-Info { param($m) Write-Host $m -ForegroundColor Cyan }
function Write-Success { param($m) Write-Host $m -ForegroundColor Green }
function Write-ErrorLine { param($m) Write-Host $m -ForegroundColor Red }

# Ensure destination folder exists
if (-not (Test-Path -Path $DestinationFolder)) {
    New-Item -ItemType Directory -Path $DestinationFolder | Out-Null
}

$ZipPath = Join-Path $DestinationFolder 'SysinternalsSuite.zip'

function Try-InvokeWebRequest {
    param($Url, $OutFile)
    try {
        # Ensure TLS 1.2 for older PS/.NET
        try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

        if (Get-Command -Name Invoke-WebRequest -ErrorAction SilentlyContinue) {
            Write-Info "Trying Invoke-WebRequest..."
            # Use -Uri and -OutFile; add -UseBasicParsing for very old PS (but that parameter is deprecated)
            Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing -ErrorAction Stop
            return $true
        } else {
            Write-Info "Invoke-WebRequest not available."
            return $false
        }
    } catch {
        Write-ErrorLine "Invoke-WebRequest failed: $($_.Exception.Message)"
        return $false
    }
}

function Try-BitsAdmin {
    param($Url, $OutFile)
    # bitsadmin typically exists at C:\Windows\System32\bitsadmin.exe on older Windows
    $bits = Get-Command -Name bitsadmin -ErrorAction SilentlyContinue
    if (-not $bits) {
        Write-Info "bitsadmin not found on this system."
        return $false
    }

    try {
        Write-Info "Trying bitsadmin..."
        # bitsadmin requires local filename; ensure any existing transfer with same name removed
        $transferName = "SysinternalsDownload_$(Get-Random)"
        $cmd = "bitsadmin /transfer `"$transferName`" /download /priority normal `"$Url`" `"$OutFile`""
        $proc = Start-Process -FilePath "bitsadmin" -ArgumentList "/transfer", $transferName, "/download", "/priority", "normal", $Url, $OutFile -NoNewWindow -PassThru -Wait -ErrorAction Stop

        # bitsadmin returns code 0 on success; Start-Process returns a process object, check exit code
        if ($proc.ExitCode -eq 0) {
            return $true
        } else {
            Write-ErrorLine "bitsadmin exit code: $($proc.ExitCode)"
            return $false
        }
    } catch {
        Write-ErrorLine "bitsadmin failed: $($_.Exception.Message)"
        return $false
    } finally {
        # try to cancel any partial transfer using bitsadmin (best-effort, ignore errors)
        try { bitsadmin /reset | Out-Null } catch {}
    }
}

function Try-CertUtil {
    param($Url, $OutFile)
    if (-not (Get-Command -Name certutil -ErrorAction SilentlyContinue)) {
        Write-Info "certutil not found on this system."
        return $false
    }

    try {
        Write-Info "Trying certutil..."
        # certutil -urlcache -split <URL> <outfile>
        # Note: certutil writes to stdout-ish, so run via Start-Process and wait
        $args = @("-urlcache", "-split", $Url, $OutFile)
        $proc = Start-Process -FilePath "certutil" -ArgumentList $args -NoNewWindow -PassThru -Wait -ErrorAction Stop
        if ($proc.ExitCode -eq 0) {
            return $true
        } else {
            Write-ErrorLine "certutil exit code: $($proc.ExitCode)"
            return $false
        }
    } catch {
        Write-ErrorLine "certutil failed: $($_.Exception.Message)"
        return $false
    }
}

# Main download attempt sequence
$downloaded = $false

# Remove existing incomplete file (best-effort)
if (Test-Path $ZipPath) {
    try { Remove-Item -Path $ZipPath -Force -ErrorAction SilentlyContinue } catch {}
}

# 1) Try Invoke-WebRequest
if (-not $downloaded) {
    $downloaded = Try-InvokeWebRequest -Url $DownloadUrl -OutFile $ZipPath
}

# 2) Try bitsadmin
if (-not $downloaded) {
    $downloaded = Try-BitsAdmin -Url $DownloadUrl -OutFile $ZipPath
}

# 3) Try certutil
if (-not $downloaded) {
    $downloaded = Try-CertUtil -Url $DownloadUrl -OutFile $ZipPath
}

if (-not $downloaded) {
    Write-ErrorLine "All download methods failed. Cannot retrieve Sysinternals Suite from $DownloadUrl"
    exit 1
}

Write-Success "Download completed: $ZipPath"

# Extract zip
function Extract-Zip {
    param($ZipFile, $OutFolder)
    try {
        if (Get-Command -Name Expand-Archive -ErrorAction SilentlyContinue) {
            Write-Info "Extracting with Expand-Archive..."
            Expand-Archive -Path $ZipFile -DestinationPath $OutFolder -Force
            return $true
        } else {
            # .NET fallback for older PowerShell
            Write-Info "Expand-Archive not available. Using .NET ZipFile fallback..."
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFile, $OutFolder)
            return $true
        }
    } catch {
        Write-ErrorLine "Extraction failed: $($_.Exception.Message)"
        return $false
    }
}

if (Extract-Zip -ZipFile $ZipPath -OutFolder $DestinationFolder) {
    Write-Success "Extracted Sysinternals Suite to: $DestinationFolder"
    if (-not $KeepZip) {
        try { Remove-Item -Path $ZipPath -Force -ErrorAction SilentlyContinue; Write-Info "Removed zip file." } catch {}
    } else {
        Write-Info "Kept zip file as requested."
    }
    Write-Success "Done."
    exit 0
} else {
    Write-ErrorLine "Download succeeded but extraction failed. Zip located at: $ZipPath"
    exit 2
}

