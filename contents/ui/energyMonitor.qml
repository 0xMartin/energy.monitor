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
    id: energyMonitor
    width: 400 * units.devicePixelRatio
    height: 300 * units.devicePixelRatio
    Plasmoid.backgroundHints: PlasmaCore.Types.ShadowBackground | PlasmaCore.Types.ConfigurableBackground


    // battery perentage
    property QtObject pmSource: PlasmaCore.DataSource {
        id: pmSource
        engine: "powermanagement"
        connectedSources: ["Battery", "AC Adapter"]
        interval: 1000
    }
    property bool isOnBattery: pmSource.data["AC Adapter"]["Plugged in"] == false
    property int batteryPercent: pmSource.data["Battery"]["Percent"]


    // total power
    property var batteryList: Power.getBatteryPaths()


    // main variables
    property double power_avg: Power.getPower(batteryList)
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


    //config refresh (in graph.js) + color of graph (green = chargeding, red = discharging)
    property bool isOnBatteryLast: true
    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            //config apply
            if(Graph.refreshConfig()) {
                // changed = recompute main timer interval
                energyMonitor.mainTimer.interval = 60000 / Graph.samples_per_minute / 10;
            }
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
    property alias mainTimer: t_graph
    Timer {
        id: t_graph
        interval: 60000 / Graph.samples_per_minute / 10
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            //current power
            var power = Power.getPower(batteryList);

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