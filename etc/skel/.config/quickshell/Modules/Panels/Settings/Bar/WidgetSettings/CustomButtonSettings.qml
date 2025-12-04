import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import qs.Commons
import qs.Services.UI
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginM

  property var widgetData: null
  property var widgetMetadata: null

  property string valueIcon: widgetData.icon !== undefined ? widgetData.icon : widgetMetadata.icon
  property bool valueTextStream: widgetData.textStream !== undefined ? widgetData.textStream : widgetMetadata.textStream
  property bool valueParseJson: widgetData.parseJson !== undefined ? widgetData.parseJson : widgetMetadata.parseJson
  property int valueMaxTextLengthHorizontal: widgetData?.maxTextLength?.horizontal ?? widgetMetadata?.maxTextLength?.horizontal
  property int valueMaxTextLengthVertical: widgetData?.maxTextLength?.vertical ?? widgetMetadata?.maxTextLength?.vertical

  function saveSettings() {
    var settings = Object.assign({}, widgetData || {});
    settings.icon = valueIcon;
    settings.leftClickExec = leftClickExecInput.text;
    settings.leftClickUpdateText = leftClickUpdateText.checked;
    settings.rightClickExec = rightClickExecInput.text;
    settings.rightClickUpdateText = rightClickUpdateText.checked;
    settings.middleClickExec = middleClickExecInput.text;
    settings.middleClickUpdateText = middleClickUpdateText.checked;
    settings.wheelMode = separateWheelToggle.internalChecked ? "separate" : "unified";
    settings.wheelExec = wheelExecInput.text;
    settings.wheelUpExec = wheelUpExecInput.text;
    settings.wheelDownExec = wheelDownExecInput.text;
    settings.wheelUpdateText = wheelUpdateText.checked;
    settings.wheelUpUpdateText = wheelUpUpdateText.checked;
    settings.wheelDownUpdateText = wheelDownUpdateText.checked;
    settings.textCommand = textCommandInput.text;
    settings.textCollapse = textCollapseInput.text;
    settings.textStream = valueTextStream;
    settings.parseJson = valueParseJson;
    settings.maxTextLength = {
      "horizontal": valueMaxTextLengthHorizontal,
      "vertical": valueMaxTextLengthVertical
    };
    settings.textIntervalMs = parseInt(textIntervalInput.text || textIntervalInput.placeholderText, 10);
    return settings;
  }

  NScrollView {
    Layout.preferredWidth: Math.round(600 * Style.uiScaleRatio)
    Layout.preferredHeight: Math.round(700 * Style.uiScaleRatio)
    horizontalPolicy: ScrollBar.AlwaysOff
    verticalPolicy: ScrollBar.AsNeeded
    padding: Style.marginL
    focus: true

    ColumnLayout {
      width: parent.width
      spacing: Style.marginM

      RowLayout {
        spacing: Style.marginM

        NLabel {
          label: I18n.tr("bar.widget-settings.custom-button.icon.label")
          description: I18n.tr("bar.widget-settings.custom-button.icon.description")
        }

        NIcon {
          Layout.alignment: Qt.AlignVCenter
          icon: valueIcon
          pointSize: Style.fontSizeXL
          visible: valueIcon !== ""
        }

        NButton {
          text: I18n.tr("bar.widget-settings.custom-button.browse")
          onClicked: iconPicker.open()
        }
      }

      NIconPicker {
        id: iconPicker
        initialIcon: valueIcon
        onIconSelected: function (iconName) {
          valueIcon = iconName;
        }
      }

      RowLayout {
        spacing: Style.marginM

        NTextInput {
          id: leftClickExecInput
          Layout.fillWidth: true
          label: I18n.tr("bar.widget-settings.custom-button.left-click.label")
          description: I18n.tr("bar.widget-settings.custom-button.left-click.description")
          placeholderText: I18n.tr("placeholders.enter-command")
          text: widgetData?.leftClickExec || widgetMetadata.leftClickExec
        }

        NToggle {
          id: leftClickUpdateText
          enabled: !valueTextStream
          Layout.alignment: Qt.AlignRight | Qt.AlignBottom
          Layout.bottomMargin: Style.marginS
          onEntered: TooltipService.show(leftClickUpdateText, I18n.tr("bar.widget-settings.custom-button.left-click.update-text"), "auto")
          onExited: TooltipService.hide()
          checked: widgetData?.leftClickUpdateText ?? widgetMetadata.leftClickUpdateText
          onToggled: isChecked => checked = isChecked
        }
      }

      RowLayout {
        spacing: Style.marginM

        NTextInput {
          id: rightClickExecInput
          Layout.fillWidth: true
          label: I18n.tr("bar.widget-settings.custom-button.right-click.label")
          description: I18n.tr("bar.widget-settings.custom-button.right-click.description")
          placeholderText: I18n.tr("placeholders.enter-command")
          text: widgetData?.rightClickExec || widgetMetadata.rightClickExec
        }

        NToggle {
          id: rightClickUpdateText
          enabled: !valueTextStream
          Layout.alignment: Qt.AlignRight | Qt.AlignBottom
          Layout.bottomMargin: Style.marginS
          onEntered: TooltipService.show(rightClickUpdateText, I18n.tr("bar.widget-settings.custom-button.right-click.update-text"), "auto")
          onExited: TooltipService.hide()
          checked: widgetData?.rightClickUpdateText ?? widgetMetadata.rightClickUpdateText
          onToggled: isChecked => checked = isChecked
        }
      }

      RowLayout {
        spacing: Style.marginM

        NTextInput {
          id: middleClickExecInput
          Layout.fillWidth: true
          label: I18n.tr("bar.widget-settings.custom-button.middle-click.label")
          description: I18n.tr("bar.widget-settings.custom-button.middle-click.description")
          placeholderText: I18n.tr("placeholders.enter-command")
          text: widgetData.middleClickExec || widgetMetadata.middleClickExec
        }

        NToggle {
          id: middleClickUpdateText
          enabled: !valueTextStream
          Layout.alignment: Qt.AlignRight | Qt.AlignBottom
          Layout.bottomMargin: Style.marginS
          onEntered: TooltipService.show(middleClickUpdateText, I18n.tr("bar.widget-settings.custom-button.middle-click.update-text"), "auto")
          onExited: TooltipService.hide()
          checked: widgetData?.middleClickUpdateText ?? widgetMetadata.middleClickUpdateText
          onToggled: isChecked => checked = isChecked
        }
      }

      // Wheel command settings
      NToggle {
        id: separateWheelToggle
        Layout.fillWidth: true
        label: I18n.tr("bar.widget-settings.custom-button.wheel-mode-separate.label", "Separate wheel commands")
        description: I18n.tr("bar.widget-settings.custom-button.wheel-mode-separate.description", "Enable separate commands for wheel up and down")
        property bool internalChecked: (widgetData?.wheelMode || widgetMetadata?.wheelMode || "unified") === "separate"
        checked: internalChecked
        onToggled: checked => {
                     internalChecked = checked;
                   }
      }

      ColumnLayout {
        Layout.fillWidth: true
        Layout.preferredWidth: parent.width

        RowLayout {
          id: unifiedWheelLayout
          visible: !separateWheelToggle.checked
          spacing: Style.marginM

          NTextInput {
            id: wheelExecInput
            Layout.fillWidth: true
            label: I18n.tr("bar.widget-settings.custom-button.wheel.label")
            description: I18n.tr("bar.widget-settings.custom-button.wheel.description")
            placeholderText: I18n.tr("placeholders.enter-command")
            text: widgetData?.wheelExec || widgetMetadata?.wheelExec || ""
          }

          NToggle {
            id: wheelUpdateText
            enabled: !valueTextStream
            Layout.alignment: Qt.AlignRight | Qt.AlignBottom
            Layout.bottomMargin: Style.marginS
            onEntered: TooltipService.show(wheelUpdateText, I18n.tr("bar.widget-settings.custom-button.wheel.update-text"), "auto")
            onExited: TooltipService.hide()
            checked: widgetData?.wheelUpdateText ?? widgetMetadata?.wheelUpdateText
            onToggled: isChecked => checked = isChecked
          }
        }

        ColumnLayout {
          id: separatedWheelLayout
          Layout.fillWidth: true
          visible: separateWheelToggle.checked

          RowLayout {
            spacing: Style.marginM

            NTextInput {
              id: wheelUpExecInput
              Layout.fillWidth: true
              label: I18n.tr("bar.widget-settings.custom-button.wheel-up.label")
              description: I18n.tr("bar.widget-settings.custom-button.wheel-up.description")
              placeholderText: I18n.tr("placeholders.enter-command")
              text: widgetData?.wheelUpExec || widgetMetadata?.wheelUpExec || ""
            }

            NToggle {
              id: wheelUpUpdateText
              enabled: !valueTextStream
              Layout.alignment: Qt.AlignRight | Qt.AlignBottom
              Layout.bottomMargin: Style.marginS
              onEntered: TooltipService.show(wheelUpUpdateText, I18n.tr("bar.widget-settings.custom-button.wheel.update-text"), "auto")
              onExited: TooltipService.hide()
              checked: (widgetData?.wheelUpUpdateText !== undefined) ? widgetData.wheelUpUpdateText : (widgetMetadata?.wheelUpUpdateText ?? false)
              onToggled: isChecked => checked = isChecked
            }
          }

          RowLayout {
            spacing: Style.marginM

            NTextInput {
              id: wheelDownExecInput
              Layout.fillWidth: true
              label: I18n.tr("bar.widget-settings.custom-button.wheel-down.label")
              description: I18n.tr("bar.widget-settings.custom-button.wheel-down.description")
              placeholderText: I18n.tr("placeholders.enter-command")
              text: widgetData?.wheelDownExec || widgetMetadata?.wheelDownExec || ""
            }

            NToggle {
              id: wheelDownUpdateText
              enabled: !valueTextStream
              Layout.alignment: Qt.AlignRight | Qt.AlignBottom
              Layout.bottomMargin: Style.marginS
              onEntered: TooltipService.show(wheelDownUpdateText, I18n.tr("bar.widget-settings.custom-button.wheel.update-text"), "auto")
              onExited: TooltipService.hide()
              checked: (widgetData?.wheelDownUpdateText !== undefined) ? widgetData.wheelDownUpdateText : (widgetMetadata?.wheelDownUpdateText ?? false)
              onToggled: isChecked => checked = isChecked
            }
          }
        }
      }

      NDivider {
        Layout.fillWidth: true
      }

      NHeader {
        label: I18n.tr("bar.widget-settings.custom-button.dynamic-text")
      }

      NSpinBox {
        label: I18n.tr("bar.widget-settings.custom-button.max-text-length-horizontal.label", "Max text length (horizontal)")
        description: I18n.tr("bar.widget-settings.custom-button.max-text-length-horizontal.description", "Maximum number of characters to show in horizontal bar (0 to hide text)")
        from: 0
        to: 100
        value: valueMaxTextLengthHorizontal
        onValueChanged: valueMaxTextLengthHorizontal = value
      }

      NSpinBox {
        label: I18n.tr("bar.widget-settings.custom-button.max-text-length-vertical.label", "Max text length (vertical)")
        description: I18n.tr("bar.widget-settings.custom-button.max-text-length-vertical.description", "Maximum number of characters to show in vertical bar (0 to hide text)")
        from: 0
        to: 100
        value: valueMaxTextLengthVertical
        onValueChanged: valueMaxTextLengthVertical = value
      }

      NToggle {
        id: textStreamInput
        label: I18n.tr("bar.widget-settings.custom-button.text-stream.label")
        description: I18n.tr("bar.widget-settings.custom-button.text-stream.description")
        checked: valueTextStream
        onToggled: checked => valueTextStream = checked
      }

      NToggle {
        id: parseJsonInput
        label: I18n.tr("bar.widget-settings.custom-button.parse-json.label", "Parse output as JSON")
        description: I18n.tr("bar.widget-settings.custom-button.parse-json.description", "Parse the command output as a JSON object to dynamically set text and icon.")
        checked: valueParseJson
        onToggled: checked => valueParseJson = checked
      }

      NTextInput {
        id: textCommandInput
        Layout.fillWidth: true
        label: I18n.tr("bar.widget-settings.custom-button.display-command-output.label")
        description: valueTextStream ? I18n.tr("bar.widget-settings.custom-button.display-command-output.stream-description") : I18n.tr("bar.widget-settings.custom-button.display-command-output.description")
        placeholderText: I18n.tr("placeholders.command-example")
        text: widgetData?.textCommand || widgetMetadata.textCommand
      }

      NTextInput {
        id: textCollapseInput
        Layout.fillWidth: true
        visible: valueTextStream
        label: I18n.tr("bar.widget-settings.custom-button.collapse-condition.label")
        description: I18n.tr("bar.widget-settings.custom-button.collapse-condition.description")
        placeholderText: I18n.tr("placeholders.enter-text-to-collapse")
        text: widgetData?.textCollapse || widgetMetadata.textCollapse
      }

      NTextInput {
        id: textIntervalInput
        Layout.fillWidth: true
        visible: !valueTextStream
        label: I18n.tr("bar.widget-settings.custom-button.refresh-interval.label")
        description: I18n.tr("bar.widget-settings.custom-button.refresh-interval.description")
        placeholderText: String(widgetMetadata.textIntervalMs || 3000)
        text: widgetData && widgetData.textIntervalMs !== undefined ? String(widgetData.textIntervalMs) : ""
      }
    }
  }
}
