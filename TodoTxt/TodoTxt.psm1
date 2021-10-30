. $PSScriptRoot\AnsiColors.ps1

function ConvertTo-TodoObject {
    param (
        [int]$TodoId,
        [string]$Text
    )
    
    $todoObject = @{
        Id = $TodoId
        Text = $Text
        Contexts = @()
        Projects = @()
        FormattedText = ""
    }

    $formattedText = $Text.Split(' ') |
        ForEach-Object {
            if ($_ -match '^@\w+') {
                $formatted = Add-ForegroundColor -Color Green -Text $_
                $todoObject.Contexts += $_
            } elseif ($_ -match '^\+\w+') {
                $formatted = Add-ForegroundColor -Color Red -Text $_
                $todoObject.Projects += $_
            } else {
                $formatted = $_
            }
            $formatted
        } | Join-String -Separator ' '
    
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