# trackstash-transcode Meta-Prompt Specification

## Objective

Generate a cross-platform PowerShell module named `trackstash-transcode` that wraps `ffmpeg` to transcode audio while preserving metadata by default.

## Normative Language

The keywords **MUST**, **MUST NOT**, **SHOULD**, and **MAY** are normative.

## Scope

This specification covers module behavior, project structure, cmdlet contracts, CLI behavior, testing, and documentation.

## Locked Decisions (2026-05-31)

The following decisions are locked and MUST be treated as defaults unless explicitly overridden by the user:

- Build the full MVP now, including:
  - module manifest
  - public cmdlets
  - private helpers
  - CLI wrapper
  - Pester tests
  - README
  - ffmpeg detection logic
- Enforce strict alignment with TrackStash conventions from sibling repositories.
- Include PowerShell Gallery-ready manifest metadata now, including:
  - `Author`
  - `LicenseUri`
  - `ProjectUri`
  - `Tags`
  - `CompatiblePSEditions`
  - `RequiredModules` (none for this module unless explicitly changed)
  - `RootModule`
- MP3 default behavior MUST be:
  - codec: `libmp3lame`
  - bitrate: 320 kbps CBR (`-b:a 320k`)
  - channel mode: joint stereo
  - sample rate: preserve source by default (no resample unless user sets `-SampleRate`)
  - lowpass: LAME default
- Batch runs MUST return a non-zero aggregate exit code if any file fails, while still returning per-file results.
- Test strategy MUST include:
  - mandatory mocked unit tests
  - optional integration tests gated by `$env:TRACKSTASH_TEST_FFMPEG`
- CI MUST be included from day one via GitHub Actions with matrix runs on:
  - `windows-latest`
  - `macos-latest`
  - `ubuntu-latest`
  - and MUST run linting plus Pester (with optional integration tests gated)
- MVP format support is limited to `FLAC`, `AIFF`, `WAV`, and `MP3`, implemented with extension-friendly architecture:
  - centralized format mapping
  - centralized codec resolver
  - centralized extension resolver

## Alignment Reference Repositories

Use these repositories as the canonical alignment baseline:

- `/Users/david/source/trackstash/trackstash-scan`
- `/Users/david/source/trackstash/psmusictagger`
- `/Users/david/source/trackstash/psAcoustID` (when relevant for ecosystem conventions)

Observed conventions to mirror include:

- module entrypoint with `#requires -Version 7.4` and `Set-StrictMode -Version Latest`
- dot-sourcing sorted scripts from `Private/` and `Public/`
- explicit `Export-ModuleMember -Function @(...)`
- CLI wrapper pattern in top-level `CLI/`-style folder using strict mode and module import via relative path
- Pester tests under `Tests/` using `Describe`, `BeforeAll`, `InModuleScope`, and command mocking

## Non-Goals

- No .NET ffmpeg bindings.
- No GUI application.
- No assumption that `ffmpeg` is bundled with the module.

## 1. Project Identity

- Module name: `trackstash-transcode`
- Language: PowerShell 7.4+
- Platforms: Windows, macOS (Intel + Apple Silicon), Linux
- Runtime dependency: external `ffmpeg` executable installed by user

The module is part of the TrackStash ecosystem and MUST align with conventions used by:

- `psMusicTagger`
- `trackstash-scan`
- `trackstash-fingerprint`

Alignment includes:

- folder layout
- logging style
- error handling
- CLI ergonomics
- test structure

## 2. Required Capabilities

### 2.1 Safe ffmpeg Wrapping

Implementation MUST:

- call `ffmpeg` from PowerShell process execution only
- use argument arrays (never command string concatenation)
- handle path values safely across platforms
- preserve metadata by default with `-map_metadata 0`
- support target formats: `FLAC`, `AIFF`, `WAV`, `MP3`

Future formats MAY be added if backward compatibility is preserved.

### 2.2 Fail-Fast ffmpeg Detection

On module import, implementation MUST:

- verify `ffmpeg` is available in `$env:PATH`
- throw a terminating error when missing
- include installation guidance in the error message:
  - Windows: `winget` or `chocolatey`
  - macOS: `brew`
  - Linux: `apt`, `dnf`, or `pacman` (generic guidance)

### 2.3 Ergonomic Cmdlets

The module MUST export:

- `Invoke-TrackStashTranscode`
- `Get-TrackStashTranscodeInfo`
- `Test-TrackStashFfmpeg`

Cmdlets MUST:

- enforce strict parameter validation
- accept pipeline input for file paths where applicable
- support batch operations
- support PowerShell dry-run semantics via `-WhatIf`
- return structured objects (not plain status strings)

### 2.4 TrackStash Operational Conventions

Implementation MUST:

- use `Write-Verbose`, `Write-Error`, and `Write-Debug`
- fail fast on invalid global input or setup failures
- continue processing remaining files after per-file failures in batch mode
- use Pester 5 for tests

## 3. Required Project Structure

```text
trackstash-transcode/
|-- trackstash.transcode/
|   |-- TrackStash.Transcode.psd1
|   |-- TrackStash.Transcode.psm1
|   |-- Public/
|   |   |-- Invoke-TrackStashTranscode.ps1
|   |   |-- Get-TrackStashTranscodeInfo.ps1
|   |   `-- Test-TrackStashFfmpeg.ps1
|   `-- Private/
|       |-- Start-FfmpegProcess.ps1
|       |-- Resolve-FfmpegPath.ps1
|       `-- Convert-TranscodeOptions.ps1
|-- cli/
|   `-- trackstash-transcode.ps1
`-- tests/
    |-- Invoke-TrackStashTranscode.Tests.ps1
    |-- Test-TrackStashFfmpeg.Tests.ps1
    `-- ModuleImport.Tests.ps1
```

## 4. Behavioral Rules

### 4.1 Cross-Platform Rules

Code MUST:

- use `Join-Path` instead of manual separators
- rely on `$IsWindows`, `$IsMacOS`, `$IsLinux` where OS branching is needed
- invoke `ffmpeg` generically, never hardcode `ffmpeg.exe`

### 4.2 Metadata Preservation

Transcode calls MUST include:

```text
-map_metadata 0
```

### 4.3 Safe Process Invocation Pattern

Implementation SHOULD follow this pattern:

```powershell
$arguments = @(
    "-i", $InputPath
    "-map_metadata", "0"
    # codec options
    $OutputPath
)

$process = Start-Process -FilePath $ffmpegPath -ArgumentList $arguments -NoNewWindow -Wait -PassThru
```

### 4.4 Input Validation

Transcode logic MUST validate:

- input file exists
- output directory exists
- target format is supported

### 4.5 Output Object Contract

Transcode results MUST be emitted as structured objects and SHOULD include at least:

```powershell
[PSCustomObject]@{
    InputPath  = $InputPath
    OutputPath = $OutputPath
    Format     = $TargetFormat
    Success    = $process.ExitCode -eq 0
    ExitCode   = $process.ExitCode
}
```

## 5. Cmdlet Contract

### 5.1 Invoke-TrackStashTranscode

Purpose: transcode one file or a pipeline of files.

Required parameters:

- `-InputPath` (string and/or pipeline)
- `-OutputDirectory`
- `-Format` with `ValidateSet(Flac, Aiff, Wav, Mp3)`
- `-BitrateKbps` (MP3 only)
- `-SampleRate`
- `-Force`
- `-WhatIf`

### 5.2 Get-TrackStashTranscodeInfo

MUST return ffmpeg version and supported codecs.

### 5.3 Test-TrackStashFfmpeg

MUST return boolean availability and diagnostic details.

## 6. CLI Contract

CLI wrapper MUST be located at `cli/trackstash-transcode.ps1` and MUST call module cmdlets.

CLI MUST support:

- `--input`
- `--output`
- `--format`
- `--verbose`
- `--dry-run`

## 7. Testing Requirements (Pester 5)

Test suite MUST include:

- module import tests
- ffmpeg detection tests (mocked)
- transcode invocation tests (mocked)
- CLI tests

## 8. Documentation Requirements

Deliverables MUST include:

- comment-based help for all exported cmdlets
- `README.md` containing:
  - installation
  - ffmpeg installation guidance by platform
  - usage examples
  - troubleshooting

## 9. Style and Quality Rules

Code MUST:

- use PascalCase function names
- use singular nouns for cmdlets
- use approved PowerShell verbs
- enable strict mode in scripts
- use UTF-8 encoding

Strict mode requirement:

```powershell
Set-StrictMode -Version Latest
```

## 10. Do / Don't Checklist

### Do

- Do use argument arrays for process invocation.
- Do preserve metadata unless explicitly overridden.
- Do return typed/structured objects for automation.
- Do isolate private helpers under `Private/`.
- Do write tests that mock external process behavior.

### Don't

- Do not concatenate raw shell command strings.
- Do not emit only human-readable strings for machine workflows.
- Do not stop batch jobs after the first per-file failure.
- Do not hardcode OS-specific executable names or path separators.
- Do not bypass parameter validation.

## 11. Acceptance Criteria

The implementation is accepted only if all statements are true:

- Module import fails fast with actionable guidance when `ffmpeg` is unavailable.
- `Invoke-TrackStashTranscode` supports single and pipeline input.
- `-WhatIf` works and does not execute transcoding.
- Metadata is preserved by default using `-map_metadata 0`.
- Output is structured and includes success and exit code fields.
- Cmdlets and file layout match this specification.
- Pester 5 tests cover import, detection, transcode path, and CLI path.
- README and comment-based help on all functions are present and complete.
- Markdown documents should comply with the rules in meta/copilot-markdown-style-guide.md
