function Start-PresentationMode {
    # change certain colors to be friendlier to those with color blindness
    Write-Host -ForegroundColor Yellow "Changing ERROR foreground color from RED >>> BLUE"
    $Host.PrivateData.ErrorForegroundColor = "Blue"

    Write-Host -ForegroundColor Yellow "Ghanging ERROR backround color >>> WHITE"
    $Host.PrivateData.ErrorBackgroundColor = "white"

    # Could add more here based on what colors are preferred but this is a start.

}
