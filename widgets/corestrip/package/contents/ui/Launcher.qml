/* Thin wrapper over the executable data engine, used for the "open System
   Monitor" affordances. */
import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support

Plasma5Support.DataSource {
    id: launcher

    engine: "executable"
    connectedSources: []

    onNewData: function (source) {
        disconnectSource(source)
    }

    function run(command) {
        connectSource(command)
    }
}
