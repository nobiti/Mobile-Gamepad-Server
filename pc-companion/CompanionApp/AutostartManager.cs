using System.Runtime.InteropServices;

namespace CompanionApp;

public static class AutostartManager
{
    public static void Install(string appPath)
    {
        if (!RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
        {
            return;
        }

        var startupFolder = Environment.GetFolderPath(Environment.SpecialFolder.Startup);
        var targetPath = Path.Combine(startupFolder, "MobileGamepadCompanion.cmd");
        var content = $"\"{appPath}\"";
        File.WriteAllText(targetPath, content);
    }

    public static void Remove()
    {
        if (!RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
        {
            return;
        }

        var startupFolder = Environment.GetFolderPath(Environment.SpecialFolder.Startup);
        var targetPath = Path.Combine(startupFolder, "MobileGamepadCompanion.cmd");
        if (File.Exists(targetPath))
        {
            File.Delete(targetPath);
        }
    }
}
