#requires -Version 7.4

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$inputs = [System.Collections.Generic.List[string]]::new()
$outputDirectory = $null
$format = $null
$verboseEnabled = $false
$dryRun = $false
$bitrateKbps = 320
$sampleRate = $null
$force = $false

for ($i = 0; $i -lt $args.Count; $i++) {
    $token = $args[$i]

    switch ($token) {
        '--input' {
            if ($i + 1 -ge $args.Count) { throw 'Missing value for --input' }
            $i++
            [void]$inputs.Add($args[$i])
        }
        '--output' {
            if ($i + 1 -ge $args.Count) { throw 'Missing value for --output' }
            $i++
            $outputDirectory = $args[$i]
        }
        '--format' {
            if ($i + 1 -ge $args.Count) { throw 'Missing value for --format' }
            $i++
            $format = $args[$i]
        }
        '--verbose' { $verboseEnabled = $true }
        '--dry-run' { $dryRun = $true }
        '--bitrate-kbps' {
            if ($i + 1 -ge $args.Count) { throw 'Missing value for --bitrate-kbps' }
            $i++
            $bitrateKbps = [int]$args[$i]
        }
        '--sample-rate' {
            if ($i + 1 -ge $args.Count) { throw 'Missing value for --sample-rate' }
            $i++
            $sampleRate = [int]$args[$i]
        }
        '--force' { $force = $true }
        default { throw "Unknown argument: $token" }
    }
}

if ($inputs.Count -eq 0) {
    throw 'At least one --input value is required.'
}

if ([string]::IsNullOrWhiteSpace($outputDirectory)) {
    throw '--output is required.'
}

if ([string]::IsNullOrWhiteSpace($format)) {
    throw '--format is required.'
}

$modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../trackstash.transcode/TrackStash.Transcode.psd1'
Import-Module -Name $modulePath -Force

$params = @{
    InputPath       = @($inputs)
    OutputDirectory = $outputDirectory
    Format          = $format
    BitrateKbps     = $bitrateKbps
    Force           = $force
}

if ($verboseEnabled) {
    $params.Verbose = $true
}

if ($dryRun) {
    $params.WhatIf = $true
}

if ($null -ne $sampleRate) {
    $params.SampleRate = $sampleRate
}

$result = Invoke-TrackStashTranscode @params
$result

if ($result.ExitCode -ne 0) {
    exit 1
}
