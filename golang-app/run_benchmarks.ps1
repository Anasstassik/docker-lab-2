Set-Location "c:\Users\ADMIN\OneDrive\Рабочий стол\учеба 2 курс\ТРПЗКС\lab2\golang-app"
Write-Host "Pulling base images..."
docker pull golang:1.21-bullseye | Out-Null
docker pull gcr.io/distroless/static-debian11 | Out-Null

$results = @()

function Build-And-Measure {
    param([string]$Name, [string]$Tag, [string]$File)
    Write-Host "Building $Name..."
    $start = Get-Date
    docker build --no-cache -f $File -t $Tag . | Out-Null
    $end = Get-Date
    $time = ($end - $start).TotalSeconds
    $size = docker inspect -f "{{.Size}}" $Tag
    $sizeMB = [math]::Round($size / 1MB, 2)
    Write-Host "$Name : $time s | Size: $sizeMB MB"
    return @{ Name = $Name; Time = $time; SizeMB = $sizeMB }
}

$results += Build-And-Measure -Name "golang-basic" -Tag "golang-app:basic" -File "Dockerfile.basic"
$results += Build-And-Measure -Name "golang-scratch" -Tag "golang-app:scratch" -File "Dockerfile.scratch"
$results += Build-And-Measure -Name "golang-distroless" -Tag "golang-app:distroless" -File "Dockerfile.distroless"

$results | ConvertTo-Json | Out-File "build_results_golang.json"
