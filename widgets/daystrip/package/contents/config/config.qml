import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: "Panel"
        icon: "configure"
        source: "ConfigPanel.qml"
    }
    ConfigCategory {
        name: "Weather"
        icon: "weather-few-clouds"
        source: "ConfigWeather.qml"
    }
    ConfigCategory {
        name: "Calendars"
        icon: "view-calendar"
        source: "ConfigCalendars.qml"
    }
}
