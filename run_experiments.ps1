$proj = Split-Path -Parent $MyInvocation.MyCommand.Path + "\lab-03-starter-project-python"
$results = @()

Write-Host "Checking Docker..." -ForegroundColor Cyan
$pipe = Test-Path "\\.\pipe\dockerDesktopLinuxEngine"
if (-not $pipe) {
    Write-Host "ERROR: Docker Desktop is not running. Please start Docker Desktop first." -ForegroundColor Red
    exit 1
}
Write-Host "Docker OK" -ForegroundColor Green

Write-Host "`n[STEP 1] Pulling base images (this is NOT counted in build time)..."
docker pull python:3.13-bookworm 2>&1 | Select-String "Status:|Already"
docker pull python:3.13-alpine 2>&1 | Select-String "Status:|Already"

Write-Host "`n[STEP 2] Building images and measuring times..."

function BuildAndMeasure($tag, $dockerfilePath, $context, $noCache = $true) {
    $args = @("build", "-t", $tag, "-f", $dockerfilePath)
    if ($noCache) { $args += "--no-cache" }
    $args += $context
    
    $t = Measure-Command { & docker @args 2>&1 | Out-Null }
    $sz = docker images $tag --format "{{.Size}}"
    $sec = [math]::Round($t.TotalSeconds, 1)
    Write-Host "  $tag : ${sec}s | Size: $sz"
    return [PSCustomObject]@{
        Image   = $tag
        Time    = "${sec}s"
        Size    = $sz
        Cache   = if ($noCache) {"no-cache"} else {"cached"}
    }
}

$results += BuildAndMeasure "spaceship:debian-basic" "$proj\Dockerfile" $proj
$results += BuildAndMeasure "spaceship:debian-opt" "$proj\Dockerfile.optimized" $proj
$results += BuildAndMeasure "spaceship:debian-basic-rebuild" "$proj\Dockerfile" $proj $false
$results += BuildAndMeasure "spaceship:debian-opt-rebuild" "$proj\Dockerfile.optimized" $proj $false
$results += BuildAndMeasure "spaceship:alpine" "$proj\Dockerfile.alpine" $proj
$results += BuildAndMeasure "spaceship:debian-numpy" "$proj\Dockerfile.debian-numpy" $proj

Write-Host "`n[OPTIONAL - SLOW] Alpine + numpy build (~15 min):"
$answer = Read-Host "Build alpine-numpy? (y/n)"
if ($answer -eq "y") {
    $results += BuildAndMeasure "spaceship:alpine-numpy" "$proj\Dockerfile.alpine-numpy" $proj
}

Write-Host "`n[STEP 3] Final summary:"
$results | Format-Table -AutoSize

$results | ConvertTo-Json | Out-File -Encoding utf8 "build_results.json"
Write-Host "`nResults saved to: build_results.json"
Write-Host "Add these numbers to the report: Звіт_Лабораторна_2_Docker.docx"
