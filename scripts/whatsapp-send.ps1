# GPR SLP INVITE - WhatsApp Desktop send button automation.
# Only click after verifying the expected message in the active WhatsApp composer.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -AssemblyName System.Windows.Forms
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class WhatsAppInput {
    [StructLayout(LayoutKind.Sequential)]
    public struct Point { public int X; public int Y; }
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr window, out uint processId);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern bool GetCursorPos(out Point point);
    [DllImport("user32.dll")] public static extern void mouse_event(uint flags, uint dx, uint dy, uint data, UIntPtr extraInfo);
}
'@

function Normalize-Text([string]$text) {
    return [regex]::Replace($text, '[\s\u200B-\u200D\uFEFF]+', ' ').Trim()
}

function Read-Text($element) {
    try {
        $value = $element.GetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern)
        if ($null -ne $value) { return [string]$value.Current.Value }
    } catch {}
    try {
        $text = $element.GetCurrentPattern([System.Windows.Automation.TextPattern]::Pattern)
        if ($null -ne $text) { return [string]$text.DocumentRange.GetText(-1) }
    } catch {}
    try {
        $legacy = $element.GetCurrentPattern([System.Windows.Automation.LegacyIAccessiblePattern]::Pattern)
        if ($null -ne $legacy) { return [string]$legacy.Current.Value }
    } catch {}
    return ''
}

function Test-ComposerClipboard($window, [string]$expected) {
    # The Store version of WhatsApp often does not expose its text to UI Automation.
    # Read the selected text via the normal clipboard, but only send after an exact match.
    $originalClipboard = $null
    $hadClipboard = $false
    try {
        try {
            $originalClipboard = [System.Windows.Forms.Clipboard]::GetDataObject()
            $hadClipboard = $null -ne $originalClipboard
        } catch {}
        $rect = $window.Current.BoundingRectangle
        if ($rect.IsEmpty -or $rect.Width -lt 400 -or $rect.Height -lt 350) { return $false }
        # WhatsApp's message composer is at the bottom of the conversation pane.
        # Clicking near its middle avoids the send and attachment controls.
        $x = [int]($rect.Left + $rect.Width * 0.65)
        $y = [int]($rect.Bottom - 72)
        $old = New-Object WhatsAppInput+Point
        [void][WhatsAppInput]::GetCursorPos([ref]$old)
        try {
            [void][WhatsAppInput]::SetCursorPos($x, $y)
            Start-Sleep -Milliseconds 90
            [WhatsAppInput]::mouse_event(2, 0, 0, 0, [UIntPtr]::Zero)
            Start-Sleep -Milliseconds 50
            [WhatsAppInput]::mouse_event(4, 0, 0, 0, [UIntPtr]::Zero)
        } finally {
            [void][WhatsAppInput]::SetCursorPos($old.X, $old.Y)
        }
        Start-Sleep -Milliseconds 120
        [System.Windows.Forms.Clipboard]::Clear()
        [System.Windows.Forms.SendKeys]::SendWait('^a')
        Start-Sleep -Milliseconds 100
        [System.Windows.Forms.SendKeys]::SendWait('^c')
        Start-Sleep -Milliseconds 220
        $copied = Normalize-Text ([System.Windows.Forms.Clipboard]::GetText())
        [System.Windows.Forms.SendKeys]::SendWait('{RIGHT}')
        return ($copied -eq $expected)
    } catch {
        return $false
    } finally {
        try {
            if ($hadClipboard) {
                [System.Windows.Forms.Clipboard]::SetDataObject($originalClipboard, $true)
            } else {
                [System.Windows.Forms.Clipboard]::Clear()
            }
        } catch {}
    }
}

function Find-SendButton($window, $composer) {
    $condition = [System.Windows.Automation.OrCondition]::new(
        [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Button),
        [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Custom)
    )
    $composerRect = $composer.Current.BoundingRectangle
    if ($composerRect.IsEmpty -or $composerRect.Width -lt 60) { return $null }
    $controls = $window.FindAll([System.Windows.Automation.TreeScope]::Descendants, $condition)
    $candidates = @()
    foreach ($button in $controls) {
        try {
            if (-not $button.Current.IsEnabled -or $button.Current.IsOffscreen) { continue }
            $rect = $button.Current.BoundingRectangle
            if ($rect.IsEmpty -or $rect.Width -lt 8 -or $rect.Height -lt 8) { continue }
            $label = @($button.Current.Name, $button.Current.AutomationId, $button.Current.HelpText) -join ' '
            if ($label -notmatch '(?i)(^|[^a-z])(send|verzend(?:en)?|verstuur|versturen|senden)([^a-z]|$)') { continue }
            if ($label -match '(?i)(search|zoeken|forward|doorsturen|attachment|bijlage|contact|location|locatie|audio|voice|spraak)') { continue }
            $midX = $rect.Left + ($rect.Width / 2)
            $midY = $rect.Top + ($rect.Height / 2)
            $composerY = $composerRect.Top + ($composerRect.Height / 2)
            if ($midX -lt ($composerRect.Left + $composerRect.Width * 0.60)) { continue }
            if ($midX -gt ($composerRect.Right + 175)) { continue }
            if ([Math]::Abs($midY - $composerY) -gt 95) { continue }
            $candidates += @{ Element=$button; Distance=[Math]::Abs($midY - $composerY) + [Math]::Abs($midX - $composerRect.Right) * 0.15 }
        } catch {}
    }
    if ($candidates.Count -eq 0) { return $null }
    return ($candidates | Sort-Object Distance | Select-Object -First 1).Element
}

function Click-SendButton($button, [IntPtr]$expectedForeground) {
    if ([WhatsAppInput]::GetForegroundWindow() -ne $expectedForeground) { return 'FOCUS_CHANGED' }
    try {
        $pattern = $button.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
        if ($null -ne $pattern) {
            $pattern.Invoke()
            return 'CLICKED:INVOKE'
        }
    } catch {}
    try {
        $point = $button.GetClickablePoint()
        if ([WhatsAppInput]::GetForegroundWindow() -ne $expectedForeground) { return 'FOCUS_CHANGED' }
        $old = New-Object WhatsAppInput+Point
        [void][WhatsAppInput]::GetCursorPos([ref]$old)
        if (-not [WhatsAppInput]::SetCursorPos([int]$point.X, [int]$point.Y)) { return 'CLICK_FAILED' }
        Start-Sleep -Milliseconds 100
        [WhatsAppInput]::mouse_event(2, 0, 0, 0, [UIntPtr]::Zero)
        Start-Sleep -Milliseconds 65
        [WhatsAppInput]::mouse_event(4, 0, 0, 0, [UIntPtr]::Zero)
        [void][WhatsAppInput]::SetCursorPos($old.X, $old.Y)
        return 'CLICKED:MOUSE'
    } catch {
        return 'CLICK_FAILED'
    }
}

try {
    if (-not $env:GPR_WA_MESSAGE_B64) { Write-Output 'MESSAGE_MISSING'; exit 2 }
    $message = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($env:GPR_WA_MESSAGE_B64))
    $expected = Normalize-Text $message
    if ($expected.Length -lt 15) { Write-Output 'MESSAGE_TOO_SHORT'; exit 2 }

    $deadline = (Get-Date).AddSeconds(16)
    $foundWhatsApp = $false
    $foundComposer = $false
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 600
        $handle = [WhatsAppInput]::GetForegroundWindow()
        if ($handle -eq [IntPtr]::Zero) { continue }
        [uint32]$processId = 0
        [void][WhatsAppInput]::GetWindowThreadProcessId($handle, [ref]$processId)
        $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
        if ($null -eq $process) { continue }
        $window = [System.Windows.Automation.AutomationElement]::FromHandle($handle)
        if ($null -eq $window) { continue }
        $windowTitle = [string]$window.Current.Name
        if ($process.ProcessName -notmatch '(?i)WhatsApp' -and $windowTitle -notmatch '(?i)WhatsApp') { continue }
        $foundWhatsApp = $true
        try {
            if (-not (Test-ComposerClipboard $window $expected)) { continue }
            $foundComposer = $true
            if ([WhatsAppInput]::GetForegroundWindow() -ne $handle) { continue }
            # The exact draft is verified. Enter is the same action the operator
            # already confirmed works manually on this WhatsApp installation.
            [System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
            Write-Output 'CLICKED:VERIFIED_ENTER'
            exit 0
        } catch {
            # WhatsApp redraws its UI as the conversation opens.
        }
    }
    if (-not $foundWhatsApp) { Write-Output 'WHATSAPP_NOT_FOREGROUND' }
    elseif (-not $foundComposer) { Write-Output 'COMPOSER_NOT_VERIFIED' }
    else { Write-Output 'SEND_BUTTON_NOT_FOUND' }
    exit 3
} catch {
    Write-Output ('AUTOMATION_ERROR:' + $_.Exception.Message)
    exit 4
}
