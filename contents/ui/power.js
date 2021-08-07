      /*
       * Copyright 2021  Atul Gopinathan  <leoatul12@gmail.com>
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
       */


      //this function tries to find the exact path to battery file
      function getBatPath() {
          for (var i = 0; i < 4; i++) {
              var path = "/sys/class/power_supply/BAT" + i + "/voltage_now";
              var req = new XMLHttpRequest();
              req.open("GET", path, false);
              req.send(null)
              if (req.responseText != "") {
                  //console.log(path)
                  return "/sys/class/power_supply/BAT" + i;
              }
          }
          return ""
      }

      //Returns power usage in Watts, rounded off to 1 decimal.
      function getPower(fileUrl) {
          //if there is no BAT[i] file at all
          if (fileUrl == "") {
              return "0.0"
          }

          //in case the "power_now" file exists:
          if (main.powerNow == true) {
              var path = fileUrl + "/power_now"
              var req = new XMLHttpRequest();
              req.open("GET", path, false);
              req.send(null);

              var power = parseInt(req.responseText) / 1000000;
              return (Math.round(power * 10) / 10);
          }

          //if the power_now file doesn't exist, we collect voltage
          //and current and manually calculate power consumption
          var curUrl = fileUrl + "/current_now"
          var voltUrl = fileUrl + "/voltage_now"

          var curReq = new XMLHttpRequest();
          var voltReq = new XMLHttpRequest();

          curReq.open("GET", curUrl, false);
          voltReq.open("GET", voltUrl, false);

          curReq.send(null);
          voltReq.send(null);

          var power = (parseInt(curReq.responseText) * parseInt(voltReq.responseText)) / 1000000000000;
          //console.log(power.toFixed(1));
          return Math.round(power * 10) / 10; //toFixed() is apparently slow, so we use this way
      }