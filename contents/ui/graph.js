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

//<-------config-------------------------------------------------------------------------------->
var grid_color = "#666666";
var txt_color = "#cccccc";
var graph_consumption_color = "#fd4848";
var graph_voltage_color = "#ff6800";
var minutes_range = 60;
var samples_per_minute = 2;
//<--------------------------------------------------------------------------------------------->

var capacity_levels = [];
var consumption_levels = [];



function setCapacity(data) {
    capacity_levels = data;
}

function setConsumption(data) {
    consumption_levels = data;
}

function pushCapacity(value) {
    if (Number.isNaN(value) || value < 0.0) value = capacity_levels[0];
    capacity_levels.unshift(parseFloat(value));
    while (capacity_levels.length - 1 > 10 * 60 * samples_per_minute) capacity_levels.pop();
}

function pushConsumption(value) {
    if (Number.isNaN(value) || value < 0.0) value = consumption_levels[0];
    consumption_levels.unshift(parseFloat(value));
    while (consumption_levels.length - 1 > 10 * 60 * samples_per_minute) consumption_levels.pop();
}

function paintGraph(ctx, width, height) {
    ctx.clearRect(0, 0, width, height);

    //<-------setup------------------------------------------------------------------------------------->
    const offset_x = ctx.measureText("100%").width + 20; //left side X axis offset

    const dW = (width - offset_x * 2) / 8;
    const dH = height * 0.9 / 11;

    //max power
    var max_power = Math.max(arrayMax(consumption_levels), 3) * 1.35;


    //<-------draw graph-------------------------------------------------------------------------------->
    var buffer = [];
    var i = 0;

    //consumption
    if (consumption_levels.length != 0) {
        //draw basic graph
        for (const consumption of consumption_levels) {
            buffer.push({
                x: offset_x + (1.0 - i / (minutes_range * samples_per_minute)) * 8 * dW,
                y: (1.0 - consumption / max_power) * 10 * dH + height * 0.1
            });
            ++i;
            if (i > minutes_range * samples_per_minute) break;
        }

        ctx.strokeStyle = graph_consumption_color;
        bzCurve(ctx, buffer, 0.3, 1);


        //fill gradient
        ctx.lineTo(offset_x + (1.0 - (i - 1) / (minutes_range * samples_per_minute)) * 8 * dW, height * 0.9);
        ctx.lineTo(offset_x + 8 * dW, height * 0.9);
        ctx.closePath();

        var grd = ctx.createLinearGradient(0, 0, 0, height * 0.9);
        grd.addColorStop(0, graph_consumption_color);
        grd.addColorStop(1, "transparent");
        ctx.fillStyle = grd;
        ctx.fill();
    }

    //capacity level
    if (capacity_levels.length != 0) {
        buffer = [];
        i = 0;

        for (const capacity of capacity_levels) {
            buffer.push({
                x: offset_x + (1.0 - i / (minutes_range * samples_per_minute)) * 8 * dW,
                y: (10 - capacity / 10) * dH + height * 0.1
            });
            ++i;
            if (i > minutes_range * samples_per_minute) break;
        }

        ctx.strokeStyle = graph_voltage_color;
        ctx.lineWidth = 1.0;
        bzCurve(ctx, buffer, 0.3, 1);
        ctx.stroke();
    }


    //<-------draw grid--------------------------------------------------------------------------------->
    ctx.lineWidth = 0.3;
    ctx.strokeStyle = grid_color;

    //voltage + consumption
    for (var i = 0; i <= 10; i += 2) {
        ctx.beginPath();
        ctx.moveTo(offset_x - 10, i * dH + height * 0.1);
        ctx.lineTo(offset_x + dW * 8 + 10, i * dH + height * 0.1);
        ctx.stroke();
        ctx.fillStyle = graph_voltage_color;
        ctx.fillText(((10 - i) * 10) + "%", 7, i * dH + height * 0.1);
        ctx.fillStyle = graph_consumption_color;
        var power = (10 - i) / 10.0 * max_power;
        ctx.fillText(power.toFixed(1) + "W", offset_x + dW * 8 + 15, i * dH + height * 0.1);
    }

    //time
    ctx.fillStyle = txt_color;
    var today = new Date();
    for (var i = 8; i >= 0; --i) {
        var time = paddy(today.getHours(), 2) + ":" + paddy(today.getMinutes(), 2);
        today = new Date(today.valueOf() - minutes_range / 8 * 60000);
        ctx.beginPath();
        ctx.moveTo(offset_x + i * dW, height * 0.95);
        ctx.lineTo(offset_x + i * dW, height * 0.05);
        ctx.stroke();
        if (i % 2 == 0) {
            ctx.fillText(time, offset_x + i * dW - ctx.measureText(time).width / 2, height - 10);
        }
    }

}

function arrayMax(arr) {
    if (arr.length == 0) return 0;
    return arr.reduce(function(p, v) {
        return (p > v ? p : v);
    });
}

function paddy(num, padlen, padchar) {
    var pad_char = typeof padchar !== 'undefined' ? padchar : '0';
    var pad = new Array(1 + padlen).join(pad_char);
    return (pad + num).slice(-pad.length);
}

function gradient(a, b) {
    return (b.y - a.y) / (b.x - a.x);
}

function bzCurve(ctx, points, f, t) {
    if (typeof(f) == 'undefined') f = 0.3;
    if (typeof(t) == 'undefined') t = 0.6;

    ctx.beginPath();
    ctx.moveTo(points[0].x, points[0].y);

    var m = 0;
    var dx1 = 0;
    var dy1 = 0;

    var preP = points[0];
    var nexP, dx2, dy2;

    for (var i = 1; i < points.length; i++) {
        var curP = points[i];
        nexP = points[i + 1];

        if (nexP) {
            m = gradient(preP, nexP);
            dx2 = (nexP.x - curP.x) * -f;
            dy2 = dx2 * m * t;
        } else {
            dx2 = 0;
            dy2 = 0;
        }

        ctx.bezierCurveTo(
            preP.x - dx1, preP.y - dy1,
            curP.x + dx2, curP.y + dy2,
            curP.x, curP.y
        );

        dx1 = dx2;
        dy1 = dy2;
        preP = curP;
    }

    ctx.stroke();
}