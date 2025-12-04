import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Services.Keyboard
import qs.Services.UI

Item {
  id: root

  // 1. FACADE INTERFACE
  property ListModel workspaces: ListModel {}
  property var windows: []
  property int focusedWindowIndex: -1

  signal workspaceChanged
  signal activeWindowChanged
  signal windowListChanged
  signal displayScalesChanged

  property string selectedMonitor: ""
  property string currentLayoutSymbol: ""
  property bool initialized: false

  // 2. CONFIGURATION
  QtObject {
    id: config
    readonly property int defaultWorkspaceId: 1

    // Pre-compiled Regex for Performance
    readonly property var reTagDetail: /^(\S+)\s+tag\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)$/
                                       readonly property var reTagBinary: /^(\S+)\s+tags\s+([01]+)\s+([01]+)\s+([01]+)$/
                                       readonly property var reLayout: /^(\S+)\s+layout\s+(\S+)$/
                                       readonly property var reMetadata: /^(\S+)\s+(title|appid)\s+(.*)$/
                                       readonly property var reKbLayout: /^(\S+)\s+kb_layout\s+(.*)$/
                                       readonly property var reScale: /^(\S+)\s+scale_factor\s+(\d+(\.\d+)?)$/

                                       readonly property var query: ({
                                                                       eventStream: ["mmsg", "-w"],
                                                                       monitors: ["mmsg", "-g", "-o"],
                                                                       outputs: ["mmsg", "-g", "-A"] // Scales
                                                                       ,
                                                                       workspaces: ["mmsg", "-g", "-t"]
                                                                     })

    readonly property var action: ({
                                     tag: ["mmsg", "-s", "-t"],
                                     view: ["mmsg", "-s", "-d", "view"],
                                     toggleOverview: ["mmsg", "-s", "-d", "toggleoverview"],
                                     setLayout: ["mmsg", "-s", "-d", "setlayout"],
                                     killClient: ["mmsg", "-s", "-d", "killclient"],
                                     quit: ["mmsg", "-s", "-q"]
                                   })
  }

  // 3. LOGIC ENGINE
  QtObject {
    id: internal

    // State
    property var activeTags: ({})
    property var multiTagState: ({})
    property bool hasValidTagData: false

    // Map<ToplevelObject, WorkspaceID>
    property var windowStateMap: new Map()

    property string mmsgFocusedTitle: ""
    property string mmsgFocusedAppId: ""
    property string currentKbLayout: ""

    // Caches
    property var workspaceCache: ({})
    property var monitorScales: ({})
    property string lastWindowSig: ""

    // Buffers
    property string streamBuffer: ""

    // --- STREAM PROCESSOR ---
    function processFrame(output) {
      const lines = output.trim().split('\n');
      const newWsList = [];
      const newWsCache = {};
      const processedTags = {};
      let metadataChanged = false;
      let receivedClientCounts = false; // Track if we got real numbers

      for (let i = 0; i < lines.length; i++) {
        const line = lines[i].trim();
        if (!line)
          continue;

        // 1. Tag Details (High Quality Data: Contains Client Counts)
        const tagMatch = line.match(config.reTagDetail);
        if (tagMatch) {
          const outputName = tagMatch[1];
          const tagId = parseInt(tagMatch[2]);
          const state = parseInt(tagMatch[3]);
          const clients = parseInt(tagMatch[4]);
          const focused = parseInt(tagMatch[5]);
          const isActive = (state & 1) !== 0;

          if (isActive)
            internal.activeTags[outputName] = tagId;
          const wsData = {
            "id": tagId,
            "idx": tagId,
            "name": tagId.toString(),
            "output": outputName,
            "isActive": isActive,
            "isFocused": isActive && (focused === 1 || outputName === root.selectedMonitor),
            "isUrgent": (state & 2) !== 0,
            "isOccupied": clients > 0,
            "clients": clients // We have the real number!
          };
          const key = `${outputName}-${tagId}`;
          newWsCache[key] = wsData;
          newWsList.push(wsData);
          processedTags[key] = true;
          receivedClientCounts = true;
          continue;
        }

        // 2. Binary Tags (Low Quality Data: No Client Counts)
        const tagsMatch = line.match(config.reTagBinary);
        if (tagsMatch) {
          const outputName = tagsMatch[1];
          const occ = tagsMatch[2];
          const seltags = tagsMatch[3];
          const urg = tagsMatch[4];
          const len = occ.length;

          // Overview Detection
          let activeCount = 0;
          for (let c = 0; c < seltags.length; c++)
            if (seltags[c] === '1')
              activeCount++;
          internal.multiTagState[outputName] = (activeCount > 1);

          for (let j = 0; j < len; j++) {
            const tagId = j + 1;
            const charIdx = len - 1 - j;
            const key = `${outputName}-${tagId}`;

            if (processedTags[key])
              continue;
            const isActive = seltags[charIdx] === '1';
            const isOccupied = occ[charIdx] === '1';

            if (isActive)
              internal.activeTags[outputName] = tagId;
            newWsList.push({
                             "id": tagId,
                             "idx": tagId,
                             "name": tagId.toString(),
                             "output": outputName,
                             "isActive": isActive,
                             "isFocused": false,
                             "isUrgent": urg[charIdx] === '1',
                             "isOccupied": isOccupied,
                             "clients": isOccupied ? -1 : 0 // -1 indicates "Unknown, but at least 1"
                           });
          }
          continue;
        }

        // 3. Metadata
        const metaMatch = line.match(config.reMetadata);
        if (metaMatch) {
          const prop = metaMatch[2];
          const val = metaMatch[3];
          if (prop === "title")
            internal.mmsgFocusedTitle = val;
          else if (prop === "appid")
            internal.mmsgFocusedAppId = val;
          metadataChanged = true;
          continue;
        }

        // 4. Layout
        const layoutMatch = line.match(config.reLayout);
        if (layoutMatch) {
          if (layoutMatch[2] !== root.currentLayoutSymbol)
            root.currentLayoutSymbol = layoutMatch[2];
        }

        // 5. Keyboard
        const kbMatch = line.match(config.reKbLayout);
        if (kbMatch) {
          const kbName = kbMatch[2];
          if (kbName !== internal.currentKbLayout) {
            internal.currentKbLayout = kbName;
            if (KeyboardLayoutService)
              KeyboardLayoutService.setCurrentLayout(kbName);
          }
        }
      }

      // Apply
      if (JSON.stringify(newWsCache) !== JSON.stringify(internal.workspaceCache)) {
        internal.workspaceCache = newWsCache;
        newWsList.sort((a, b) => {
                         if (a.id !== b.id)
                         return a.id - b.id;
                         return a.output.localeCompare(b.output);
                       });
        root.workspaces.clear();
        for (let k = 0; k < newWsList.length; k++)
          root.workspaces.append(newWsList[k]);
        root.workspaceChanged();

        if (receivedClientCounts)
          internal.hasValidTagData = true;
      }

      if (metadataChanged || newWsList.length > 0) {
        internal.updateWindowList();
      }
    }

    // --- WINDOW LIST MERGE ---
    function updateWindowList() {
      if (!ToplevelManager.toplevels)
        return;

      // FIX: SAFETY CHECK
      // If we haven't received "Detailed" data yet (only binary),
      // we don't know where the windows are. Abort to prevent map poisoning.
      if (!internal.hasValidTagData)
        return;

      const rawList = ToplevelManager.toplevels.values;
      const finalList = [];
      let newFocusedIdx = -1;

      const currentObjects = new Set();
      const tagCapacities = new Map();

      // Build Capacities
      let totalCapacity = 0;
      for (let key in internal.workspaceCache) {
        const ws = internal.workspaceCache[key];
        const cap = ws.clients > 0 ? ws.clients : 0;
        tagCapacities.set(key, cap);
        totalCapacity += cap;
      }

      if (totalCapacity === 0 && rawList.length > 0 && !internal.hasValidTagData)
        return;

      const unassignedWindows = [];

      // Pass 1: Known & Focused
      for (let i = 0; i < rawList.length; i++) {
        const toplevel = rawList[i];
        if (!toplevel || toplevel.outliers)
          continue;

        currentObjects.add(toplevel);

        const appId = toplevel.appId || toplevel.wayland.appId || "";
        const title = toplevel.title || toplevel.wayland.title || "";

        let outputName = root.selectedMonitor;
        if (toplevel.outputs && toplevel.outputs.length > 0) {
          outputName = toplevel.outputs[0].name;
        }

        const currentActiveTag = internal.activeTags[outputName] || config.defaultWorkspaceId;
        const isMultiTag = internal.multiTagState[outputName] === true;
        let wsId = -1;

        const isFocused = toplevel.activated;
        const isMmsgFocus = (title === internal.mmsgFocusedTitle) && (appId === internal.mmsgFocusedAppId);

        if (isFocused && isMmsgFocus && !isMultiTag) {
          wsId = currentActiveTag;
          internal.windowStateMap.set(toplevel, wsId);
        } else if (internal.windowStateMap.has(toplevel)) {
          wsId = internal.windowStateMap.get(toplevel);
        }

        if (wsId !== -1) {
          const key = `${outputName}-${wsId}`;
          const cap = tagCapacities.get(key) || 0;
          if (cap > 0)
            tagCapacities.set(key, cap - 1);

          finalList.push(createWindowObject(toplevel, outputName, appId, title, wsId, isFocused, i));
        } else {
          unassignedWindows.push({
                                   toplevel,
                                   outputName,
                                   appId,
                                   title,
                                   isFocused,
                                   index: i
                                 });
        }
      }

      // Pass 2: Distribute Unknowns
      for (const win of unassignedWindows) {
        let assignedId = -1;

        for (let key in internal.workspaceCache) {
          const ws = internal.workspaceCache[key];
          // Robust output check: match name OR if both are undefined/generic
          if (ws.output !== win.outputName && win.outputName !== "")
            continue;

          const cap = tagCapacities.get(key) || 0;
          if (cap > 0) {
            assignedId = ws.id;
            tagCapacities.set(key, cap - 1);
            break;
          }
        }

        if (assignedId === -1) {
          assignedId = internal.activeTags[win.outputName] || config.defaultWorkspaceId;
        }

        internal.windowStateMap.set(win.toplevel, assignedId);
        finalList.push(createWindowObject(win.toplevel, win.outputName, win.appId, win.title, assignedId, win.isFocused, win.index));
      }

      finalList.sort((a, b) => {
                       const idxA = parseInt(a.id.split('-').pop());
                       const idxB = parseInt(b.id.split('-').pop());
                       return idxA - idxB;
                     });

      for (let i = 0; i < finalList.length; i++) {
        if (finalList[i].isFocused)
          newFocusedIdx = i;
      }

      if (internal.windowStateMap.size > rawList.length + 10) {
        for (const key of internal.windowStateMap.keys()) {
          if (!currentObjects.has(key))
            internal.windowStateMap.delete(key);
        }
      }

      const sig = JSON.stringify(finalList.map(w => w.id + w.workspaceId + w.isFocused));
      if (sig !== internal.lastWindowSig) {
        internal.lastWindowSig = sig;
        root.windows = finalList;
        root.windowListChanged();
      }

      if (newFocusedIdx !== root.focusedWindowIndex) {
        root.focusedWindowIndex = newFocusedIdx;
        root.activeWindowChanged();
      }
    }

    function createWindowObject(toplevel, outputName, appId, title, wsId, isFocused, index) {
      return {
        "id": `${outputName}-${appId}-${index}`,
        "title": title,
        "appId": appId,
        "class": appId,
        "workspaceId": wsId,
        "isFocused": isFocused,
        "output": outputName,
        "handle": toplevel,
        "fullscreen": toplevel.fullscreen,
        "floating": toplevel.maximized === false && toplevel.fullscreen === false
      };
    }

    // --- SCALES ---
    function updateScales() {
      const scalesMap = {};
      for (const [name, data] of Object.entries(internal.monitorScales)) {
        scalesMap[name] = {
          "name": name,
          "scale": data.scale || 1.0,
          "width": 0,
          "height": 0,
          "x": 0,
          "y": 0
        };
      }
      if (CompositorService && CompositorService.onDisplayScalesUpdated) {
        CompositorService.onDisplayScalesUpdated(scalesMap);
      }
      root.displayScalesChanged();
    }
  }

  // 4. PROCESSES

  Process {
    id: eventStream
    running: false
    command: config.query.eventStream
    stdout: SplitParser {
      onRead: line => {
                if (line.includes("selmon") && line.includes(" 1")) {
                  const parts = line.split(' ');
                  if (parts.length >= 3)
                  root.selectedMonitor = parts[0];
                  return;
                }
                internal.streamBuffer += line + "\n";
                if (line.match(config.reTagBinary)) {
                  internal.processFrame(internal.streamBuffer);
                  internal.streamBuffer = "";
                }
              }
    }
    onExited: code => {
                if (code !== 0)
                restartTimer.start();
              }
  }
  Timer {
    id: restartTimer
    interval: 1000
    onTriggered: if (initialized)
                   eventStream.running = true
  }

  Process {
    id: procInitial
    command: config.query.workspaces
    stdout: SplitParser {
      onRead: line => internal.streamBuffer += line + "\n"
    }
    onExited: code => {
                if (code === 0) {
                  internal.processFrame(internal.streamBuffer);
                  internal.streamBuffer = "";
                }
              }
  }

  Process {
    id: procOutputs
    command: config.query.outputs
    stdout: SplitParser {
      onRead: line => {
                const match = line.match(config.reScale);
                if (match) {
                  const out = match[1];
                  const scale = parseFloat(match[2]);
                  if (!internal.monitorScales[out])
                  internal.monitorScales[out] = {};
                  internal.monitorScales[out].scale = scale;
                }
              }
    }
    onExited: code => {
                if (code === 0)
                internal.updateScales();
              }
  }

  // 5. WAYLAND & INIT

  Connections {
    target: ToplevelManager.toplevels
    function onValuesChanged() {
      internal.updateWindowList();
    }
  }
  Timer {
    interval: 200
    running: true
    repeat: true
    onTriggered: internal.updateWindowList()
  }

  function initialize() {
    if (initialized)
      return;
    Logger.i("MangoService", "Service Started");

    procOutputs.running = true;
    procInitial.running = true;
    eventStream.running = true;
    Quickshell.execDetached(["mmsg", "-g", "-o"]);

    initialized = true;
  }

  function queryDisplayScales() {
    procOutputs.running = true;
  }

  function switchToWorkspace(workspace) {
    const tagId = workspace.idx || workspace.id || config.defaultWorkspaceId;
    const output = workspace.output || root.selectedMonitor || "";
    const cmd = config.action.tag.slice();
    if (output && Object.keys(internal.monitorScales).length > 1)
      cmd.push("-o", output);
    cmd.push(tagId.toString());
    Quickshell.execDetached(cmd);
  }

  function focusWindow(window) {
    if (window && window.handle)
      window.handle.activate();
    else if (window.workspaceId)
      switchToWorkspace({
                          id: window.workspaceId,
                          output: window.output
                        });
  }

  function closeWindow(window) {
    if (window && window.handle)
      window.handle.close();
    else
      Quickshell.execDetached(config.action.killClient);
  }

  function logout() {
    Quickshell.execDetached(config.action.quit);
  }
}
