using namespace Microsoft.PowerShell.EditorServices.Protocol.MessageProtocol
using namespace Microsoft.PowerShell.EditorServices.Protocol.Messages
using namespace Microsoft.PowerShell.EditorServices

# All of this is lifted from Brandon Padgett's blog:
# http://brandonpadgett.com/vscode/VSCode-Presentations/

function ReadInputPrompt
{
    param([string]$Prompt)
    end
    {
        $result = $psEditor.Components.Get([IMessageSender]).SendRequest([ShowInputPromptRequest]::Type,[ShowInputPromptRequest]@{
            Name  = $Prompt
            Label = $Prompt
        },$true).Result

        if (-not $result.PromptCanceled)
        {
            $result.ResponseText
        }
    }
}
function ReadChoicePrompt
{
    param([string]$Prompt, [System.Management.Automation.Host.ChoiceDescription[]]$Choices)
    end
    {
        $choiceIndex = 0
        $convertedChoices = $Choices.ForEach{
            $newLabel = '{0} - {1}' -f ($choiceIndex + 1), $_.Label
            [ChoiceDetails]::new($newLabel, $_.HelpMessage)
            $choiceIndex++
        } -as [ChoiceDetails[]]

        $result = $psEditor.Components.Get([IMessageSender]).SendRequest([ShowChoicePromptRequest]::Type,[ShowChoicePromptRequest]@{
                Caption        = $Prompt
                Message        = $Prompt
                Choices        = $convertedChoices
                DefaultChoices = 0
            },$true).Result

        if (-not $result.PromptCanceled)
        {
            $result.ResponseText | Select-String '^(\d+) - ' | ForEach-Object { $_.Matches.Groups[1].Value - 1 }
        }
    }
}

Register-EditorCommand `
    -Name 'Speed.OpenDemo' `
    -DisplayName '#PSHSummit Speed: Open Demo' `
    -SuppressOutput `
    -ScriptBlock {
        param([Microsoft.PowerShell.EditorServices.Extensions.EditorContext]$context)

        $Demos = Get-ChildItem -Path 'C:\Users\joshuak\OneDrive\PS Summit\Presentation - Speed\Demos\*.ps1'

        $Choices = [System.Management.Automation.Host.ChoiceDescription[]] @($Demos.Name)
        $Selection = ReadChoicePrompt -Prompt "Please Select a Demo" -Choices $Choices
        $Name = $Demos[$Selection]

        $psEditor.Workspace.OpenFile($Name)
        & $Name
    }
