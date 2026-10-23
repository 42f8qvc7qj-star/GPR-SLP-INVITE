# GPR SLP INVITE - focus WhatsApp composer and send with Enter.
# No clipboard inspection or message comparison.
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

function Focus-WhatsAppComposer($window, [IntPtr]$expectedHandle) {
    if ([WhatsAppInput]::GetForegroundWindow() -ne $expectedHandle) { return $false }
    $rect = $window.Current.BoundingRectangle
    if ($rect.IsEmpty -or $rect.Width -lt 400 -or $rect.Height -lt 350) { return $false }
    $x = [int]($rect.Left + $rect.Width * 0.65)
    $y = [int]($rect.Bottom - 72)
    $old = New-Object WhatsAppInput+Point
    [void][WhatsAppInput]::GetCursorPos([ref]$old)
    try {
        if (-not [WhatsAppInput]::SetCursorPos($x, $y)) { return $false }
        Start-Sleep -Milliseconds 100
        [WhatsAppInput]::mouse_event(2, 0, 0, 0, [UIntPtr]::Zero)
        Start-Sleep -Milliseconds 60
        [WhatsAppInput]::mouse_event(4, 0, 0, 0, [UIntPtr]::Zero)
    } finally {
        [void][WhatsAppInput]::SetCursorPos($old.X, $old.Y)
    }
    Start-Sleep -Milliseconds 200
    return ([WhatsAppInput]::GetForegroundWindow() -eq $expectedHandle)
}

try {
    $deadline = (Get-Date).AddSeconds(15)
    $foundWhatsApp = $false
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
        # Give the WhatsApp URI handler time to open the conversation and fill the draft.
        Start-Sleep -Milliseconds 1300
        if (-not (Focus-WhatsAppComposer $window $handle)) { continue }
        [System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
        Write-Output 'CLICKED:FOCUSED_ENTER'
        exit 0
    }
    if ($foundWhatsApp) { Write-Output 'COMPOSER_FOCUS_FAILED' }
    else { Write-Output 'WHATSAPP_NOT_FOREGROUND' }
    exit 3
} catch {
    Write-Output ('AUTOMATION_ERROR:' + $_.Exception.Message)
    exit 4
}
