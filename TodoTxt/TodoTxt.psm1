. $PSScriptRoot\AnsiColors.ps1

function ConvertTo-TodoObject {
    param (
        [int]$TodoId,
        [string]$Text
    )

    $Text -cmatch "^(?<Done>x )?(\((?<Priority>[A-Z])\) )?(?<FirstDate>(19\d\d|20\d\d)-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1]) )?((?<SecondDate>(19\d\d|20\d\d)-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])))?" | Out-Null

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
            if ($_ -cmatch '^@\S+') {
                $formatted = Add-ForegroundColor -Color Green -Text $_
                $todoObject.Contexts += $_
            } elseif ($_ -cmatch '^\+\S+') {
                $formatted = Add-ForegroundColor -Color DarkBlue -Text $_
                $todoObject.Projects += $_
            } elseif ($_ -cmatch '^\S+:\S+') {
                $formatted = Add-ForegroundColor -Color Magenta -Text $_
                $todoObject.KeyValues += $_
            } elseif ($_ -cmatch '^(19\d\d|20\d\d)-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])') {
                $formatted = Add-ForegroundColor -Color Cyan -Text $_
            } elseif ($_ -cmatch '^\([A-Z]\)') {
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
    param (
        [Parameter(Mandatory=$false)]
        [ValidateSet(“Id",”Text","Priority",”Projects”,"Contexts")]
        [string]
        $SortBy = "Text",
        [Parameter(Mandatory=$false)]
        [string]
        $Context,
        [Parameter(Mandatory=$false)]
        [string]
        $Project
    )
    $lineNo = 0
    $todoList = Get-Content $HOME\todo.txt |
        ForEach-Object {
            $lineNo++
            ConvertTo-TodoObject $lineNo $_
        }
    $todoCount = $todoList.Count
    $padLength = [Math]::Floor([Math]::Log10($todoCount)) + 1
    $todoList |
        Where-Object {
            if ($Project) {
                $_.Projects | Where-Object { $_ -match $Project }
            } else {
                $true
            }
        } |
        Where-Object {
            if ($Context) {
                $_.Contexts | Where-Object { $_ -match $Context }
            } else {
                $true
            }
        } |
        Sort-Object -Property {
            if ([bool]$_[$SortBy]) {
                $_[$SortBy]
            } else {
                "z"
            }
        } -Stable |
        ForEach-Object {
            $paddedTodoId = "$($_.Id)".PadLeft($padLength)
            Write-Output "$paddedTodoId $($_.FormattedText)"
        }
}

function Complete-TodoTxt {
    param (
        [Parameter(ValueFromPipeline)]
        [int[]]$TodoIds
    )
    $todoList = Get-Content $HOME\todo.txt
    $TodoIds | ForEach-Object {
        if (($_ -gt 0) -and ($_ -le $todoList.Count)) {
            if (-not $todoList[$_ - 1].StartsWith("x ")) {
                $todoList[$_ - 1] = "x $(Get-Date -Format 'yyyy-MM-dd') $($todoList[$_ - 1])"
            }
        }
    }
    $todoList | Set-Content $HOME\todo.txt
}

function Add-TodoTxt {
    param (
        [Parameter(ValueFromPipeline)]
        [string]$TodoText,
        [Parameter(Mandatory=$false)]
        [char]$Priority,
        [Parameter(Mandatory=$false)]
        [switch]$WithDate=$false
    )

    if ($Priority -and ($Priority -match "[A-Z]")) {
        $prio = "($(([string]$Priority).ToUpper())) "
    }
    if ($WithDate) {
        $date = "$(Get-Date -Format 'yyyy-MM-dd') "
    }

    (Get-Content $HOME\todo.txt) + "$prio$date$TodoText" | Set-Content $HOME\todo.txt
}

function Optimize-TodoTxt {
    (Get-Content $HOME\todo.txt | Where-Object { $_.StartsWith('x ') }) + (Get-Content $HOME\done.txt) |
        Set-Content $HOME\done.txt
    $activeTasks = Get-Content $HOME\todo.txt | Where-Object { !$_.StartsWith('x ') }
    if ($null -ne $activeTasks) {
        $activeTasks | Set-Content $HOME\todo.txt
    } else {
        Set-Content $HOME\todo.txt $null
    }
}

function Set-TodoTxtPriority {
    param (
        [Parameter(ValueFromPipeline)]
        [int]$TodoId,
        [Parameter(Mandatory=$false)]
        [char]$NewPriority
    )

    $newPriority = ([string]$NewPriority).ToUpper()

    $todoList = Get-Content $HOME\todo.txt
    if (($TodoId -gt 0) -and ($TodoId -le $todoList.Count)) {
        $todoToChange = $todoList[$TodoId - 1]

        $hasPriority = $todoToChange -cmatch "^\((?<Priority>[A-Z])\) "
        
        if ($newPriority -and ($newPriority -cmatch "[A-Z]")) {
            if ($hasPriority) {
                $todoToChange = $todoToChange -replace "^\([A-Z]\) ", "($newPriority) "
            } else {
                $todoToChange = "($newPriority) $todoToChange"
            }
        } elseif (!$newPriority) {
            if ($hasPriority) {
                $priority = [byte][char]$Matches.Priority
                if ($priority -gt 65) {
                    $bumpedPriority = [char]([byte][char]$Matches.Priority - 1)
                } else {
                    $bumpedPriority = $Matches.Priority
                }

                $todoToChange = $todoToChange -replace "^\([A-Z]\) ", "($bumpedPriority) "
            } else {
                $todoToChange = "(A) $todoToChange"
            }
        }
        $todoList[$TodoId - 1] = $todoToChange
        $todoList | Set-Content $HOME\todo.txt
    }
}

function Reset-TodoTxtPriority {
    param (
        [Parameter(ValueFromPipeline)]
        [int[]]$TodoIds
    )

    $todoList = Get-Content $HOME\todo.txt
    $TodoIds | ForEach-Object {
        if (($_ -gt 0) -and ($_ -le $todoList.Count)) {
            $todoToChange = $todoList[$_ - 1]
    
            if ($todoToChange -cmatch "^\((?<Priority>[A-Z])\) ") {
                $todoToChange = $todoToChange -replace "^\([A-Z]\) ", ""
            }
            $todoList[$_ - 1] = $todoToChange
        }
    }
    $todoList | Set-Content $HOME\todo.txt
}

Export-ModuleMember -Function Show-TodoTxt
Export-ModuleMember -Function Complete-TodoTxt
Export-ModuleMember -Function Add-TodoTxt
Export-ModuleMember -Function Optimize-TodoTxt
Export-ModuleMember -Function Set-TodoTxtPriority
Export-ModuleMember -Function Reset-TodoTxtPriority