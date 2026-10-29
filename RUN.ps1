# Parse Arguments #
$path     = ""
$position = "fill"
$interval = 1800
$shuffle  = $false

for ($i = 0; $i -lt $args.Count; $i++) {
    $a = $args[$i]
    if ($a -match "^-{1,2}help$") {
        Write-Host "Usage: script.ps1 -path <folder> [options]"
        Write-Host ""
        Write-Host "Options:"
        Write-Host "  -path <path>       Absolute path to folder with images (required)"
        Write-Host "  -position <pos>    center|tile|stretch|fit|fill|span (default: fill)"
        Write-Host "  -interval <sec>    Slideshow interval in seconds (default: 1800)"
        Write-Host "  -shuffle           Enable shuffle (disabled by default)"
        Write-Host "  -help              Show this help message"
        return
    } elseif ($a -match "^-{1,2}path$" -and ($i + 1) -lt $args.Count) {
        $path = $args[++$i]
    } elseif ($a -match "^-{1,2}position$" -and ($i + 1) -lt $args.Count) {
        $position = $args[++$i]
    } elseif ($a -match "^-{1,2}interval$" -and ($i + 1) -lt $args.Count) {
        $interval = [uint32]$args[++$i]
    } elseif ($a -match "^-{1,2}shuffle$") {
        $shuffle = $true
    }
}

if (-not $path) {
    Write-Host "Error: -path is required. Use -help for usage."
    return
}

if (-not [System.IO.Path]::IsPathRooted($path)) {
    Write-Host "Error: Path must be absolute (e.g. C:\Pictures)"
    return
}

if (-not (Test-Path -Path $path -PathType Container)) {
    Write-Host "Error: Directory not found: $path"
    return
}

$posMap = @{ "center" = 0; "tile" = 1; "stretch" = 2; "fit" = 3; "fill" = 4; "span" = 5 }

if (-not $posMap.ContainsKey($position)) {
    Write-Host "Error: Invalid position. Use: center|tile|stretch|fit|fill|span"
    return
}

# COM Interop #
try { [WP.Wallpaper] | Out-Null } catch {
    Add-Type -TypeDefinition @"
namespace WP {
using System;
using System.Runtime.InteropServices;

public class Wallpaper {
    [ComImport, Guid("B92B56A9-8B55-4E14-9A89-0199BBB6F93B")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IDesktopWallpaper {
        void SetWallpaper([MarshalAs(UnmanagedType.LPWStr)] string monitorID, [MarshalAs(UnmanagedType.LPWStr)] string wallpaper);
        [return: MarshalAs(UnmanagedType.LPWStr)]
        string GetWallpaper([MarshalAs(UnmanagedType.LPWStr)] string monitorID);
        [return: MarshalAs(UnmanagedType.LPWStr)]
        string GetMonitorDevicePathAt(uint monitorIndex);
        uint GetMonitorDevicePathCount();
        void GetMonitorRECT([MarshalAs(UnmanagedType.LPWStr)] string monitorID, out RECT displayRect);
        void SetBackgroundColor(uint color);
        uint GetBackgroundColor();
        void SetPosition(int position);
        int GetPosition();
        void SetSlideshow(IntPtr items);
        IntPtr GetSlideshow();
        void SetSlideshowOptions(int options, uint slideshowTick);
        void GetSlideshowOptions(out int options, out uint slideshowTick);
        void AdvanceSlideshow([MarshalAs(UnmanagedType.LPWStr)] string monitorID, int direction);
        int GetStatus();
        void Enable([MarshalAs(UnmanagedType.Bool)] bool enable);
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left, Top, Right, Bottom; }

    [ComImport, Guid("C2CF3110-460E-4fc1-B9D0-8A1C0C9CC4BD")]
    public class DesktopWallpaperClass { }

    [DllImport("shell32.dll", CharSet = CharSet.Unicode, PreserveSig = false)]
    public static extern void SHCreateItemFromParsingName(string pszPath, IntPtr pbc, ref Guid riid, out IntPtr ppv);

    [DllImport("shell32.dll", PreserveSig = false)]
    public static extern void SHCreateShellItemArrayFromShellItem(IntPtr psi, ref Guid riid, out IntPtr ppv);

    public static void ApplySlideshow(string path, int position, uint intervalSec, bool shuffle) {
        IDesktopWallpaper wallpaper = (IDesktopWallpaper)new DesktopWallpaperClass();

        Guid iidItem = new Guid("43826d1e-e718-42ee-bc55-a1e261c37bfe");
        IntPtr pItem;
        SHCreateItemFromParsingName(path, IntPtr.Zero, ref iidItem, out pItem);

        Guid iidArray = new Guid("b63ea76d-1f85-456f-a19c-48159efa858b");
        IntPtr pArray;
        SHCreateShellItemArrayFromShellItem(pItem, ref iidArray, out pArray);
        Marshal.Release(pItem);

        wallpaper.SetSlideshow(pArray);
        Marshal.Release(pArray);

        wallpaper.SetPosition(position);
        wallpaper.SetSlideshowOptions(shuffle ? 1 : 0, intervalSec * 1000);
    }
}
}
"@
}

# Apply #
try {
    [WP.Wallpaper]::ApplySlideshow($path, $posMap[$position], [uint32]$interval, $shuffle)
    Write-Host "||| SUCCESS |||"
} catch {
    Write-Host "Error: $($_.Exception.Message)"
}
