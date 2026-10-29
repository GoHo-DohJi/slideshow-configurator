```shell
Usage: slideshow-configurator.exe --path <folder> [options]

Options:
  --path <path>       Absolute path to folder with images (required)
  --position <pos>    center|tile|stretch|fit|fill|span (default: fill)
  --interval <sec>    Slideshow interval in seconds (default: 1800)
  --shuffle           Enable shuffle (disabled by default)
  --help              Show this help message
```


# Slideshow Configurator

Set Windows desktop wallpaper slideshow directly from PowerShell — no installation required.

## Quick Start

Open **PowerShell** and run:

```shell
& ([scriptblock]::Create((irm "https://raw.githubusercontent.com/GoHo-DohJi/slideshow-configurator/main/RUN.ps1"))) -path "C:\Users\gohodoji\Pictures\Wallpapers"
```

> [!NOTE]
> Administrator privileges are **not** required. Wallpaper is a per-user setting.

## Usage

```shell
$url = "https://raw.githubusercontent.com/GoHo-DohJi/slideshow-configurator/main/RUN.ps1"
$run = [scriptblock]::Create((irm $url))

# Basic — set slideshow folder
& $run -path "C:\Users\gohodoji\Pictures\Wallpapers"

# Custom position and interval
& $run -path "D:\Wallpapers" -position fill -interval 600

# Enable shuffle
& $run -path "D:\Wallpapers" -interval 300 -shuffle

# All options
& $run -path "D:\Wallpapers" -position fit -interval 900 -shuffle

# Help
& $run -help
```

## Arguments

| Flag | Description | Default |
|------|-------------|---------|
| `-path <path>` | Absolute path to folder with images (**required**) | — |
| `-position <pos>` | `center`, `tile`, `stretch`, `fit`, `fill`, `span` | `fill` |
| `-interval <sec>` | Slideshow interval in seconds | `1800` (30 min) |
| `-shuffle` | Enable random image order | disabled |
| `-help` | Show usage information | — |

## How It Works

Uses the Windows `IDesktopWallpaper` COM interface to:

1. Create a shell item array from the target folder
2. Set it as the active slideshow source
3. Configure position, interval, and shuffle options

Changes are applied immediately and persist across reboots.
