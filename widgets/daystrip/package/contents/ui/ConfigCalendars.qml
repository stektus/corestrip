import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property var cfg_calendarNames: []
    property var cfg_calendarUrls: []
    property alias cfg_calendarIntervalMinutes: intervalBox.value

    /* Edited here, written back to the two string lists KConfig stores. */
    ListModel {
        id: entries
    }

    function loadEntries() {
        entries.clear()
        var urls = cfg_calendarUrls || []
        var names = cfg_calendarNames || []
        for (var i = 0; i < urls.length; i++) {
            entries.append({
                name: i < names.length ? String(names[i]) : "",
                url: String(urls[i])
            })
        }
    }

    function storeEntries() {
        var names = []
        var urls = []
        for (var i = 0; i < entries.count; i++) {
            var entry = entries.get(i)
            if (!entry.url)
                continue
            names.push(entry.name)
            urls.push(entry.url)
        }
        cfg_calendarNames = names
        cfg_calendarUrls = urls
    }

    Component.onCompleted: loadEntries()

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing

        QQC2.Label {
            text: "Add the calendar's private iCal address. In Google Calendar it is under "
                  + "Settings → Settings for my calendars → Integrate calendar → "
                  + "\"Secret address in iCal format\". Nextcloud, Outlook and any CalDAV "
                  + "server that publishes an .ics link work the same way."
            wrapMode: Text.WordWrap
            opacity: 0.75
            Layout.fillWidth: true
        }

        QQC2.Label {
            text: "Treat these links as passwords: anyone holding one can read that calendar. "
                  + "They are stored in this widget's own configuration file."
            wrapMode: Text.WordWrap
            opacity: 0.6
            font: Kirigami.Theme.smallFont
            Layout.fillWidth: true
        }

        QQC2.Frame {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                spacing: Kirigami.Units.smallSpacing

                ListView {
                    id: entryView

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: Kirigami.Units.smallSpacing
                    model: entries

                    delegate: RowLayout {
                        id: row

                        required property int index
                        required property string name
                        required property string url

                        width: entryView.width
                        spacing: Kirigami.Units.smallSpacing

                        QQC2.TextField {
                            text: row.name
                            placeholderText: "Name"
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                            onEditingFinished: {
                                entries.setProperty(row.index, "name", text)
                                page.storeEntries()
                            }
                        }

                        QQC2.TextField {
                            text: row.url
                            placeholderText: "https://calendar.google.com/calendar/ical/…/basic.ics"
                            Layout.fillWidth: true
                            onEditingFinished: {
                                entries.setProperty(row.index, "url", text)
                                page.storeEntries()
                            }
                        }

                        QQC2.ToolButton {
                            icon.name: "list-remove"
                            display: QQC2.AbstractButton.IconOnly
                            text: "Remove"
                            onClicked: {
                                entries.remove(row.index)
                                page.storeEntries()
                            }
                        }
                    }
                }

                QQC2.Button {
                    text: "Add calendar"
                    icon.name: "list-add"
                    Layout.alignment: Qt.AlignLeft
                    onClicked: entries.append({ name: "", url: "" })
                }
            }
        }

        Kirigami.FormLayout {
            Layout.fillWidth: true

            QQC2.SpinBox {
                id: intervalBox
                Kirigami.FormData.label: "Refresh every:"
                from: 5
                to: 240
                stepSize: 5
                textFromValue: function (value) {
                    return value + " minutes"
                }
                valueFromText: function (text) {
                    return parseInt(text) || 30
                }
            }
        }
    }
}
