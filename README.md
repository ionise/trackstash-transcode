# trackstash-transcode

Cross-platform PowerShell module for safe, metadata-preserving audio transcoding with ffmpeg.

## Features

- FLAC, AIFF, WAV, and MP3 transcoding
- Metadata preserved by default using `-map_metadata 0`
- Pipeline-friendly cmdlets with structured object output
- Batch processing with per-file results and aggregate exit code
- CLI wrapper for automation

## Requirements

- PowerShell 7.4+
- ffmpeg in `PATH`

## ffmpeg Installation

- Windows: `winget install Gyan.FFmpeg` or `choco install ffmpeg`
- macOS: `brew install ffmpeg`
- Linux: `apt install ffmpeg`, `dnf install ffmpeg`, or `pacman -S ffmpeg`

## Module Layout

```text
trackstash.transcode/
|-- TrackStash.Transcode.psd1
|-- TrackStash.Transcode.psm1
|-- Public/
|-- Private/
```

## Usage

Import the module:

```powershell
Import-Module ./trackstash.transcode/TrackStash.Transcode.psd1 -Force
```

Check ffmpeg availability:

```powershell
Test-TrackStashFfmpeg
```

Get module and ffmpeg info:

```powershell
Get-TrackStashTranscodeInfo
```

Transcode one file to MP3 (default 320 kbps CBR):

```powershell
Invoke-TrackStashTranscode -InputPath ./in/track.flac -OutputDirectory ./out -Format Mp3
```

Pipeline transcode:

```powershell
Get-ChildItem ./in/*.wav | Invoke-TrackStashTranscode -OutputDirectory ./out -Format Flac
```

Dry run:

```powershell
Invoke-TrackStashTranscode -InputPath ./in/track.aiff -OutputDirectory ./out -Format Wav -WhatIf
```

## CLI

CLI script path: `cli/trackstash-transcode.ps1`

Example:

```powershell
pwsh ./cli/trackstash-transcode.ps1 --input ./in/track.flac --output ./out --format Mp3 --verbose
```

## Testing

Run unit tests:

```powershell
Invoke-Pester ./tests
```

Enable optional integration tests:

```powershell
$env:TRACKSTASH_TEST_FFMPEG = '1'
Invoke-Pester ./tests/Integration.Transcode.Tests.ps1
```

## Troubleshooting

- If import fails with an ffmpeg error, ensure ffmpeg is on `PATH`.
- For existing output files, pass `-Force` to overwrite.
- In batch runs, inspect `.Results` for per-file errors and `.ExitCode` for aggregate status.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
