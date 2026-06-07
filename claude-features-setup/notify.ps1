param(
    [string]$Title = "Claude Code",
    [string]$Message = "Needs your attention"
)

# Check if terminal window is in the foreground
# If yes, user is watching - no notification needed
try {
    Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class Win32 {
        [DllImport("user32.dll")]
        public static extern IntPtr GetForegroundWindow();

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder lpString, int nMaxCount);

        [DllImport("user32.dll")]
        public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    }
"@ -ErrorAction SilentlyContinue

    $fgWindow = [Win32]::GetForegroundWindow()
    $processId = 0
    [Win32]::GetWindowThreadProcessId($fgWindow, [ref]$processId) | Out-Null
    $fgProcess = Get-Process -Id $processId -ErrorAction SilentlyContinue

    $terminalNames = @('WindowsTerminal', 'cmd', 'powershell', 'pwsh', 'conhost', 'Code')
    if ($fgProcess -and $fgProcess.ProcessName -in $terminalNames) {
        exit 0
    }
} catch {}

# Method 1: BurntToast (auto-dismiss, no click needed)
try {
    Import-Module BurntToast -ErrorAction Stop
    New-BurntToastNotification -Text $Title, $Message
    exit 0
} catch {}

# Method 2: Console beep fallback
[console]::beep(1000, 200)
[console]::beep(1200, 200)
[console]::beep(1500, 400)
