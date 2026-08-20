/* One panel gauge.  `kind` is "percent" (CPU, GPU, memory) or "rate"
   (network and disk, which have two directions and no natural maximum).

   Styles, in order of how much they tell you:
     combo  — history plot plus label and value (default)
     rings  — ring with the value inside
     bars   — history plot only
     text   — value only

   Every width is computed here rather than read back from the loaded gauge:
   asking the Loader for its item's implicit width yields zero until the item
   exists, which collapses the gauge in the panel. */
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../code/util.js" as Util

Item {
    id: metric

    property string style: "combo"
    property string kind: "percent"
    property string label: ""
    property string caption: ""
    /* Short captions (a temperature) can share the single-line readout;
       long ones (a memory size) only appear when two lines fit. */
    property bool captionInline: false
    property color metricColor: Util.accent.cpu
    property bool showLabel: false
    property bool vertical: false

    /* percent */
    property real ratio: 0
    property string valueText: ""
    property var history: []

    /* rate */
    property real downValue: 0
    property real upValue: 0
    property var downHistory: []
    property var upHistory: []
    property real rateMaximum: 1

    property int revision: 0
    property real gaugeSize: Kirigami.Units.gridUnit
    /* Text size from the settings, as a factor. Readouts are absolute point
       sizes rather than shares of the panel, so this is what makes them
       follow the setting; the plots and rings scale through gaugeSize. */
    property real fontFactor: 1

    readonly property real readoutPoint: Math.max(5, Kirigami.Theme.smallFont.pointSize * fontFactor)
    readonly property real captionPoint: Math.max(5, (Kirigami.Theme.smallFont.pointSize - 1) * fontFactor)

    readonly property color liveColor: kind === "percent" ? Util.loadColor(metricColor, ratio) : metricColor
    readonly property bool labelFits: showLabel && gaugeSize >= 16
    readonly property real lineSquash: 0.86
    /* Two stacked lines only if the panel is actually tall enough for them;
       otherwise the readout falls back to a single "CPU 32% 51°" line. */
    readonly property bool twoLinesFit: gaugeSize >= (captionMetrics.height + readoutMetrics.height) * lineSquash
    readonly property bool readoutFits: !vertical || gaugeSize >= Kirigami.Units.gridUnit * 1.6

    readonly property real plotWidth: Math.round(gaugeSize * (vertical ? 0.7 : 0.95))
    readonly property real readoutWidth: twoLinesFit
                                         ? Math.ceil(Math.max(captionMetrics.width, readoutMetrics.width))
                                         : Math.ceil(singleLineMetrics.width)

    readonly property real gaugeWidth: {
        if (style === "combo")
            return readoutFits ? plotWidth + Kirigami.Units.smallSpacing + readoutWidth : plotWidth
        if (style === "text")
            return Math.ceil(Math.max(singleLineMetrics.width, Kirigami.Units.gridUnit * 1.6))
        if (kind === "rate")
            return vertical ? gaugeSize : Math.round(gaugeSize * 1.4)
        if (style === "bars")
            return vertical ? gaugeSize : Math.round(gaugeSize * 1.25)
        return gaugeSize
    }

    /* Reserving the widest possible readout keeps the applet from resizing —
       and shoving the rest of the panel around — on every tick. */
    TextMetrics {
        id: captionMetrics
        font.pointSize: metric.captionPoint
        font.capitalization: Font.AllUppercase
        text: metric.label + (metric.caption ? "  99.9 GiB" : "")
    }

    TextMetrics {
        id: readoutMetrics
        font.pointSize: metric.readoutPoint
        font.weight: Font.DemiBold
        text: metric.kind === "rate" ? "▾999.9M ▴999.9M" : "100%"
    }

    TextMetrics {
        id: singleLineMetrics
        font.pointSize: metric.readoutPoint
        font.weight: Font.DemiBold
        text: metric.kind === "rate"
              ? "▾999.9M ▴999.9M"
              : metric.label + " 100%" + (metric.captionInline && metric.caption ? " 100°" : "")
    }

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    RowLayout {
        id: layout
        /* centred rather than filled: the item takes its size *from* this
           layout, so anchoring the layout to the item would be circular. */
        anchors.centerIn: parent
        spacing: metric.labelFits ? Kirigami.Units.smallSpacing : 0

        Text {
            visible: metric.labelFits && !metric.vertical && metric.style !== "combo"
            text: metric.label
            color: Kirigami.Theme.textColor
            opacity: 0.6
            font.pointSize: metric.captionPoint
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 0.5
            Layout.alignment: Qt.AlignVCenter
        }

        Loader {
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: metric.gaugeWidth
            Layout.preferredHeight: metric.gaugeSize
            sourceComponent: {
                if (metric.style === "combo")
                    return comboGauge
                if (metric.kind === "rate")
                    return metric.style === "text" ? rateTextGauge : rateBarsGauge
                if (metric.style === "text")
                    return textGauge
                if (metric.style === "bars")
                    return barsGauge
                return ringGauge
            }
        }
    }

    // ------------------------------------------------ combo (plot + readout)
    Component {
        id: comboGauge

        RowLayout {
            spacing: Kirigami.Units.smallSpacing

            /* Plot: one column per sample for percentages, two mirrored
               strips for rates. */
            Item {
                Layout.preferredWidth: metric.plotWidth
                Layout.preferredHeight: metric.gaugeSize
                Layout.alignment: Qt.AlignVCenter

                MiniBars {
                    anchors.fill: parent
                    visible: metric.kind === "percent"
                    values: metric.history
                    revision: metric.revision
                    maximum: 100
                    barColor: metric.liveColor
                    barWidth: 2
                    barSpacing: 1
                }

                MiniBars {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: parent.height / 2 - 1
                    visible: metric.kind === "rate"
                    values: metric.downHistory
                    revision: metric.revision
                    maximum: metric.rateMaximum
                    barColor: metric.metricColor
                    barWidth: 2
                    barSpacing: 1
                }

                MiniBars {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: parent.height / 2 - 1
                    visible: metric.kind === "rate"
                    values: metric.upHistory
                    revision: metric.revision
                    maximum: metric.rateMaximum
                    barColor: Util.accent.disk
                    barWidth: 2
                    barSpacing: 1
                }
            }

            ColumnLayout {
                spacing: 0
                visible: metric.readoutFits
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: metric.readoutWidth

                /* Caption line: metric name, plus temperature or size when set. */
                RowLayout {
                    visible: metric.twoLinesFit
                    spacing: Kirigami.Units.smallSpacing
                    Layout.fillWidth: true

                    Text {
                        text: metric.label
                        color: Kirigami.Theme.textColor
                        opacity: 0.55
                        font.pointSize: metric.captionPoint
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 0.4
                        lineHeight: metric.lineSquash
                        lineHeightMode: Text.ProportionalHeight
                    }

                    Text {
                        visible: metric.caption.length > 0 && metric.kind !== "rate"
                        text: metric.caption
                        color: Kirigami.Theme.textColor
                        opacity: 0.4
                        font.pointSize: metric.captionPoint
                        lineHeight: metric.lineSquash
                        lineHeightMode: Text.ProportionalHeight
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                /* Short panels get one line: "CPU 32% 51°". */
                RowLayout {
                    visible: metric.kind === "percent"
                    spacing: Math.round(Kirigami.Units.smallSpacing / 2)
                    Layout.alignment: Qt.AlignLeft

                    Text {
                        visible: !metric.twoLinesFit
                        text: metric.label
                        color: Kirigami.Theme.textColor
                        opacity: 0.55
                        font.pointSize: metric.captionPoint
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 0.4
                    }

                    Text {
                        text: metric.valueText
                        color: metric.liveColor
                        font.pointSize: metric.readoutPoint
                        font.weight: Font.DemiBold
                        lineHeight: metric.lineSquash
                        lineHeightMode: Text.ProportionalHeight
                    }

                    Text {
                        visible: !metric.twoLinesFit && metric.captionInline && metric.caption.length > 0
                        text: metric.caption
                        color: Kirigami.Theme.textColor
                        opacity: 0.45
                        font.pointSize: metric.captionPoint
                    }
                }

                RowLayout {
                    visible: metric.kind === "rate"
                    spacing: Kirigami.Units.smallSpacing

                    Text {
                        text: "▾" + Util.shortRate(metric.downValue)
                        color: metric.metricColor
                        font.pointSize: metric.captionPoint
                        font.weight: Font.Medium
                    }

                    Text {
                        text: "▴" + Util.shortRate(metric.upValue)
                        color: Util.accent.disk
                        font.pointSize: metric.captionPoint
                        font.weight: Font.Medium
                    }
                }
            }
        }
    }

    // ------------------------------------------------------------ percent
    Component {
        id: ringGauge

        Ring {
            value: metric.ratio
            ringColor: metric.liveColor
            thickness: Math.max(2, metric.gaugeSize * 0.16)

            Text {
                anchors.fill: parent
                visible: metric.gaugeSize >= 19
                text: Math.round(metric.ratio * 100)
                color: Kirigami.Theme.textColor
                opacity: 0.85
                font.pointSize: Math.max(5, Math.round(Math.min(metric.gaugeSize * 0.52,
                                                                metric.gaugeSize * 0.34 * metric.fontFactor)))
                font.weight: Font.DemiBold
                minimumPointSize: 5
                fontSizeMode: Text.HorizontalFit
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    Component {
        id: barsGauge

        MiniBars {
            values: metric.history
            revision: metric.revision
            maximum: 100
            barColor: metric.liveColor
            barWidth: 3
            barSpacing: 1
        }
    }

    Component {
        id: textGauge

        Text {
            text: metric.valueText
            color: metric.liveColor
            font.family: Kirigami.Theme.defaultFont.family
            font.pointSize: Math.max(6, Math.round(Math.min(metric.gaugeSize * 0.62,
                                                            metric.gaugeSize * 0.42 * metric.fontFactor)))
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
        }
    }

    // --------------------------------------------------------------- rate
    Component {
        id: rateBarsGauge

        Item {
            MiniBars {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: parent.height / 2 - 1
                values: metric.downHistory
                revision: metric.revision
                maximum: metric.rateMaximum
                barColor: metric.metricColor
                barWidth: 3
                barSpacing: 1
            }

            MiniBars {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.height / 2 - 1
                values: metric.upHistory
                revision: metric.revision
                maximum: metric.rateMaximum
                barColor: Util.accent.disk
                barWidth: 3
                barSpacing: 1
            }
        }
    }

    Component {
        id: rateTextGauge

        Item {
            Column {
                anchors.centerIn: parent
                spacing: 0

                Text {
                    anchors.right: parent.right
                    text: "▾ " + Util.shortRate(metric.downValue)
                    color: metric.metricColor
                    font.pointSize: Math.max(5, Math.round(Math.min(metric.gaugeSize * 0.42,
                                                                    metric.gaugeSize * 0.3 * metric.fontFactor)))
                    font.weight: Font.Medium
                }

                Text {
                    anchors.right: parent.right
                    text: "▴ " + Util.shortRate(metric.upValue)
                    color: Util.accent.disk
                    font.pointSize: Math.max(5, Math.round(Math.min(metric.gaugeSize * 0.42,
                                                                    metric.gaugeSize * 0.3 * metric.fontFactor)))
                    font.weight: Font.Medium
                }
            }
        }
    }
}
