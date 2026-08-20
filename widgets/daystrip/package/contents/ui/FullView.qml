/* The popup: clock and current weather on top, then the forecast, the month
   and the agenda for whichever day is selected. */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "../code/util.js" as Util

Item {
    id: full

    property var backend

    property date displayedMonth: new Date()
    property date selectedDate: new Date()

    Layout.minimumWidth: Kirigami.Units.gridUnit * 24
    Layout.preferredWidth: Kirigami.Units.gridUnit * 30
    Layout.minimumHeight: Kirigami.Units.gridUnit * 20
    Layout.preferredHeight: Kirigami.Units.gridUnit * 36

    Launcher {
        id: launcher
    }

    function showToday() {
        var today = backend ? backend.now : new Date()
        displayedMonth = new Date(today.getFullYear(), today.getMonth(), 1)
        selectedDate = new Date(today.getFullYear(), today.getMonth(), today.getDate())
    }

    function shiftMonth(delta) {
        displayedMonth = new Date(displayedMonth.getFullYear(), displayedMonth.getMonth() + delta, 1)
    }

    Component.onCompleted: showToday()

    Loader {
        anchors.fill: parent
        active: full.backend !== null && full.backend !== undefined
        sourceComponent: contentComponent
    }

    Component {
    id: contentComponent

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        // ------------------------------------------------------------ header
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.smallSpacing
            Layout.topMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.largeSpacing

            ColumnLayout {
                spacing: 0

                Text {
                    text: Util.formatTime(full.backend.now,
                                          Plasmoid.configuration.use24Hour,
                                          Plasmoid.configuration.showSeconds)
                    color: Kirigami.Theme.textColor
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 2.4
                    font.weight: Font.Light
                    lineHeight: 0.95
                    lineHeightMode: Text.ProportionalHeight
                }

                Text {
                    text: Util.weekday(full.backend.now, false) + ", "
                          + full.backend.now.getDate() + " " + Util.monthNames[full.backend.now.getMonth()]
                    color: Kirigami.Theme.textColor
                    opacity: 0.55
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                }
            }

            Item { Layout.fillWidth: true }

            /* Current conditions, right-aligned against the clock. */
            RowLayout {
                visible: full.backend.weather !== null
                spacing: Kirigami.Units.smallSpacing

                ColumnLayout {
                    spacing: 0

                    Text {
                        text: full.backend.weather
                              ? Util.temperature(full.backend.weather.temperature,
                                                 Plasmoid.configuration.temperatureUnit)
                              : ""
                        color: Kirigami.Theme.textColor
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.5
                        font.weight: Font.Light
                        horizontalAlignment: Text.AlignRight
                        Layout.alignment: Qt.AlignRight
                    }

                    Text {
                        text: full.backend.weather ? Util.weatherLabel(full.backend.weather.code) : ""
                        color: Kirigami.Theme.textColor
                        opacity: 0.55
                        font: Kirigami.Theme.smallFont
                        horizontalAlignment: Text.AlignRight
                        Layout.alignment: Qt.AlignRight
                    }

                    Text {
                        text: full.backend.locationName
                        visible: text.length > 0
                        color: Kirigami.Theme.textColor
                        opacity: 0.4
                        font: Kirigami.Theme.smallFont
                        horizontalAlignment: Text.AlignRight
                        Layout.alignment: Qt.AlignRight
                    }
                }

                WeatherGlyph {
                    code: full.backend.weather ? full.backend.weather.code : 3
                    day: full.backend.weather ? full.backend.weather.isDay : true
                    implicitWidth: Kirigami.Units.iconSizes.huge
                    implicitHeight: Kirigami.Units.iconSizes.huge
                }
            }
        }

        // ------------------------------------------------------------- cards
        PlasmaComponents.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth

            ColumnLayout {
                width: parent.width
                spacing: Kirigami.Units.smallSpacing * 2

                // ---- weather
                Card {
                    title: "Weather"
                    accentColor: Util.accent.weather
                    visible: Plasmoid.configuration.popupWeather
                    headline: full.backend.weatherError.length > 0
                              ? full.backend.weatherError
                              : (full.backend.hasLocation ? full.backend.locationName : "No location set")

                    GridLayout {
                        Layout.fillWidth: true
                        visible: full.backend.weather !== null
                        columns: 2
                        columnSpacing: Kirigami.Units.largeSpacing
                        rowSpacing: Kirigami.Units.smallSpacing

                        StatLine {
                            label: "Feels like"
                            value: full.backend.weather
                                   ? Util.temperature(full.backend.weather.apparent,
                                                      Plasmoid.configuration.temperatureUnit)
                                   : "--"
                            valueSample: "-00°F"
                            emphasized: true
                        }
                        StatLine {
                            label: "Humidity"
                            value: full.backend.weather ? Util.percent(full.backend.weather.humidity) : "--"
                            valueSample: "100%"
                        }
                        StatLine {
                            label: "Wind"
                            value: full.backend.weather
                                   ? Util.wind(full.backend.weather.wind, Plasmoid.configuration.windUnit)
                                   : "--"
                            valueSample: "000 km/h"
                        }
                        StatLine {
                            label: "Sunrise / sunset"
                            value: full.backend.sunTimes
                                   ? full.backend.sunTimes.sunrise + " – " + full.backend.sunTimes.sunset
                                   : "--"
                            valueSample: "00:00 – 00:00"
                        }
                    }

                    Text {
                        visible: !full.backend.hasLocation
                        text: "Pick a city in the widget settings to see the forecast."
                        color: Kirigami.Theme.textColor
                        opacity: 0.5
                        font: Kirigami.Theme.smallFont
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    ForecastList {
                        Layout.fillWidth: true
                        Layout.topMargin: Kirigami.Units.smallSpacing
                        visible: Plasmoid.configuration.popupForecast && full.backend.forecast.length > 0
                        backend: full.backend
                    }
                }

                // ---- calendar
                Card {
                    title: "Calendar"
                    accentColor: Util.accent.calendar
                    visible: Plasmoid.configuration.popupCalendar
                    headline: Util.monthNames[full.displayedMonth.getMonth()] + " "
                              + full.displayedMonth.getFullYear()

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        PlasmaComponents.ToolButton {
                            icon.name: "go-previous"
                            display: PlasmaComponents.AbstractButton.IconOnly
                            text: "Previous month"
                            onClicked: full.shiftMonth(-1)
                        }

                        Item { Layout.fillWidth: true }

                        PlasmaComponents.ToolButton {
                            text: "Today"
                            onClicked: full.showToday()
                        }

                        Item { Layout.fillWidth: true }

                        PlasmaComponents.ToolButton {
                            icon.name: "go-next"
                            display: PlasmaComponents.AbstractButton.IconOnly
                            text: "Next month"
                            onClicked: full.shiftMonth(1)
                        }
                    }

                    MonthGrid {
                        Layout.fillWidth: true
                        backend: full.backend
                        displayedMonth: full.displayedMonth
                        selectedDate: full.selectedDate
                        firstDayMonday: Plasmoid.configuration.firstDayMonday
                        revision: full.backend.calendarRevision
                        onDaySelected: function (day) {
                            full.selectedDate = day
                            if (day.getMonth() !== full.displayedMonth.getMonth())
                                full.displayedMonth = new Date(day.getFullYear(), day.getMonth(), 1)
                        }
                    }
                }

                // ---- agenda
                Card {
                    id: agendaCard

                    readonly property bool showingUpcoming:
                        Util.sameDay(full.selectedDate, full.backend.now)
                        && full.backend.eventsOn(full.selectedDate).length === 0

                    title: showingUpcoming
                           ? "Upcoming"
                           : (Util.sameDay(full.selectedDate, full.backend.now)
                              ? "Today" : Util.formatDate(full.selectedDate, "full"))
                    accentColor: Util.accent.event
                    visible: Plasmoid.configuration.popupAgenda
                    headline: full.backend.calendarError.length > 0
                              ? full.backend.calendarError
                              : (full.backend.calendarSources.length > 0
                                  ? full.backend.calendarSources.length + " calendars" : "")

                    AgendaList {
                        Layout.fillWidth: true
                        backend: full.backend
                        day: full.selectedDate
                        revision: full.backend.calendarRevision
                    }
                }
            }
        }
    }
    }
}
