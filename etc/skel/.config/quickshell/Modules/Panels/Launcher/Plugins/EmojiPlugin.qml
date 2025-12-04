import QtQuick
import Quickshell
import qs.Commons
import qs.Services.Keyboard

Item {
  id: root

  // Plugin metadata
  property string name: I18n.tr("plugins.emoji")
  property var launcher: null
  property bool handleSearch: false

  // Force update results when emoji service loads
  Connections {
    target: EmojiService
    function onLoadedChanged() {
      if (EmojiService.loaded && root.launcher) {
        // Update launcher results to refresh the UI
        root.launcher?.updateResults();
      }
    }
  }

  // Initialize plugin
  function init() {
    Logger.i("EmojiPlugin", "Initialized");
  }

  // Check if this plugin handles the command
  function handleCommand(searchText) {
    return searchText.startsWith(">emoji");
  }

  // Return available commands when user types ">"
  function commands() {
    return [
          {
            "name": ">emoji",
            "description": I18n.tr("plugins.emoji-search-description"),
            "icon": "face-smile",
            "isImage": false,
            "onActivate": function () {
              launcher.setSearchText(">emoji ");
            }
          }
        ];
  }

  // Get search results
  function getResults(searchText) {
    if (!searchText.startsWith(">emoji")) {
      return [];
    }

    if (!EmojiService.loaded) {
      return [
            {
              "name": I18n.tr("plugins.emoji-loading"),
              "description": I18n.tr("plugins.emoji-loading-description"),
              "icon": "view-refresh",
              "isImage": false,
              "onActivate": function () {}
            }
          ];
    }

    const query = searchText.slice(6).trim();
    const emojis = EmojiService.search(query);
    return emojis.map(formatEmojiEntry);
  }

  // Format an emoji entry for the results list
  function formatEmojiEntry(emoji) {
    let title = emoji.name;
    let description = (emoji.keywords || []).join(", ");

    if (emoji.category) {
      description += " • Category: " + emoji.category;
    }

    const emojiChar = emoji.emoji;

    return {
      "name": title,
      "description": description,
      "icon": null,
      "isImage": false,
      "emojiChar": emojiChar,
      "onActivate": function () {
        EmojiService.copy(emojiChar);
        launcher.close();
      }
    };
  }
}
