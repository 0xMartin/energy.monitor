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

function getBatteryPaths() {
    var list = [];

    for (var i = 0; i < 4; i++) {
        var req = new XMLHttpRequest();
        req.open("GET", "/sys/class/power_supply/BAT" + i + "/present", false);
        req.send(null);

        if (req.responseText != "") {
            var batURL = "/sys/class/power_supply/BAT" + i;

            req = new XMLHttpRequest();
            req.open("GET", batURL + "/power_now", false);
            req.send(null);

            var battery = {
                url: batURL,
                powerNowExists: (req.responseText != "")
            }
            list.push(battery);
        }

    }

    return list;
}


function getPower(batteryURLs) {
    if(batteryURLs === undefined) {
        return 0.0;
    }
    if (batteryURLs.length == 0) {
        return 0.0;
    }

    var totalPower = 0.0;

    for (var i = 0; i < batteryURLs.length; i++) {
        var battery = batteryURLs[i];
        if (battery.powerNowExists == true) {
            // Power file
            var req = new XMLHttpRequest();
            req.open("GET", battery.url + "/power_now", false);
            req.send(null);
            if(req.responseText != "") {
                var power = parseInt(req.responseText) / 1000000;
                totalPower += Math.round(power * 10) / 10;
            }
        } else {
            // V * I
            var curReq = new XMLHttpRequest();
            var voltReq = new XMLHttpRequest();
            curReq.open("GET", battery.url + "/current_now", false);
            voltReq.open("GET", battery.url + "/voltage_now", false);
            curReq.send(null);
            voltReq.send(null);
            if(curReq.responseText != "" && voltReq.responseText != "") {
                var power = (parseInt(curReq.responseText) * parseInt(voltReq.responseText)) / 1000000000000;
                totalPower += Math.round(power * 10) / 10;
            }
        }
    }

    return totalPower;
}
