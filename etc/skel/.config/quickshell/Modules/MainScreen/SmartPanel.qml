import QtQuick
import Quickshell
import qs.Commons
import qs.Services.UI

/**
* SmartPanel - Wrapper that creates placeholder + content window
*
* This component is a thin wrapper that maintains backward compatibility
* while splitting panel rendering into:
* 1. PanelPlaceholder (in MainScreen, for background rendering)
* 2. SmartPanelWindow (separate window, for content)
*/
Item {
  id: root

  // Screen property provided by MainScreen
  property ShellScreen screen: null

  // Panel content: Text, icons, etc...
  property Component panelContent: null

  // Panel size properties
  property real preferredWidth: 700
  property real preferredHeight: 900
  property real preferredWidthRatio
  property real preferredHeightRatio
  property var buttonItem: null
  property bool forceAttachToBar: false

  // Anchoring properties
  property bool panelAnchorHorizontalCenter: false
  property bool panelAnchorVerticalCenter: false
  property bool panelAnchorTop: false
  property bool panelAnchorBottom: false
  property bool panelAnchorLeft: false
  property bool panelAnchorRight: false

  // Keyboard focus
  property bool exclusiveKeyboard: true

  // Support close with escape
  property bool closeWithEscape: true

  // Track if window should be active (for lazy loading and cleanup)
  property bool windowActive: false

  // Expose panel state (from content window)
  readonly property bool isPanelOpen: windowLoader.item ? windowLoader.item.isPanelOpen : false
  readonly property bool isPanelVisible: windowLoader.item ? windowLoader.item.isPanelVisible : false

  // Expose panelRegion for backward compatibility (MainScreen mask)
  readonly property var panelRegion: panelPlaceholder ? panelPlaceholder.panelItem : null

  // Signals
  signal opened
  signal closed

  // Keyboard event handlers - these can be overridden by panel implementations
  // Note: SmartPanelWindow directly calls these functions via panelWrapper reference
  function onEscapePressed() {
  }
  function onTabPressed() {
  }
  function onBackTabPressed() {
  }
  function onUpPressed() {
  }
  function onDownPressed() {
  }
  function onLeftPressed() {
  }
  function onRightPressed() {
  }
  function onReturnPressed() {
  }
  function onHomePressed() {
  }
  function onEndPressed() {
  }
  function onPageUpPressed() {
  }
  function onPageDownPressed() {
  }
  function onCtrlJPressed() {
  }
  function onCtrlKPressed() {
  }

  // Public control functions
  function toggle(buttonItem, buttonName) {
    // Ensure window is created before toggling
    if (!root.windowActive) {
      root.windowActive = true;
      Qt.callLater(function () {
        if (windowLoader.item) {
          windowLoader.item.toggle(buttonItem, buttonName);
        }
      });
    } else if (windowLoader.item) {
      windowLoader.item.toggle(buttonItem, buttonName);
    }
  }

  function open(buttonItem, buttonName) {
    // Ensure window is created before opening
    if (!root.windowActive) {
      root.windowActive = true;
      Qt.callLater(function () {
        if (windowLoader.item) {
          windowLoader.item.open(buttonItem, buttonName);
        }
      });
    } else if (windowLoader.item) {
      windowLoader.item.open(buttonItem, buttonName);
    }
  }

  function close() {
    if (windowLoader.item) {
      windowLoader.item.close();
    }
  }

  // Expose setPosition for panels that need to recalculate on settings changes
  function setPosition() {
    if (panelPlaceholder) {
      panelPlaceholder.setPosition();
    }
  }

  // INTERNAL IMPLEMENTATION

  // Create the panel placeholder (stays in MainScreen for background rendering)
  readonly property var panelPlaceholder: PanelPlaceholder {
    id: placeholder
    screen: root.screen
    panelName: root.objectName || "unnamed-panel"

    // Forward configuration properties
    preferredWidth: root.preferredWidth
    preferredHeight: root.preferredHeight
    preferredWidthRatio: root.preferredWidthRatio
    preferredHeightRatio: root.preferredHeightRatio
    forceAttachToBar: root.forceAttachToBar

    // Forward anchoring properties
    panelAnchorHorizontalCenter: root.panelAnchorHorizontalCenter
    panelAnchorVerticalCenter: root.panelAnchorVerticalCenter
    panelAnchorTop: root.panelAnchorTop
    panelAnchorBottom: root.panelAnchorBottom
    panelAnchorLeft: root.panelAnchorLeft
    panelAnchorRight: root.panelAnchorRight

    // Parent to MainScreen root
    parent: root.parent
  }

  // Lazy-load the content window (only created when open, destroyed when closed)
  Loader {
    id: windowLoader
    active: root.windowActive
    sourceComponent: SmartPanelWindow {
      placeholder: panelPlaceholder
      panelContent: root.panelContent
      panelWrapper: root // Pass reference to SmartPanel for keyboard handlers
      exclusiveKeyboard: root.exclusiveKeyboard
      closeWithEscape: root.closeWithEscape

      // Forward signals
      onPanelOpened: root.opened()
      onPanelClosed: {
        root.closed();
        // Destroy the window after close animation completes
        Qt.callLater(function () {
          root.windowActive = false;
        });
      }
    }
  }

  // Register with PanelService
  Component.onCompleted: {
    PanelService.registerPanel(root);
  }
}
