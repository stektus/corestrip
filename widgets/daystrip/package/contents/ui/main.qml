/*
 * Daystrip — clock, date and weather in the panel, with a calendar,
 * forecast and agenda in the popup.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property Backend backend: Backend {
        id: dayBackend
        detailed: root.expanded
        showSeconds: Plasmoid.configuration.showSeconds

        locationName: Plasmoid.configuration.locationName
        latitude: Plasmoid.configuration.latitude
        longitude: Plasmoid.configuration.longitude
        temperatureUnit: Plasmoid.configuration.temperatureUnit
        windUnit: Plasmoid.configuration.windUnit
        weatherIntervalMinutes: Plasmoid.configuration.weatherIntervalMinutes

        calendarIntervalMinutes: Plasmoid.configuration.calendarIntervalMinutes
        calendarSources: {
            var urls = Plasmoid.configuration.calendarUrls
            var names = Plasmoid.configuration.calendarNames
            var sources = []
            for (var i = 0; i < urls.length; i++) {
                if (!urls[i])
                    continue
                sources.push({
                    url: urls[i],
                    name: i < names.length && names[i] ? names[i] : "Calendar " + (i + 1),
                    color: dayBackend.eventColors[i % dayBackend.eventColors.length]
                })
            }
            return sources
        }
    }

    readonly property Launcher launcher: Launcher {}

    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar
                             ? fullRepresentation : compactRepresentation

    compactRepresentation: CompactView {
        backend: root.backend
        onToggleRequested: root.expanded = !root.expanded
    }

    fullRepresentation: FullView {
        backend: root.backend
    }

    toolTipItem: ToolTipView {
        backend: root.backend
        Layout.minimumWidth: Kirigami.Units.gridUnit * 14
        Layout.preferredWidth: Kirigami.Units.gridUnit * 16
        Layout.maximumWidth: Kirigami.Units.gridUnit * 20
        Layout.minimumHeight: implicitHeight
        Layout.preferredHeight: implicitHeight
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: "Refresh now"
            icon.name: "view-refresh"
            onTriggered: {
                root.backend.refreshWeather()
                root.backend.refreshCalendars()
            }
        },
        PlasmaCore.Action {
            text: "Adjust date and time…"
            icon.name: "clock"
            onTriggered: root.launcher.run("kcmshell6 kcm_clock")
        }
    ]
}
