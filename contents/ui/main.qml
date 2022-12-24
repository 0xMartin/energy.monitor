/*
 * Copyright 2021 Martin Krcma <martin.krcma1@gmail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http: //www.gnu.org/licenses/>.
 * 
 */

import QtQuick 2.7
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.1

import "../tools/power.js" as Power
 

Item {
    id: main
    anchors.fill: parent
    width: 100
    height: 40
    Layout.preferredWidth: 400 * units.devicePixelRatio
    Layout.preferredHeight: 300 * units.devicePixelRatio

    // load energy monitor main componnent
    Loader {
        id: energyMonitor
        source: "energyMonitor.qml"
    }

    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation

    // compact representation
    Plasmoid.compactRepresentation: Label {
        id: label1
        Plasmoid.backgroundHints: PlasmaCore.Types.ShadowBackground | PlasmaCore.Types.ConfigurableBackground
        anchors {
            fill: parent
            margins: Math.round(parent.width * 0.05)
        }
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCente
        font.pixelSize: 1000;
        minimumPointSize: theme.smallestFont.pointSize
        fontSizeMode: Text.Fit
        font.bold: true

        // battery power
        property var batteryList: Power.getBatteryPaths()

        // isOnBattery ? 
        property QtObject pmSource: PlasmaCore.DataSource {
            id: pmSource
            engine: "powermanagement"
            connectedSources: ["Battery", "AC Adapter"]
            interval: 1000
        }
        property bool isOnBattery: pmSource.data["AC Adapter"]["Plugged in"] == false

        // update time
        Timer {
            id: t_label
            interval: 1000
            repeat: true
            running: true
            triggeredOnStart: true
            onTriggered: {
                var power = Power.getPower(batteryList);
                if(isOnBattery) {
                    label1.text = power + " W⬇";
                    label1.color = "red";
                } else {
                    label1.text = power + " W⬆";
                    label1.color = "green";
                }
            }
        }
  
        // full representation (graph)
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            onClicked: plasmoid.expanded = !plasmoid.expanded
            hoverEnabled: true
        }

        // title
        PlasmaCore.ToolTipArea {
            anchors.fill: parent
            icon: parent.source
            mainText: "Energy monitor"
        }
    }

    // full representation
    Plasmoid.fullRepresentation: energyMonitor

}
