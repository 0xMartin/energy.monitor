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


function getBatteryPath() {
    for (var i = 0; i < 4; i++) {
        var path = "/sys/class/power_supply/BAT" + i + "/voltage_now";
        var req = new XMLHttpRequest();
        req.open("GET", path, false);
        req.send(null);
        if (req.responseText != "") {
            return "/sys/class/power_supply/BAT" + i;
        }
    }
    return "";
}

function getPower(fileUrl) {
    if (fileUrl == "") return 0.0;

    var curReq = new XMLHttpRequest();
    var voltReq = new XMLHttpRequest();

    curReq.open("GET", fileUrl + "/current_now", false);
    voltReq.open("GET", fileUrl + "/voltage_now", false);

    curReq.send(null);
    voltReq.send(null);

    var power = (parseInt(curReq.responseText) * parseInt(voltReq.responseText)) / 1000000000000;

    if (Number.isNaN(power)) return 0.0

    return Math.round(power * 10) / 10;

}