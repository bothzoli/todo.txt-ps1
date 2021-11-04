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
        CreationDate = $creationDate
        CompletionDate = $completionDate
        Contexts = @()
        Projects = @()
        FormattedText = ""
        Priority = $Matches.Priority
        Done = [bool]$Matches.Done
    }

    if ($todoObject.Done) {
        $formattedText = Add-ForegroundColor -Color DarkGray -Text $Text
    } else {
        $formattedText = $Text.Split(' ') |
        ForEach-Object {
            if ($_ -match '^@\S+') {
                $formatted = Add-ForegroundColor -Color Green -Text $_
                $todoObject.Contexts += $_
            } elseif ($_ -match '^\+\S+') {
                $formatted = Add-ForegroundColor -Color Red -Text $_
                $todoObject.Projects += $_
            } elseif ($_ -match '^\S+:\S+') {
                $formatted = Add-ForegroundColor -Color DarkBlue -Text $_
            } elseif ($_ -match '^(19\d\d|20\d\d)-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])') {
                $formatted = Add-ForegroundColor -Color DarkCyan -Text $_
            } elseif ($_ -match '^\((?<Priority>[A-Z])\)') {
                if ("A" -eq $Matches.Priority) {
                    $formatted = Add-ForegroundColor -Color Red -Text $_
                } elseif ("B" -eq $Matches.Priority) {
                    $formatted = Add-ForegroundColor -Color DarkRed -Text $_
                } elseif ("C" -eq $Matches.Priority) {
                    $formatted = Add-ForegroundColor -Color Yellow -Text $_
                } elseif ("D" -eq $Matches.Priority) {
                    $formatted = Add-ForegroundColor -Color Blue -Text $_
                } else {
                    $formatted = $_
                }
            } else {
                $formatted = $_
            }
            $formatted
        } | Join-String -Separator ' '
    }
    
    $todoObject.FormattedText = $formattedText

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