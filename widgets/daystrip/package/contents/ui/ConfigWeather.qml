import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property string cfg_locationName
    property double cfg_latitude
    property double cfg_longitude
    property string cfg_temperatureUnit
    property string cfg_windUnit
    property alias cfg_weatherIntervalMinutes: intervalBox.value

    property var results: []
    property bool searching: false
    property string searchError: ""

    /* Open-Meteo's geocoding endpoint: no key, no account.
       Typing triggers the search after a short pause. */
    property string pendingQuery: ""

    Timer {
        id: searchDebounce
        interval: 350
        onTriggered: page.search(page.pendingQuery)
    }

    function queryChanged(text) {
        page.pendingQuery = text
        page.searchError = ""
        if (text.trim().length < 2) {
            page.results = []
            searchDebounce.stop()
            return
        }
        searchDebounce.restart()
    }

    function search(query) {
        if (query.trim().length < 2)
            return
        page.searching = true
        page.searchError = ""
        var issued = query

        var request = new XMLHttpRequest()
        request.open("GET", "https://geocoding-api.open-meteo.com/v1/search?count=8&language=en&format=json&name="
                     + encodeURIComponent(query))
        request.onreadystatechange = function () {
            if (request.readyState !== XMLHttpRequest.DONE)
                return
            if (issued !== page.pendingQuery)
                return              /* a newer keystroke already took over */
            page.searching = false
            if (request.status !== 200) {
                page.searchError = "Search failed (" + request.status + ")"
                return
            }
            try {
                var data = JSON.parse(request.responseText)
                var found = []
                var entries = data.results || []
                for (var i = 0; i < entries.length; i++) {
                    var entry = entries[i]
                    var label = [entry.name, entry.admin1, entry.country].filter(function (part) {
                        return !!part
                    }).join(", ")
                    found.push({ label: label, name: entry.name,
                                 latitude: entry.latitude, longitude: entry.longitude })
                }
                page.results = found
                if (found.length === 0)
                    page.searchError = "Nothing found"
            } catch (error) {
                page.searchError = "Could not read the answer"
            }
        }
        request.send()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing

        Kirigami.FormLayout {
            Layout.fillWidth: true

            RowLayout {
                Kirigami.FormData.label: "Location:"
                spacing: Kirigami.Units.smallSpacing

                QQC2.TextField {
                    id: queryField
                    placeholderText: "Start typing a city…"
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 14
                    onTextChanged: page.queryChanged(text)
                    onAccepted: page.search(text)
                }

                QQC2.BusyIndicator {
                    running: page.searching
                    visible: page.searching
                    implicitWidth: Kirigami.Units.iconSizes.small
                    implicitHeight: Kirigami.Units.iconSizes.small
                }
            }

            QQC2.Label {
                Kirigami.FormData.label: "Selected:"
                text: page.cfg_locationName.length > 0
                      ? page.cfg_locationName + "  (" + page.cfg_latitude.toFixed(2)
                        + ", " + page.cfg_longitude.toFixed(2) + ")"
                      : "None — the widget will not show weather"
                opacity: page.cfg_locationName.length > 0 ? 1 : 0.6
            }

            QQC2.ComboBox {
                Kirigami.FormData.label: "Temperature:"
                textRole: "label"
                valueRole: "key"
                model: [
                    { key: "celsius", label: "Celsius" },
                    { key: "fahrenheit", label: "Fahrenheit" }
                ]
                currentIndex: Math.max(0, indexOfValue(page.cfg_temperatureUnit))
                onActivated: page.cfg_temperatureUnit = currentValue
            }

            QQC2.ComboBox {
                Kirigami.FormData.label: "Wind speed:"
                textRole: "label"
                valueRole: "key"
                model: [
                    { key: "kmh", label: "km/h" },
                    { key: "ms", label: "m/s" },
                    { key: "mph", label: "mph" }
                ]
                currentIndex: Math.max(0, indexOfValue(page.cfg_windUnit))
                onActivated: page.cfg_windUnit = currentValue
            }

            QQC2.SpinBox {
                id: intervalBox
                Kirigami.FormData.label: "Refresh every:"
                from: 5
                to: 180
                stepSize: 5
                textFromValue: function (value) {
                    return value + " minutes"
                }
                valueFromText: function (text) {
                    return parseInt(text) || 15
                }
            }
        }

        QQC2.Label {
            visible: page.searchError.length > 0
            text: page.searchError
            opacity: 0.7
        }

        QQC2.Frame {
            visible: page.results.length > 0
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: resultView
                anchors.fill: parent
                clip: true
                model: page.results

                delegate: QQC2.ItemDelegate {
                    required property var modelData

                    width: resultView.width
                    text: modelData.label
                    onClicked: {
                        page.cfg_locationName = modelData.name
                        page.cfg_latitude = modelData.latitude
                        page.cfg_longitude = modelData.longitude
                        page.results = []
                    }
                }
            }
        }

        QQC2.Label {
            text: "Forecast data by Open-Meteo. No account or API key is needed, and only the chosen coordinates are sent."
            wrapMode: Text.WordWrap
            opacity: 0.6
            font: Kirigami.Theme.smallFont
            Layout.fillWidth: true
        }
    }
}
