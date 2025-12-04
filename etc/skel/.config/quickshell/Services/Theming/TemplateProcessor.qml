pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.System
import qs.Services.Theming
import qs.Services.UI

Singleton {
  id: root

  readonly property string dynamicConfigPath: Settings.cacheDir + "matugen.dynamic.toml"

  readonly property var schemeNameMap: ({
                                          "Noctalia (default)": "Noctalia-default",
                                          "Noctalia (legacy)": "Noctalia-legacy",
                                          "Tokyo Night": "Tokyo-Night"
                                        })

  readonly property var terminalPaths: ({
                                          "foot": "~/.config/foot/themes/noctalia",
                                          "ghostty": "~/.config/ghostty/themes/noctalia",
                                          "kitty": "~/.config/kitty/themes/noctalia.conf",
                                          "alacritty": "~/.config/alacritty/themes/noctalia.toml",
                                          "wezterm": "~/.config/wezterm/colors/Noctalia.toml"
                                        })

  /**
  * Process wallpaper colors using matugen CLI
  * Dual-path architecture (wallpaper uses matugen CLI)
  */
  function processWallpaperColors(wallpaperPath, mode) {
    const content = buildMatugenConfig();
    if (!content)
      return;
    const wp = wallpaperPath.replace(/'/g, "'\\''");
    const script = buildMatugenScript(content, wp, mode);

    generateProcess.generator = "matugen";
    generateProcess.command = ["bash", "-lc", script];
    generateProcess.running = true;
  }

  /**
  * Process predefined color scheme using sed scripts
  * Dual-path architecture (predefined uses sed scripts)
  */
  function processPredefinedScheme(schemeData, mode) {
    handleTerminalThemes(mode);

    const colors = schemeData[mode];
    let script = processAllTemplates(colors, mode);

    // Add user templates if enabled (requirement #1)
    script += buildUserTemplateCommandForPredefined(schemeData, mode);

    generateProcess.generator = "predefined";
    generateProcess.command = ["bash", "-lc", script];
    generateProcess.running = true;
  }

  // ================================================================================
  // WALLPAPER-BASED GENERATION (matugen CLI)
  // ================================================================================
  function buildMatugenConfig() {
    var lines = [];
    var mode = Settings.data.colorSchemes.darkMode ? "dark" : "light";

    if (Settings.data.colorSchemes.useWallpaperColors) {
      addWallpaperTemplates(lines, mode);
    }

    addApplicationTemplates(lines, mode);

    if (lines.length > 0) {
      return ["[config]"].concat(lines).join("\n") + "\n";
    }
    return "";
  }

  function addWallpaperTemplates(lines, mode) {
    // Noctalia colors JSON
    lines.push("[templates.noctalia]");
    lines.push('input_path = "' + Quickshell.shellDir + '/Assets/MatugenTemplates/noctalia.json"');
    lines.push('output_path = "' + Settings.configDir + 'colors.json"');

    // Terminal templates
    TemplateRegistry.terminals.forEach(terminal => {
                                         if (Settings.data.templates[terminal.id]) {
                                           lines.push(`\n[templates.${terminal.id}]`);
                                           lines.push(`input_path = "${Quickshell.shellDir}/Assets/MatugenTemplates/${terminal.matugenPath}"`);
                                           lines.push(`output_path = "${terminal.outputPath}"`);
                                           const postHook = terminal.postHook || `${TemplateRegistry.colorsApplyScript} ${terminal.id}`;
                                           lines.push(`post_hook = "${postHook}"`);
                                         }
                                       });
  }

  function addApplicationTemplates(lines, mode) {
    TemplateRegistry.applications.forEach(app => {
                                            if (app.id === "discord") {
                                              // Handle Discord clients specially
                                              if (Settings.data.templates.discord) {
                                                app.clients.forEach(client => {
                                                                      // Check if this specific client is detected
                                                                      if (isDiscordClientEnabled(client.name)) {
                                                                        lines.push(`\n[templates.discord_${client.name}]`);
                                                                        lines.push(`input_path = "${Quickshell.shellDir}/Assets/MatugenTemplates/${app.input}"`);
                                                                        lines.push(`output_path = "${client.path}/themes/noctalia.theme.css"`);
                                                                      }
                                                                    });
                                              }
                                            } else if (app.id === "code") {
                                              // Handle Code clients specially
                                              if (Settings.data.templates.code) {
                                                app.clients.forEach(client => {
                                                                      // Check if this specific client is detected
                                                                      if (isCodeClientEnabled(client.name)) {
                                                                        lines.push(`\n[templates.code_${client.name}]`);
                                                                        lines.push(`input_path = "${Quickshell.shellDir}/Assets/MatugenTemplates/${app.input}"`);
                                                                        lines.push(`output_path = "${client.path}"`);
                                                                      }
                                                                    });
                                              }
                                            } else {
                                              // Handle regular apps
                                              if (Settings.data.templates[app.id]) {
                                                app.outputs.forEach((output, idx) => {
                                                                      lines.push(`\n[templates.${app.id}_${idx}]`);
                                                                      lines.push(`input_path = "${Quickshell.shellDir}/Assets/MatugenTemplates/${app.input}"`);
                                                                      lines.push(`output_path = "${output.path}"`);
                                                                      if (app.postProcess) {
                                                                        lines.push(`post_hook = "${app.postProcess(mode)}"`);
                                                                      }
                                                                    });
                                              }
                                            }
                                          });
  }

  function isDiscordClientEnabled(clientName) {
    // Check ProgramCheckerService to see if client is detected
    for (var i = 0; i < ProgramCheckerService.availableDiscordClients.length; i++) {
      if (ProgramCheckerService.availableDiscordClients[i].name === clientName) {
        return true;
      }
    }
    return false;
  }

  function isCodeClientEnabled(clientName) {
    // Check ProgramCheckerService to see if client is detected
    for (var i = 0; i < ProgramCheckerService.availableCodeClients.length; i++) {
      if (ProgramCheckerService.availableCodeClients[i].name === clientName) {
        return true;
      }
    }
    return false;
  }

  function buildMatugenScript(content, wallpaper, mode) {
    const delimiter = "MATUGEN_CONFIG_EOF_" + Math.random().toString(36).substr(2, 9);
    const pathEsc = dynamicConfigPath.replace(/'/g, "'\\''");

    let script = `cat > '${pathEsc}' << '${delimiter}'\n${content}\n${delimiter}\n`;
    script += `matugen image '${wallpaper}' --config '${pathEsc}' --mode ${mode} --type ${Settings.data.colorSchemes.matugenSchemeType}`;
    script += buildUserTemplateCommand(wallpaper, mode);

    return script + "\n";
  }

  // ================================================================================
  // PREDEFINED SCHEME GENERATION (sed scripts)
  // ================================================================================
  function processAllTemplates(colors, mode) {
    let script = "";
    const homeDir = Quickshell.env("HOME");

    TemplateRegistry.applications.forEach(app => {
                                            if (app.id === "discord") {
                                              if (Settings.data.templates.discord) {
                                                script += processDiscordClients(app, colors, mode, homeDir);
                                              }
                                            } else if (app.id === "code") {
                                              if (Settings.data.templates.code) {
                                                script += processCodeClients(app, colors, mode, homeDir);
                                              }
                                            } else {
                                              if (Settings.data.templates[app.id]) {
                                                script += processTemplate(app, colors, mode, homeDir);
                                              }
                                            }
                                          });
    return script;
  }

  function processDiscordClients(discordApp, colors, mode, homeDir) {
    let script = "";
    const palette = ColorPaletteGenerator.generatePalette(colors, Settings.data.colorSchemes.darkMode, false);

    discordApp.clients.forEach(client => {
                                 if (!isDiscordClientEnabled(client.name))
                                 return;
                                 const templatePath = `${Quickshell.shellDir}/Assets/MatugenTemplates/${discordApp.input}`;
                                 const outputPath = `${client.path}/themes/noctalia.theme.css`.replace("~", homeDir);
                                 const outputDir = outputPath.substring(0, outputPath.lastIndexOf('/'));
                                 const baseConfigDir = outputDir.replace("/themes", "");

                                 script += `\n`;
                                 script += `if [ -d "${baseConfigDir}" ]; then\n`;
                                 script += `  mkdir -p ${outputDir}\n`;
                                 script += `  cp '${templatePath}' '${outputPath}'\n`;
                                 script += `  ${replaceColorsInFile(outputPath, palette)}`;
                                 script += `else\n`;
                                 script += `  echo "Discord client ${client.name} not found at ${baseConfigDir}, skipping"\n`;
                                 script += `fi\n`;
                               });

    return script;
  }

  function processCodeClients(codeApp, colors, mode, homeDir) {
    let script = "";
    const palette = ColorPaletteGenerator.generatePalette(colors, Settings.data.colorSchemes.darkMode, false);

    codeApp.clients.forEach(client => {
                              if (!isCodeClientEnabled(client.name))
                              return;
                              const templatePath = `${Quickshell.shellDir}/Assets/MatugenTemplates/${codeApp.input}`;
                              const outputPath = client.path.replace("~", homeDir);
                              const outputDir = outputPath.substring(0, outputPath.lastIndexOf('/'));

                              // Extract base config directory for checking
                              var baseConfigDir = "";
                              if (client.name === "code") {
                                baseConfigDir = "~/.vscode".replace("~", homeDir);
                              } else if (client.name === "codium") {
                                baseConfigDir = "~/.vscode-oss".replace("~", homeDir);
                              }

                              script += `\n`;
                              script += `if [ -d "${baseConfigDir}" ]; then\n`;
                              script += `  mkdir -p ${outputDir}\n`;
                              script += `  cp '${templatePath}' '${outputPath}'\n`;
                              script += `  ${replaceColorsInFile(outputPath, palette)}`;
                              script += `else\n`;
                              script += `  echo "Code client ${client.name} not found at ${baseConfigDir}, skipping"\n`;
                              script += `fi\n`;
                            });

    return script;
  }

  function processTemplate(app, colors, mode, homeDir) {
    const palette = ColorPaletteGenerator.generatePalette(colors, Settings.data.colorSchemes.darkMode, app.strict || false);
    let script = "";

    app.outputs.forEach(output => {
                          const templatePath = `${Quickshell.shellDir}/Assets/MatugenTemplates/${app.input}`;
                          const outputPath = output.path.replace("~", homeDir);
                          const outputDir = outputPath.substring(0, outputPath.lastIndexOf('/'));

                          script += `\n`;
                          script += `mkdir -p ${outputDir}\n`;
                          script += `cp '${templatePath}' '${outputPath}'\n`;
                          script += replaceColorsInFile(outputPath, palette);
                          script += `\n`;
                        });

    if (app.postProcess) {
      script += app.postProcess(mode);
    }

    return script;
  }

  function replaceColorsInFile(filePath, colors) {
    let script = "";
    Object.keys(colors).forEach(colorKey => {
                                  const hexValue = colors[colorKey].default.hex;
                                  const hexStrippedValue = colors[colorKey].default.hex_stripped;

                                  const escapedHex = hexValue.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
                                  const escapedHexStripped = hexStrippedValue.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

                                  // replace hex_stripped
                                  script += `sed -i 's/{{colors\\.${colorKey}\\.default\\.hex_stripped}}/${escapedHexStripped}/g' '${filePath}'\n`;

                                  // replace hex
                                  script += `sed -i 's/{{colors\\.${colorKey}\\.default\\.hex}}/${escapedHex}/g' '${filePath}'\n`;
                                });
    return script;
  }

  // ================================================================================
  // TERMINAL THEMES (predefined schemes use pre-rendered files)
  // ================================================================================
  function handleTerminalThemes(mode) {
    const commands = [];
    const homeDir = Quickshell.env("HOME");

    Object.keys(terminalPaths).forEach(terminal => {
                                         if (Settings.data.templates[terminal]) {
                                           const outputPath = terminalPaths[terminal].replace("~", homeDir);
                                           const outputDir = outputPath.substring(0, outputPath.lastIndexOf('/'));
                                           const templatePath = getTerminalColorsTemplate(terminal, mode);

                                           commands.push(`mkdir -p ${outputDir}`);
                                           commands.push(`cp -f ${templatePath} ${outputPath}`);
                                           commands.push(`${TemplateRegistry.colorsApplyScript} ${terminal}`);
                                         }
                                       });

    if (commands.length > 0) {
      copyProcess.command = ["bash", "-lc", commands.join('; ')];
      copyProcess.running = true;
    }
  }

  function getTerminalColorsTemplate(terminal, mode) {
    let colorScheme = Settings.data.colorSchemes.predefinedScheme;
    colorScheme = schemeNameMap[colorScheme] || colorScheme;

    let extension = "";
    if (terminal === 'kitty') {
      extension = ".conf";
    } else if (terminal === 'wezterm') {
      extension = ".toml";
    }

    const fileName = `${colorScheme}-${mode}${extension}`;
    const relativePath = `terminal/${terminal}/${fileName}`;

    // Try to find the scheme in the loaded schemes list to determine which directory it's in
    for (let i = 0; i < ColorSchemeService.schemes.length; i++) {
      const schemeJsonPath = ColorSchemeService.schemes[i];
      // Check if this is the scheme we're looking for
      if (schemeJsonPath.indexOf(`/${colorScheme}/`) !== -1 || schemeJsonPath.indexOf(`/${colorScheme}.json`) !== -1) {
        // Extract the scheme directory from the JSON path
        // JSON path is like: /path/to/scheme/SchemeName/SchemeName.json
        // We need: /path/to/scheme/SchemeName/terminal/...
        const schemeDir = schemeJsonPath.substring(0, schemeJsonPath.lastIndexOf('/'));
        return `${schemeDir}/${relativePath}`;
      }
    }

    // Fallback: try downloaded first, then preinstalled
    const downloadedPath = `${ColorSchemeService.downloadedSchemesDirectory}/${colorScheme}/${relativePath}`;
    const preinstalledPath = `${ColorSchemeService.schemesDirectory}/${colorScheme}/${relativePath}`;
    return preinstalledPath;
  }

  // ================================================================================
  // USER TEMPLATES, advanced usage
  // ================================================================================
  function buildUserTemplateCommand(input, mode) {
    if (!Settings.data.templates.enableUserTemplates)
      return "";

    const userConfigPath = getUserConfigPath();
    let script = "\n# Execute user config if it exists\n";
    script += `if [ -f '${userConfigPath}' ]; then\n`;
    script += `  matugen image '${input}' --config '${userConfigPath}' --mode ${mode} --type ${Settings.data.colorSchemes.matugenSchemeType}\n`;
    script += "fi";

    return script;
  }

  function buildUserTemplateCommandForPredefined(schemeData, mode) {
    if (!Settings.data.templates.enableUserTemplates)
      return "";

    const userConfigPath = getUserConfigPath();
    const colors = schemeData[mode];
    const palette = ColorPaletteGenerator.generatePalette(colors, Settings.data.colorSchemes.darkMode, false);

    const tempJsonPath = Settings.cacheDir + "predefined-colors.json";
    const tempJsonPathEsc = tempJsonPath.replace(/'/g, "'\\''");

    let script = "\n# Execute user templates with predefined scheme colors\n";
    script += `if [ -f '${userConfigPath}' ]; then\n`;
    script += `  cat > '${tempJsonPathEsc}' << 'EOF'\n`;
    script += JSON.stringify({
                               "colors": palette
                             }, null, 2) + "\n";
    script += "EOF\n";
    script += `  matugen json '${tempJsonPathEsc}' --config '${userConfigPath}' --mode ${mode}\n`;
    script += "fi";

    return script;
  }

  function getUserConfigPath() {
    return (Settings.configDir + "user-templates.toml").replace(/'/g, "'\\''");
  }

  // ================================================================================
  // PROCESSES
  // ================================================================================
  Process {
    id: generateProcess
    workingDirectory: Quickshell.shellDir
    running: false

    // Error reporting helpers
    property string generator: ""

    function buildErrorMessage() {
      const description = (stderr.text && stderr.text.trim() !== "") ? stderr.text.trim() : ((stdout.text && stdout.text.trim() !== "") ? stdout.text.trim() : I18n.tr("toast.theming-processor-failed.desc-generic"));
      const title = I18n.tr(`toast.theming-processor-failed.title-${generator}`);
      return description;
    }

    onExited: function (exitCode) {
      if (exitCode !== 0) {
        const description = generateProcess.buildErrorMessage();
        Logger.e("TemplateProcessor", "Process failed with exit code", exitCode, description);
      }
    }

    stdout: StdioCollector {
      onStreamFinished: {
        if (this.text)
        Logger.d("TemplateProcessor", "stdout:", this.text);
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        if (this.text) {
          const description = generateProcess.buildErrorMessage();
          Logger.e("TemplateProcessor", "Process failed", description);
        }
      }
    }
  }

  // ------------
  Process {
    id: copyProcess
    workingDirectory: Quickshell.shellDir
    running: false
    stderr: StdioCollector {
      onStreamFinished: {
        if (this.text) {
          Logger.e("TemplateProcessor", "copyProcess stderr:", this.text);
        }
      }
    }
  }
}
