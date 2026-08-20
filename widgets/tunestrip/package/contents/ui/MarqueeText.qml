/*
 * One line of text that scrolls when it does not fit, and simply sits there
 * when it does. Panel space is scarce and titles are long.
 */
import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: marquee

    property string text: ""
    property color textColor: Kirigami.Theme.textColor
    property int pixelSize: Kirigami.Theme.defaultFont.pixelSize
    property int weight: Font.Normal
    property bool scrolling: true
    property real speed: 26                     // pixels per second
    property real gap: Kirigami.Units.gridUnit * 2

    readonly property real textWidth: metrics.width
    readonly property bool overflowing: textWidth > width + 0.5
    readonly property bool running: overflowing && scrolling && visible

    implicitWidth: metrics.width
    implicitHeight: metrics.height
    clip: true

    TextMetrics {
        id: metrics
        font.pixelSize: marquee.pixelSize
        font.weight: marquee.weight
        text: marquee.text
    }

    property real offset: 0

    Text {
        id: primary
        x: marquee.running ? marquee.offset : 0
        width: marquee.running ? marquee.textWidth : marquee.width
        height: parent.height
        text: marquee.text
        color: marquee.textColor
        font.pixelSize: marquee.pixelSize
        font.weight: marquee.weight
        elide: marquee.running ? Text.ElideNone : Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }

    /* The second copy is what makes the loop seamless: it enters on the right
       as the first one leaves on the left. */
    Text {
        x: primary.x + marquee.textWidth + marquee.gap
        height: parent.height
        visible: marquee.running
        text: marquee.text
        color: marquee.textColor
        font.pixelSize: marquee.pixelSize
        font.weight: marquee.weight
        verticalAlignment: Text.AlignVCenter
    }

    SequentialAnimation {
        running: marquee.running
        loops: Animation.Infinite

        /* A pause at the start, so a glance at the panel usually catches the
           beginning of the title rather than its middle. */
        PauseAnimation { duration: 1800 }
        NumberAnimation {
            target: marquee
            property: "offset"
            from: 0
            to: -(marquee.textWidth + marquee.gap)
            duration: Math.max(1200, ((marquee.textWidth + marquee.gap) / marquee.speed) * 1000)
        }
    }

    onTextChanged: offset = 0
    onRunningChanged: if (!running) offset = 0
}
