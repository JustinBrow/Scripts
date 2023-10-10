#Requires -Version 5.0

using namespace System
using namespace System.Drawing
using namespace System.Threading
using namespace System.Reflection
using namespace System.Diagnostics
using namespace System.Windows.Forms

$APIs = @"
   using System;
   using System.Drawing;
   using System.Runtime.InteropServices;

   namespace System
   {
      public class Shell32
      {
         public static Icon ExtractIcon(string file, int number, bool largeIcon)
         {
            IntPtr large;
            IntPtr small;
            ExtractIconEx(file, number, out large, out small, 1);
            try
            {
               return Icon.FromHandle(largeIcon ? large : small);
            }
            catch
            {
               return null;
            }
         }
         [DllImport("Shell32.dll", EntryPoint = "ExtractIconExW", CharSet = CharSet.Unicode, ExactSpelling = true, CallingConvention = CallingConvention.StdCall)]
         private static extern int ExtractIconEx(string sFile, int iIndex, out IntPtr piLargeVersion, out IntPtr piSmallVersion, int amountIcons);
      }

      public class User32
      {
         public const int SW_HIDE = 0;
         public const int SW_SHOWNOACTIVATE = 4;

         [DllImport("user32.dll")]
         public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);

         [DllImport("user32.dll", SetLastError = true)]
         static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, SetWindowPosFlags uFlags);

         static readonly IntPtr HWND_TOPMOST = new IntPtr(-1);

         [Flags]
         enum SetWindowPosFlags : uint
         {
            NoSize = 0x0001,
            NoMove = 0x0002,
            NoActivate = 0x0010
         }

         public static void SetAlwaysTop(IntPtr hWnd)
         {
            SetWindowPos(hWnd, HWND_TOPMOST, 0, 0, 0, 0, SetWindowPosFlags.NoActivate | SetWindowPosFlags.NoSize | SetWindowPosFlags.NoMove);
         }
      }
   }
"@

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type -TypeDefinition $APIs -ReferencedAssemblies System.Drawing

[void][System.User32]::ShowWindowAsync((Get-Process -PID $PID).MainWindowHandle, [System.User32]::SW_HIDE)

$MapleProcesses = [Process]::GetProcessesByName('MapleStory')

if (-not $MapleProcesses)
{
   $result = [Messagebox]::Show('MapleStory is not running! Run MushroomMon anyway?', 'MushroomMon',
                                [MessageBoxButtons]::YesNo,
                                [MessageBoxIcon]::Asterisk,
                                [MessageBoxDefaultButton]::Button2)
   if ($result -eq [DialogResult]::No)
   {
      Exit
   }
}

if ($MapleProcesses.Count -ge 2)
{
   [Messagebox]::Show("You're running more than one instance of MapleStory. Hacker :'(")
}
else
{
   $hash = [hashtable]::Synchronized(@{})
   $hash.Flag = $true

   $Runspace = [runspacefactory]::CreateRunspace()
   $Runspace.ApartmentState = [ApartmentState]::STA
   $Runspace.Open()
   $Runspace.SessionStateProxy.SetVariable('Hash', $hash)

   $ScriptBlock = `
   {
      $Definition = @"
         using System;
         using System.IO;
         using System.Linq;
         using System.Diagnostics;

         namespace System.Diagnostics
         {
            public class PerformanceCounterHelper
            {
               public static string GetInstanceNameForProcessId(int processId)
               {
                  var process = Process.GetProcessById(processId);
                  string processName = Path.GetFileNameWithoutExtension(process.ProcessName);

                  PerformanceCounterCategory cat = new PerformanceCounterCategory("Process");
                  string[] instances = cat.GetInstanceNames()
                     .Where(inst => inst.StartsWith(processName))
                     .ToArray();

                  foreach (string instance in instances)
                  {
                     using (PerformanceCounter cnt = new PerformanceCounter("Process",
                        "ID Process", instance, true))
                     {
                        int val = (int)cnt.RawValue;
                        if (val == processId)
                        {
                           return instance;
                        }
                     }
                  }
                  return null;
               }
            }
         }
"@
      Add-Type -TypeDefinition $Definition

      $timer = [System.Windows.Forms.Timer]::new()
      $timer.Interval = 1 * 1000
      $timer.add_Tick({
         $form.Close()
      })

      $label = [System.Windows.Forms.Label]::new()
      $label.AutoSize = $true
      $label.Text = "Memory leaking. Crash imminent!"
      $label.Font = [System.Drawing.Font]::new($label.Font.Name, 14, $label.Font.Style)
      $label.Location = [System.Drawing.Point]::new(30, 20)

      $form = [System.Windows.Forms.Form]::new()
      $form.MinimizeBox = $false
      $form.MaximizeBox = $false
      $form.Text = "MushroomMon Alert"
      $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
      $form.Icon = [System.Shell32]::ExtractIcon('C:\Windows\System32\imageres.dll', 93, $true)
      $form.Size = [System.Drawing.Size]::new(454, 97)
      $form.controls.Add($label)
      $form.add_Load({
         $timer.Start()
      })
      $form.add_Shown({
         [void][System.User32]::ShowWindowAsync($form.Handle, [System.User32]::SW_SHOWNOACTIVATE)
         [System.User32]::SetAlwaysTop($form.Handle)
      })
      $form.add_Closing({
         $timer.Stop()
      })

      $player = [System.Media.SoundPlayer]::new('C:\Windows\Media\Windows Background.wav')

      while ($hash.Flag)
      {
         $Proc = [System.Diagnostics.Process]::GetProcessesByName('MapleStory')
         $Proc = $Proc | Where-Object {$_.WorkingSet -eq [Linq.Enumerable]::Max([int[]]$Proc.WorkingSet)}

         $Instance = [System.Diagnostics.PerformanceCounterHelper]::GetInstanceNameForProcessId($proc.Id)

         $counter = [System.Diagnostics.PerformanceCounter]::new("Process", "Working Set - Private", $Instance)

         try
         {
            $usage = $counter.NextValue()
            $usage = [math]::Floor($usage / [math]::Pow(1024, 2))
         }
         catch
         {
            $usage = 0
         }

         if ($usage -ge 3300)
         {
            $label.Text = "Memory leaking `($usage MB`). Crash imminent!"
            $player.Play()
            $form.ShowDialog()
         }

         [System.Threading.Thread]::Sleep(4000)
      }

      $counter.Close()
      $form.Close()
      $form.Dispose()
   }

   $Job = [powershell]::Create()
   $Job.Runspace = $Runspace
   [void]$Job.AddScript($ScriptBlock, $true)
   $handle = $Job.BeginInvoke()

   if (Test-Path $env:APPDATA\NexonLauncher\installed-apps.db)
   {
      $NexonApps = Get-Content $env:APPDATA\NexonLauncher\installed-apps.db | ConvertFrom-Json
      $MapleStoryExe = ($NexonApps.installedApps.10100).installPath + '\MapleStory.exe'
      $icon = [Icon]::ExtractAssociatedIcon($MapleStoryExe)
   }
   elseif ([Process]::GetProcessesByName('Steam'))
   {
      $SteamProcesses = [Process]::GetProcessesByName('Steam')
      $SteamDir = $SteamProcesses[0].Path | Split-Path
      $MapleStoryExe = $SteamDir + '\SteamApps\common\MapleStory\MapleStory.exe'
      $icon = [Icon]::ExtractAssociatedIcon($MapleStoryExe)
   }
   else
   {
      $icon = [Icon]::ExtractAssociatedIcon("$PSHOME\PowerShell.exe")
   }

   $ExitAction = [PSCustomObject]@{
      Text = 'E&xit'
      Action = {
         $hash.Flag = $false
         $NotifyIcon.Visible = $false
         while ($handle.IsCompleted -notcontains $true)
         {
            [Thread]::Sleep(1000)
         }
         $Job.Stop()
         $Runspace.Close()
         $Runspace.Dispose()
         $NotifyIcon.Dispose()
         $appContext.ExitThread()
         $appContext.Dispose()
      }
   }

   $SteamLaunch = [PSCustomObject]@{
      Text = '&Launch (Steam)'
      Action = {
         try { [Process]::Start('steam://rungameid/216150') }
         catch { [Messagebox]::Show('Failed to launch via Steam.') }
      }
   }

   $EndMaple = [PSCustomObject]@{
      Text = '&End MapleStory'
      Action = {
         try { [Process]::GetProcessesByName('MapleStory').Kill() }
         catch { [Messagebox]::Show("Failed to close MapleStory or MapleStory isn't running.") }
      }
   }

   $L_ClickMenu = [ContextMenu]::new()
   [void]$L_ClickMenu.MenuItems.Add([MenuItem]::new($SteamLaunch.Text, $SteamLaunch.Action))
   [void]$L_ClickMenu.MenuItems.Add([MenuItem]::new($EndMaple.Text, $EndMaple.Action))
   [void]$L_ClickMenu.MenuItems.Add([MenuItem]::new($ExitAction.Text, $ExitAction.Action))

   $R_ClickMenu = [ContextMenu]::new()
   [void]$R_ClickMenu.MenuItems.Add([MenuItem]::new($SteamLaunch.Text, $SteamLaunch.Action))
   [void]$R_ClickMenu.MenuItems.Add([MenuItem]::new($EndMaple.Text, $EndMaple.Action))
   [void]$R_ClickMenu.MenuItems.Add([MenuItem]::new($ExitAction.Text, $ExitAction.Action))

   $NotifyIcon = [NotifyIcon]::new()
   $NotifyIcon.Text = 'Mushroom Game RAM Monitor'
   $NotifyIcon.Icon = $icon
   $NotifyIcon.ContextMenu = $R_ClickMenu
   $NotifyIcon.add_MouseDown({
      if ($_.Button -eq [MouseButtons]::Left)
      {
         $NotifyIcon.ContextMenu = $L_ClickMenu
         $NotifyIcon.GetType().GetMethod("ShowContextMenu", [BindingFlags]::Instance -bor [BindingFlags]::NonPublic).Invoke($NotifyIcon, $null)
      }
      elseif ($_.Button -eq [MouseButtons]::Right)
      {
         $NotifyIcon.ContextMenu = $R_ClickMenu
      }
      elseif ($_.Button -eq [MouseButtons]::Middle)
      {
         & $ExitAction.Action
      }
   })
   $NotifyIcon.Visible = $true

   $appContext = [ApplicationContext]::new()
   [Application]::Run($appContext)
}
