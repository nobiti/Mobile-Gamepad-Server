using System.Windows.Forms;
using CompanionApp;

const int defaultStreamPort = 9876;
const int defaultDiscoveryPort = 9877;
const string settingsFileName = "companion-settings.json";

int streamPort = defaultStreamPort;
int discoveryPort = defaultDiscoveryPort;

for (var i = 0; i < args.Length; i++)
{
    switch (args[i])
    {
        case "--stream-port" when i + 1 < args.Length && int.TryParse(args[i + 1], out var streamValue):
            streamPort = streamValue;
            i++;
            break;
        case "--discovery-port" when i + 1 < args.Length && int.TryParse(args[i + 1], out var discoveryValue):
            discoveryPort = discoveryValue;
            i++;
            break;
    }
}

Application.SetHighDpiMode(HighDpiMode.SystemAware);
Application.EnableVisualStyles();
Application.SetCompatibleTextRenderingDefault(false);

var settingsPath = Path.Combine(Directory.GetCurrentDirectory(), settingsFileName);
var settings = SettingsLoader.LoadOrCreate(settingsPath);
var form = new MainForm(settingsPath, settings, streamPort, discoveryPort);
Application.Run(form);
