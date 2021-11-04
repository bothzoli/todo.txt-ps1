. $PSScriptRoot\AnsiColors.ps1

function ConvertTo-TodoObject {
    param (
        [int]$TodoId,
        [string]$Text
    )

    $Text -match "^(?<Done>x )?(\((?<Priority>[A-Z])\) )?(?<FirstDate>(19\d\d|20\d\d)-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1]) )?((?<SecondDate>(19\d\d|20\d\d)-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])))?" | Out-Null

    if ($Matches.FirstDate -and $Matches.SecondDate) {
        $completionDate = $Matches.FirstDate
        $creationDate = $Matches.SecondDate
    } elseif ($Matches.Done -and $Matches.FirstDate) {
        $completionDate = $Matches.FirstDate
    } elseif ($Matches.FirstDate) {
        $creationDate = $Matches.FirstDate
    }
        
    $todoObject = @{
        Id = $TodoId
        Text = $Text
        Done = [bool]$Matches.Done
        Priority = $Matches.Priority
        CreationDate = $creationDate
        CompletionDate = $completionDate
        Contexts = @()
        Projects = @()
        KeyValues = @()
        FormattedText = ""
    }

    if ($todoObject.Done) {
        $todoObject.FormattedText = Add-ForegroundColor -Color DarkGray -Text $Text
    } else {
        $todoObject.FormattedText = $Text.Split(' ') |
        ForEach-Object {
            if ($_ -match '^@\S+') {
                $formatted = Add-ForegroundColor -Color Green -Text $_
                $todoObject.Contexts += $_
            } elseif ($_ -match '^\+\S+') {
                $formatted = Add-ForegroundColor -Color DarkBlue -Text $_
                $todoObject.Projects += $_
            } elseif ($_ -match '^\S+:\S+') {
                $formatted = Add-ForegroundColor -Color Magenta -Text $_
                $todoObject.KeyValues += $_
            } elseif ($_ -match '^(19\d\d|20\d\d)-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])') {
                $formatted = Add-ForegroundColor -Color Cyan -Text $_
            } elseif ($_ -match '^\([A-Z]\)') {
                if ("A" -eq $todoObject.Priority) {
                    $priorityColor = [AnsiColors]::DarkRed
                } elseif ("B" -eq $todoObject.Priority) {
                    $priorityColor = [AnsiColors]::Red
                } elseif ("C" -eq $todoObject.Priority) {
                    $priorityColor = [AnsiColors]::Yellow
                } elseif ("D" -eq $todoObject.Priority) {
                    $priorityColor = [AnsiColors]::Blue
                } else {
                    $priorityColor = [AnsiColors]::LightGray
                }
                $formatted = Add-ForegroundColor -Color $priorityColor -Text $_
            } else {
                $formatted = $_
            }
            $formatted
        } | Join-String -Separator ' '
    }

    $todoObject
}

function Show-TodoTxt {
    $lineNo = 0
    $todoList = Get-Content $HOME\todo.txt |
        ForEach-Object {
            $lineNo++
            ConvertTo-TodoObject $lineNo $_
        }
    $todoCount = $todoList.Count
    $padLength = [Math]::Floor([Math]::Log10($todoCount)) + 1
    $todoList |
        Sort-Object -Property Id |
        ForEach-Object {
            $paddedTodoId = "$($_.Id)".PadLeft($padLength)
            Write-Output "$paddedTodoId $($_.FormattedText)"
        }
}

Export-ModuleMember -Function Show-TodoTxt