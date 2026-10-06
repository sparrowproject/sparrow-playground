#include <cstdio>
#include <memory>
#include <windows.h>
#include <appmodel.h>

#ifndef PACKAGE_PROPERTY_STATIC
#define PACKAGE_PROPERTY_STATIC 0x00080000
#endif

#ifndef PACKAGE_FILTER_STATIC
#define PACKAGE_FILTER_STATIC PACKAGE_PROPERTY_STATIC
#endif

#ifndef PACKAGE_PROPERTY_DYNAMIC
#define PACKAGE_PROPERTY_DYNAMIC 0x00100000
#endif

#ifndef PACKAGE_FILTER_DYNAMIC
#define PACKAGE_FILTER_DYNAMIC PACKAGE_PROPERTY_DYNAMIC
#endif

extern "C" void PrintCurrentPackageGraph()
{
    wchar_t packageFullName[PACKAGE_FULL_NAME_MAX_LENGTH + 1]{};
    UINT32 packageFullNameLength = ARRAYSIZE(packageFullName);
    const LONG packageFullNameResult = GetCurrentPackageFullName(&packageFullNameLength, packageFullName);
    std::printf("GetCurrentPackageFullName: 0x%08lx", static_cast<unsigned long>(packageFullNameResult));
    if (packageFullNameResult == ERROR_SUCCESS)
    {
        std::printf(" %ls", packageFullName);
    }
    std::printf("\n");

    UINT32 packageCount = 0;
    UINT32 bufferLength = 0;
    constexpr UINT32 flags = PACKAGE_FILTER_HEAD | PACKAGE_FILTER_DIRECT | PACKAGE_FILTER_STATIC | PACKAGE_FILTER_DYNAMIC | PACKAGE_INFORMATION_BASIC;

    LONG result = GetCurrentPackageInfo(flags, &bufferLength, nullptr, &packageCount);
    if (result == APPMODEL_ERROR_NO_PACKAGE || result == ERROR_SUCCESS)
    {
        std::printf("GetCurrentPackageInfo: 0x%08lx packageCount=%u\n", static_cast<unsigned long>(result), packageCount);
        return;
    }

    if (result != ERROR_INSUFFICIENT_BUFFER)
    {
        std::printf("GetCurrentPackageInfo(size): 0x%08lx\n", static_cast<unsigned long>(result));
        return;
    }

    auto buffer = std::make_unique<BYTE[]>(bufferLength);
    result = GetCurrentPackageInfo(flags, &bufferLength, buffer.get(), &packageCount);
    std::printf("GetCurrentPackageInfo: 0x%08lx packageCount=%u\n", static_cast<unsigned long>(result), packageCount);
    if (result != ERROR_SUCCESS)
    {
        return;
    }

    const auto packageInfo = reinterpret_cast<const PACKAGE_INFO*>(buffer.get());
    for (UINT32 index = 0; index < packageCount; ++index)
    {
        std::printf("  [%u] %ls\n", index, packageInfo[index].packageFullName);
        std::printf("      path=%ls\n", packageInfo[index].path);
    }
}

static void PrintModulePath(const wchar_t* moduleName)
{
    HMODULE module = GetModuleHandleW(moduleName);
    if (!module)
    {
        std::printf("Module %ls: not loaded\n", moduleName);
        return;
    }

    wchar_t path[MAX_PATH]{};
    const DWORD length = GetModuleFileNameW(module, path, ARRAYSIZE(path));
    if (length == 0)
    {
        std::printf("Module %ls: loaded, path unavailable 0x%08lx\n", moduleName, static_cast<unsigned long>(GetLastError()));
        return;
    }

    std::printf("Module %ls: %ls\n", moduleName, path);
}

static void LoadAndPrintModulePath(const wchar_t* moduleName)
{
    HMODULE module = LoadLibraryW(moduleName);
    if (!module)
    {
        std::printf("LoadLibrary %ls: failed 0x%08lx\n", moduleName, static_cast<unsigned long>(GetLastError()));
        return;
    }

    PrintModulePath(moduleName);
}

extern "C" void PrintWinAppRuntimeModulePaths()
{
    LoadAndPrintModulePath(L"Microsoft.WindowsAppRuntime.dll");
    LoadAndPrintModulePath(L"Microsoft.Windows.ApplicationModel.Resources.dll");
    LoadAndPrintModulePath(L"MRM.dll");
    LoadAndPrintModulePath(L"Microsoft.UI.Xaml.dll");
    LoadAndPrintModulePath(L"Microsoft.UI.Xaml.Controls.dll");
}
