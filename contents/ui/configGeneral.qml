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
 
import QtQuick 2.6
import QtQuick.Controls 1.3
import QtQuick.Layouts 1.1

Item {
    property alias cfg_timeRange: timeRange.value
    property alias cfg_samplesPerMinute: samplesPerMinute.value

    ColumnLayout {
        RowLayout {
            Label {
                id: timeRangeLabel
                text: i18n("Time range:")
            }
            SpinBox {
                id: timeRange
                stepSize: 10
                minimumValue: 10
                maximumValue: 10 * 60
                suffix: i18nc("Minutes", "min")
            }
        }
        RowLayout {
            Label {
                id: samplesPerMinuteLabel
                text: i18n("Samples per second:")
            }
            SpinBox {
                id: samplesPerMinute
                stepSize: 1
                minimumValue: 1
                maximumValue: 4
            }
        }
    }
}
