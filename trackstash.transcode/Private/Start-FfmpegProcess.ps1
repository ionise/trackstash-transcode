function Start-FfmpegProcess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FfmpegPath,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [string[]]$ArgumentList,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$InputPath,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath
    )

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $FfmpegPath
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true

    foreach ($argument in $ArgumentList) {
        [void]$startInfo.ArgumentList.Add([string]$argument)
    }

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo

    [void]$process.Start()
    $stdOut = $process.StandardOutput.ReadToEnd()
    $stdErr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()

    return [PSCustomObject]@{
        InputPath  = $InputPath
        OutputPath = $OutputPath
        Success    = $process.ExitCode -eq 0
        ExitCode   = $process.ExitCode
        Arguments  = @($ArgumentList)
        StdOut     = $stdOut
        StdErr     = $stdErr
    }
}
