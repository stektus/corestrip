import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: "Panel"
        icon: "configure"
        source: "ConfigPanel.qml"
    }
    ConfigCategory {
        name: "Equalizer"
        icon: "view-media-visualization"
        source: "ConfigVisualizer.qml"
    }
    ConfigCategory {
        name: "Popup"
        icon: "media-playback-start"
        source: "ConfigPopup.qml"
    }
}
