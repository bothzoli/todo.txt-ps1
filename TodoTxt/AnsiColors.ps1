enum AnsiColors {
    Black = 0
    DarkRed = 1
    DarkGreen = 2
    DarkYellow = 3
    DarkBlue = 4
    DarkMagenta = 5
    DarkCyan = 6
    LightGray = 7
    DarkGray = 8
    Red = 9
    Green = 10
    Yellow = 11
    Blue = 12
    Magenta = 13
    Cyan = 14
    White = 15
}

function Add-BackgroundColor {
    param (
        [Parameter(ValueFromPipeline)]
        [string]$Text,
        [AnsiColors]$Color,
        [Parameter(Mandatory=$false)]
        [AnsiColors]$AfterColor
    )
    $colorCode = [int]$Color
    if (!$AfterColor) {
        "`e[48;5;$($colorCode)m$Text`e[0m"
    } else {
        $afterColorCode = [int]$AfterColor
        "`e[48;5;$($colorCode)m$Text`e[48;5;$($afterColorCode)m"
    }
}

function Add-ForegroundColor {
    param (
        [Parameter(ValueFromPipeline)]
        [string]$Text,
        [AnsiColors]$Color,
        [Parameter(Mandatory=$false)]
        [AnsiColors]$AfterColor
    )
    $colorCode = [int]$Color
    if (!$AfterColor) {
        "`e[38;5;$($colorCode)m$Text`e[0m"
    } else {
        $afterColorCode = [int]$AfterColor
        "`e[38;5;$($colorCode)m$Text`e[38;5;$($afterColorCode)m"
    }
}
