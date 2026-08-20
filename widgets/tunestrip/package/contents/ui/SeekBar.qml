/*
 * Position along the track: draggable when the player allows seeking, a plain
 * read-out when it does not (many web players report no seek support).
 */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../code/util.js" as Util

ColumnLayout {
    id: seek

    property var backend
    property color accentColor: Kirigami.Theme.highlightColor

    spacing: 0

    PlasmaComponents.Slider {
        id: slider

        Layout.fillWidth: true
        enabled: seek.backend && seek.backend.canSeek
        from: 0
        to: 1
        /* While a finger is on the handle the player must not fight back. */
        onMoved: if (seek.backend) seek.backend.seekFraction(value)
    }

    Binding {
        target: slider
        property: "value"
        value: seek.backend ? seek.backend.progress : 0
        when: !slider.pressed
        restoreMode: Binding.RestoreBindingOrValue
    }

    RowLayout {
        Layout.fillWidth: true

        Text {
            text: seek.backend ? Util.duration(seek.backend.position) : "0:00"
            color: Kirigami.Theme.textColor
            opacity: 0.6
            font: Kirigami.Theme.smallFont
        }

        Item { Layout.fillWidth: true }

        Text {
            text: seek.backend && seek.backend.length > 0
                  ? Util.duration(seek.backend.length) : ""
            color: Kirigami.Theme.textColor
            opacity: 0.6
            font: Kirigami.Theme.smallFont
        }
    }
}
