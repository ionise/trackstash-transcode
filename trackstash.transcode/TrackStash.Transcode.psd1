@{
    RootModule             = 'TrackStash.Transcode.psm1'
    ModuleVersion          = '0.1.0'
    GUID                   = '1235a7a8-466a-4598-b682-cc33f6366b8c'
    Author                 = 'David Alderman'
    CompanyName            = 'David Alderman'
    Copyright              = '(c) 2026 David Alderman.'
    Description            = 'Cross-platform ffmpeg wrapper for audio transcoding with metadata preservation.'
    PowerShellVersion      = '7.4'
    CompatiblePSEditions   = @('Core')

    RequiredModules        = @()

    FunctionsToExport      = @(
        'Invoke-TrackStashTranscode',
        'Get-TrackStashTranscodeInfo',
        'Test-TrackStashFfmpeg'
    )

    CmdletsToExport        = @()
    VariablesToExport      = @()
    AliasesToExport        = @()

    PrivateData            = @{
        PSData = @{
            Tags       = @('trackstash', 'audio', 'ffmpeg', 'transcode', 'mp3', 'flac', 'wav', 'aiff')
            LicenseUri = 'https://github.com/ionise/trackstash-transcode/blob/main/LICENSE'
            ProjectUri = 'https://github.com/ionise/trackstash-transcode'
        }
    }
}
