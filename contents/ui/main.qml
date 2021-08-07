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

import QtQuick 2.0
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

import "graph.js" as Graph
import "power.js" as Power


Item {
    id: main

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

        onSourceAdded: {
            disconnectSource(source)
            connectSource(source)
        }

        onSourceRemoved: {
            disconnectSource(source)
        }
    }
    //<---------------------------------------------------------------------------------------------------->


    //power consumption
    //<---------------------------------------------------------------------------------------------------->
    property string batteryPath: Power.getBatteryPath()
    property double power: Power.getPower(batteryPath)
    //<---------------------------------------------------------------------------------------------------->

    //app 
    //<---------------------------------------------------------------------------------------------------->
    Plasmoid.preferredRepresentation: Plasmoid.fullRepresentation
    Plasmoid.fullRepresentation: Item {
        id: energyMonitor
        width: units.gridUnit * 20
        height: units.gridUnit * 10
        Plasmoid.backgroundHints: PlasmaCore.Types.ShadowBackground | PlasmaCore.Types.ConfigurableBackground

        property bool isOnBattery: pmSource.data[acAdapterKey][acPluggedKey] == false
        property bool isOnBatteryLast: true
        property int batteryPercent: pmSource.data[batteryKey][batteryPercentKey]

        property double power_avg: Power.getPower(main.batteryPath) * 10
        property double capacity_avg: batteryPercent * 10

        property alias canvas: graphCanvas

        //main canvas
        Canvas {
            id: graphCanvas
            anchors.fill: parent

            property alias timer: cTimer

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

            //refresh graph data
            Timer {
                id: cTimer
                interval: 60000 / plasmoid.configuration.samplesPerMinute
                repeat: true
                running: true
                triggeredOnStart: true
                onTriggered: {
                    //Graph.pushCapacity(Math.random() * 100);
                    //Graph.pushConsumption(10);
                    Graph.pushCapacity(capacity_avg/10);
                    Graph.pushConsumption(power_avg/10);
                    energyMonitor.power_avg = 0.0;
                    energyMonitor.capacity_avg = 0.0;
                    graphCanvas.requestPaint();
                }
            }
        }

        //time for color of consumption graph (green = chargeding, red = discharging)
        Timer {
            interval: 1000
            repeat: true
            running: true
            triggeredOnStart: true
            onTriggered: {
                if(energyMonitor.isOnBatteryLast != energyMonitor.isOnBattery) {
                    if(energyMonitor.isOnBattery) {
                        Graph.graph_consumption_color = "#fd4848";        
                    } else {
                        Graph.graph_consumption_color = "#509500";
                    }
                    energyMonitor.isOnBatteryLast = energyMonitor.isOnBattery;
                    energyMonitor.canvas.requestPaint();
                }
            }
        }

        //main timer
        Timer {
            id: mainTimer
            interval: 60000 / plasmoid.configuration.samplesPerMinute / 10
            repeat: true
            running: true
            triggeredOnStart: true
            onTriggered: {
                main.power = Power.getPower(main.batteryPath);

                if(Number.isInteger(main.power)) {
                    graphCanvas.infoTxt = main.power + ".0 W " + batteryPercent + " %"; 
                } else {
                    graphCanvas.infoTxt = main.power + " W " + batteryPercent + " %"; 
                }

                energyMonitor.power_avg += main.power;
                energyMonitor.capacity_avg += energyMonitor.batteryPercent;

                //apply config 
                if(Graph.minutes_range != plasmoid.configuration.timeRange) {
                    Graph.minutes_range = plasmoid.configuration.timeRange;
                    energyMonitor.canvas.requestPaint();
                }
                if(Graph.samples_per_minute != plasmoid.configuration.samplesPerMinute) {
                    Graph.samples_per_minute = plasmoid.configuration.samplesPerMinute;
                    mainTimer.interval = 60000 / plasmoid.configuration.samplesPerMinute / 10;
                    energyMonitor.graphCanvas.timer.interval = 60000 / plasmoid.configuration.samplesPerMinute;
                }
            }
        }
    }
    //<---------------------------------------------------------------------------------------------------->

}
