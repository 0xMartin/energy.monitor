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

import "../tools/graph.js" as Graph
import "../tools/power.js" as Power


Item {
    id: main
    anchors.fill: parent

    property var batteryList: Power.getBatteryPaths()

    //battery info
    //<---------------------------------------------------------------------------------------------------->
    readonly property string batteryKey: "Battery"
    readonly property string batteryStateKey: "State"
    readonly property string batteryPercentKey: "Percent"
    readonly property string acAdapterKey: "AC Adapter"
    readonly property string acPluggedKey: "Plugged in"

    property QtObject pmSource: PlasmaCore.DataSource {
        id: pmSource
        engine: "powermanagement"
        connectedSources: [batteryKey, acAdapterKey]
        interval: 1000
    }
    //<---------------------------------------------------------------------------------------------------->

    //app 
    //<---------------------------------------------------------------------------------------------------->
    Plasmoid.compactRepresentation: Item {
        anchors.fill: parent

        Layout.preferredWidth: 120 * units.devicePixelRatio
        Layout.preferredHeight: 40 * units.devicePixelRatio

        // label with Watts
        Label {
            id: label1

            anchors {
                fill: parent
                margins: Math.round(parent.width * 0.01)
            }

            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCente

            font.pixelSize: 1000;
            minimumPointSize: theme.smallestFont.pointSize
            fontSizeMode: Text.Fit
            font.bold: plasmoid.configuration.makeFontBold

            // update time
            Timer {
                id: t1
                interval: 1000
                repeat: true
                running: true
                triggeredOnStart: true
                onTriggered: {
                    var power = Power.getPower(main.batteryList);
                    label1.text = power + " W";
                }
            }
        }
    }

    Plasmoid.fullRepresentation: Item {
        id: energyMonitor
        Layout.minimumWidth: units.gridUnit * 25
        Layout.minimumHeight: units.gridUnit * 13
        Plasmoid.backgroundHints: PlasmaCore.Types.ShadowBackground | PlasmaCore.Types.ConfigurableBackground


        property bool isOnBattery: pmSource.data[acAdapterKey][acPluggedKey] == false
        property int batteryPercent: pmSource.data[batteryKey][batteryPercentKey]


        property double power_avg: Power.getPower(main.batteryList)
        property double capacity_avg: batteryPercent
        property int samples: 1


        //main canvas
        property alias canvas: graphCanvas
        Canvas {
            id: graphCanvas
            anchors.fill: parent

            onPaint: {
                var ctx = getContext("2d");
                Graph.paintGraph(ctx, graphCanvas.width, graphCanvas.height);
            }

            property alias infoTxt: info.text
            Text {
                id: info
                x: 50 
                y: 10
                text: "0 V"
                font.family: "Helvetica"
                font.pointSize: 12
                color: Qt.rgba(1,1,1,0.5)
            }
        }

        //color of consumption graph (green = chargeding, red = discharging) + config apply
        property bool isOnBatteryLast: true
        Timer {
            interval: 1000
            repeat: true
            running: true
            triggeredOnStart: true
            onTriggered: {
                //config apply
                if(Graph.refreshConfig()) {
                    energyMonitor.mainTimer.interval = 60000 / Graph.samples_per_minute / 10;
                }

                energyMonitor.canvas.requestPaint();

                //color
                if(energyMonitor.isOnBatteryLast != energyMonitor.isOnBattery) {
                    if(energyMonitor.isOnBattery) {
                        Graph.graph_consumption_color = "#fd3838";        
                    } else {
                        Graph.graph_consumption_color = "#509500";
                    }
                    energyMonitor.isOnBatteryLast = energyMonitor.isOnBattery;
                }
            }
        }

        //timer for sampling and graph repainting
        property alias mainTimer: t1
        Timer {
            id: t1
            interval: 60000 / Graph.samples_per_minute / 10
            repeat: true
            running: true
            triggeredOnStart: true
            onTriggered: {
                //current power
                var power = Power.getPower(main.batteryList);

                //avg
                energyMonitor.power_avg += power;
                energyMonitor.capacity_avg += energyMonitor.batteryPercent;
                energyMonitor.samples++;

                //display current values
                if(Number.isInteger(power)) {
                    graphCanvas.infoTxt = power + ".0 W " + batteryPercent + " %"; 
                } else {
                    graphCanvas.infoTxt = power + " W " + batteryPercent + " %"; 
                }

                //after 10 micro samples push avg data
                if(energyMonitor.samples >= 10) {
                    //push data
                    Graph.pushCapacity(capacity_avg/samples);
                    Graph.pushConsumption(power_avg/samples);

                    //reset avg values
                    energyMonitor.power_avg = 0.0;
                    energyMonitor.capacity_avg = 0.0;
                    energyMonitor.samples = 0;

                    //paint graph
                    energyMonitor.canvas.requestPaint();
                }
            }
        }
        
    }   
}
