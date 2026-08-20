/* Month view: seven columns, six rows, a dot per calendar with an event. */
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../code/util.js" as Util

Item {
    id: grid

    property var backend
    property date displayedMonth: new Date()
    property date selectedDate: new Date()
    property bool firstDayMonday: true
    property int revision: 0

    signal daySelected(date day)

    readonly property int weekdayOffset: firstDayMonday ? 1 : 0
    readonly property real cellWidth: width / 7
    readonly property real cellHeight: Math.round(Kirigami.Units.gridUnit * 1.9)

    /* First cell of the grid: the Monday (or Sunday) on or before the 1st. */
    readonly property date gridStart: {
        var first = new Date(displayedMonth.getFullYear(), displayedMonth.getMonth(), 1)
        var shift = (first.getDay() - weekdayOffset + 7) % 7
        return new Date(first.getFullYear(), first.getMonth(), 1 - shift)
    }

    implicitHeight: header.height + Kirigami.Units.smallSpacing + cellHeight * 6

    function dayAt(index) {
        return new Date(gridStart.getFullYear(), gridStart.getMonth(), gridStart.getDate() + index)
    }

    function markersFor(day) {
        var reactOnRevision = grid.revision
        if (!backend)
            return []
        var events = backend.eventsOn(day)
        var colors = []
        for (var i = 0; i < events.length && colors.length < 3; i++) {
            if (colors.indexOf(events[i].color) < 0)
                colors.push(events[i].color)
        }
        return colors
    }

    Row {
        id: header
        width: parent.width
        height: Math.round(Kirigami.Units.gridUnit * 1.2)

        Repeater {
            model: 7

            Item {
                required property int index

                width: grid.cellWidth
                height: header.height

                Text {
                    anchors.centerIn: parent
                    text: Util.dayShort[(index + grid.weekdayOffset) % 7]
                    color: Kirigami.Theme.textColor
                    opacity: 0.45
                    font.pointSize: Math.max(6, Kirigami.Theme.smallFont.pointSize - 1)
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: 0.5
                }
            }
        }
    }

    Grid {
        anchors.top: header.bottom
        anchors.topMargin: Kirigami.Units.smallSpacing
        width: parent.width
        columns: 7
        rows: 6

        Repeater {
            model: 42

            Item {
                id: cell

                required property int index

                readonly property date day: grid.dayAt(index)
                readonly property bool inMonth: day.getMonth() === grid.displayedMonth.getMonth()
                readonly property bool isToday: grid.backend && Util.sameDay(day, grid.backend.now)
                readonly property bool isSelected: Util.sameDay(day, grid.selectedDate)
                readonly property var markers: grid.markersFor(day)

                width: grid.cellWidth
                height: grid.cellHeight

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height) - 2
                    height: width
                    radius: width / 2
                    color: cell.isSelected ? Util.alpha(Util.accent.time, 0.22) : "transparent"
                    border.width: cell.isToday && !cell.isSelected ? 1 : 0
                    border.color: Util.alpha(Util.accent.time, 0.55)
                }

                Text {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -Kirigami.Units.smallSpacing / 2
                    text: cell.day.getDate()
                    color: cell.isToday ? Util.accent.time : Kirigami.Theme.textColor
                    opacity: cell.inMonth ? (cell.isToday ? 1 : 0.85) : 0.3
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    font.weight: cell.isToday || cell.isSelected ? Font.DemiBold : Font.Normal
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Math.round(Kirigami.Units.smallSpacing / 2)
                    spacing: 2

                    Repeater {
                        model: cell.markers

                        Rectangle {
                            required property var modelData

                            width: 4
                            height: 4
                            radius: 2
                            color: modelData
                            opacity: cell.inMonth ? 0.9 : 0.35
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: grid.daySelected(cell.day)
                }
            }
        }
    }
}
