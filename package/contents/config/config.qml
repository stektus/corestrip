import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: "Panel"
        icon: "configure"
        source: "ConfigPanel.qml"
    }
    ConfigCategory {
        name: "Details"
        icon: "view-list-details"
        source: "ConfigDetails.qml"
    }
}
