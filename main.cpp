#include <windows.h>
#include <shobjidl.h>
#include <shlobj.h>
#include <iostream>
#include <string>
#include <filesystem>

#pragma comment(lib, "Ole32.lib")
#pragma comment(lib, "Shell32.lib")

void PrintUsage(const char* exe) {
    std::cout << "Usage: " << exe << " --path <folder> [options]\n\n"
              << "Options:\n"
              << "  --path <path>       Absolute path to folder with images (required)\n"
              << "  --position <pos>    center|tile|stretch|fit|fill|span (default: fill)\n"
              << "  --interval <sec>    Slideshow interval in seconds (default: 1800)\n"
              << "  --shuffle           Enable shuffle (disabled by default)\n"
              << "  --help              Show this help message\n";
}

int main(int argc, char* argv[]) {
    std::string path, position = "fill";
    UINT intervalSec = 1800;
    bool shuffle = false;

    // Parse arguments
    for (int i = 1; i < argc; i++) {
        std::string arg = argv[i];
        if (arg == "--help")                        { PrintUsage(argv[0]); return 0; }
        if (arg == "--path"     && i + 1 < argc)    { path = argv[++i];     continue; }
        if (arg == "--position" && i + 1 < argc)    { position = argv[++i]; continue; }
        if (arg == "--interval" && i + 1 < argc)    { intervalSec = std::stoul(argv[++i]); continue; }
        if (arg == "--shuffle")                     { shuffle = true;       continue; }
    }

    if (path.empty()) { PrintUsage(argv[0]); return 1; }

    // Validate path
    std::filesystem::path fsPath(path);
    if (!fsPath.is_absolute()) {
        std::cerr << "Error: Path must be absolute (e.g. C:\\Pictures)\n";
        return 1;
    }
    if (!std::filesystem::is_directory(fsPath)) {
        std::cerr << "Error: Directory not found: " << path << "\n";
        return 1;
    }

    // Map position string to enum
    DESKTOP_WALLPAPER_POSITION pos;
    if      (position == "center")  pos = DWPOS_CENTER;
    else if (position == "tile")    pos = DWPOS_TILE;
    else if (position == "stretch") pos = DWPOS_STRETCH;
    else if (position == "fit")     pos = DWPOS_FIT;
    else if (position == "fill")    pos = DWPOS_FILL;
    else if (position == "span")    pos = DWPOS_SPAN;
    else {
        std::cerr << "Error: Invalid position. Use: center|tile|stretch|fit|fill|span\n";
        return 1;
    }

    // Initialize COM
    CoInitialize(nullptr);

    IDesktopWallpaper* pWall = nullptr;
    HRESULT hr = CoCreateInstance(__uuidof(DesktopWallpaper), nullptr,
                                  CLSCTX_ALL, IID_PPV_ARGS(&pWall));
    if (FAILED(hr)) {
        std::cerr << "Error: Failed to create IDesktopWallpaper\n";
        CoUninitialize(); return 1;
    }

    // Create shell item array from folder
    std::wstring wpath = fsPath.wstring();
    IShellItem* pItem = nullptr;
    hr = SHCreateItemFromParsingName(wpath.c_str(), nullptr, IID_PPV_ARGS(&pItem));
    if (FAILED(hr)) {
        std::cerr << "Error: Cannot resolve folder path\n";
        pWall->Release(); CoUninitialize(); return 1;
    }

    IShellItemArray* pArray = nullptr;
    hr = SHCreateShellItemArrayFromShellItem(pItem, IID_PPV_ARGS(&pArray));
    pItem->Release();
    if (FAILED(hr)) {
        std::cerr << "Error: Failed to create item array\n";
        pWall->Release(); CoUninitialize(); return 1;
    }

    // Apply slideshow settings
    hr = pWall->SetSlideshow(pArray);
    pArray->Release();
    if (FAILED(hr)) {
        std::cerr << "Error: Failed to set slideshow (0x" << std::hex << hr << ")\n";
        pWall->Release(); CoUninitialize(); return 1;
    }

    pWall->SetPosition(pos);

    DESKTOP_SLIDESHOW_OPTIONS opts = shuffle
        ? DSO_SHUFFLEIMAGES
        : static_cast<DESKTOP_SLIDESHOW_OPTIONS>(0);
    pWall->SetSlideshowOptions(opts, intervalSec * 1000);

    pWall->Release();
    CoUninitialize();

    std::cout << "||| SUCCESS |||" << std::endl;
    return 0;
}
