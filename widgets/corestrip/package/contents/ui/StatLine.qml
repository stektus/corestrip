/* label ......... value  — the popup's caption/value row.
 *
 * `valueSample` reserves the width of the longest value this row can show, so
 * a reading going from "9%" to "10%" does not shift the column. */
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

RowLayout {
    id: line

    property string label
    property string value
    property string valueSample: ""
    property color valueColor: Kirigami.Theme.textColor
    property bool emphasized: false

    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing

    TextMetrics {
        id: sampleMetrics
        font.family: valueText.font.family
        font.pointSize: valueText.font.pointSize
        font.weight: valueText.font.weight
        text: line.valueSample
    }

    Text {
        text: line.label
        color: Kirigami.Theme.textColor
        opacity: 0.55
        font: Kirigami.Theme.smallFont
        elide: Text.ElideRight
        Layout.fillWidth: true
    }

    Text {
        id: valueText
        text: line.value
        color: line.valueColor
        opacity: line.emphasized ? 1.0 : 0.9
        font.family: Kirigami.Theme.defaultFont.family
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        font.weight: line.emphasized ? Font.DemiBold : Font.Medium
        horizontalAlignment: Text.AlignRight
        Layout.preferredWidth: line.valueSample.length > 0
                               ? Math.ceil(sampleMetrics.width)
                               : implicitWidth
    }
}
