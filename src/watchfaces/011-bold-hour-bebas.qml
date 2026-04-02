/*
 * Copyright (C) 2026 - Timo Könnecke <github.com/moWerk>
 *               2023 - Timo Könnecke <github.com/eLtMosen>
 *               2022 - Darrel Griët <dgriet@gmail.com>
 *               2022 - Ed Beroset <github.com/beroset>
 *               2016 - Sylvia van Os <iamsylvie@openmailbox.org>
 *               2015 - Florent Revest <revestflo@gmail.com>
 *               2012 - Vasiliy Sorokin <sorokin.vasiliy@gmail.com>
 *                      Aleksey Mikhailichenko <a.v.mich@gmail.com>
 *                      Arto Jalkanen <ajalkane@gmail.com>
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation, either version 2.1 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.15
import QtQuick.Shapes 1.15
import QtGraphicalEffects 1.15
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0
import Nemo.Mce 1.0

Item {
    anchors.fill: parent
    
    Item {
        id: root
        
        anchors.centerIn: parent
        height: parent.width > parent.height ? parent.height : parent.width
        width: height
        
        Item {
            id: scaleContent
            
            anchors.centerIn: parent
            width: parent.width * (nightstandMode.active ? .8 : 1)
            height: width
            
            Canvas {
                id: minuteArc
                
                property int minute: 0
                property real centerX: parent.width / 2
                property real centerY: parent.height / 2
                
                anchors.fill: parent
                renderStrategy: Canvas.Cooperative
                visible: !displayAmbient && !nightstandMode.active
                onPaint: {
                    var ctx = getContext("2d")
                    var rot = (minute - 15) * 6
                    ctx.reset()
                    ctx.lineWidth = parent.width * .0031
                    // conical gradient arc — kept as Canvas since PathAngleArc has no conical gradient support
                    var gradient = ctx.createConicalGradient(centerX, centerY, 90 * .01745)
                    gradient.addColorStop(1 - (minute / 60), Qt.rgba(1, 1, 1, .4))
                    gradient.addColorStop(1 - (minute / 60 / 6), Qt.rgba(1, 1, 1, 0))
                    var gradient2 = ctx.createConicalGradient(centerX, centerY, 90 * .01745)
                    gradient2.addColorStop(1 - (minute / 60), Qt.rgba(1, 1, 1, .5))
                    gradient2.addColorStop(1 - (minute / 60 / 6), Qt.rgba(1, 1, 1, .01))
                    ctx.fillStyle = gradient
                    ctx.strokeStyle = gradient2
                    ctx.beginPath()
                    ctx.arc(centerX, centerY, width / 2.75, -90 * .017453, rot * .017453, false)
                    ctx.lineTo(centerX, centerY)
                    ctx.fill()
                    ctx.stroke()
                }
            }
            
            Text {
                id: hourDisplay
                
                renderType: Text.NativeRendering
                anchors.centerIn: parent
                font {
                    pixelSize: parent.height * .87
                    family: "BebasKai"
                    styleName: "Bold"
                }
                color: Qt.rgba(1, 1, 1, .9)
                opacity: .9
                style: Text.Outline
                styleColor: Qt.rgba(0, 0, 0, .2)
                horizontalAlignment: Text.AlignHCenter
                text: use12H.value ? wallClock.time.toLocaleString(Qt.locale(), "hh ap").slice(0, 2) :
                wallClock.time.toLocaleString(Qt.locale(), "HH")
            }
            
            // Minute hand tip dot — Rectangle replaces Canvas circle
            Rectangle {
                id: minuteCircle
                
                width: parent.width / 8.6 * 2
                height: width
                radius: width / 2
                color: Qt.rgba(.184, .184, .184, .95)
            }
            
            Text {
                id: minuteDisplay
                
                font {
                    pixelSize: parent.height / 5.24
                    family: "BebasKai"
                    styleName: "Condensed"
                }
                color: "white"
            }
        }
        
        Item {
            id: nightstandMode
            
            readonly property bool active: nightstand
            property int batteryPercentChanged: batteryChargePercentage.percent
            
            anchors.fill: parent
            visible: nightstandMode.active
            layer {
                enabled: true
                samples: 4
            }
            
            Shape {
                id: chargeArc
                
                property real angle: batteryChargePercentage.percent * 360 / 100
                property real arcStrokeWidth: .04
                property real scalefactor: .49 - (arcStrokeWidth / 2)
                property int chargecolor: Math.floor(batteryChargePercentage.percent / 33.35)
                readonly property var colorArray: ["red", "yellow", Qt.rgba(.318, 1, .051, .9)]
                
                anchors.fill: parent
                
                ShapePath {
                    fillColor: "transparent"
                    strokeColor: chargeArc.colorArray[chargeArc.chargecolor]
                    strokeWidth: parent.height * chargeArc.arcStrokeWidth
                    capStyle: ShapePath.FlatCap
                    joinStyle: ShapePath.MiterJoin
                    startX: chargeArc.width / 2
                    startY: chargeArc.height * (.5 - chargeArc.scalefactor)
                    
                    PathAngleArc {
                        centerX: chargeArc.width / 2
                        centerY: chargeArc.height / 2
                        radiusX: chargeArc.scalefactor * chargeArc.width
                        radiusY: chargeArc.scalefactor * chargeArc.height
                        startAngle: -90
                        sweepAngle: chargeArc.angle
                        moveToStart: false
                    }
                }
            }
        }
    }
    
    MceBatteryLevel {
        id: batteryChargePercentage
    }
    
    Connections {
        target: wallClock
        function onTimeChanged() {
            var min = wallClock.time.getMinutes()
            var rotM = (min - 15) / 60
            var cx = scaleContent.width / 2
            var cy = scaleContent.height / 2
            var dotR = scaleContent.width / 8.6
            
            minuteArc.minute = min
            minuteArc.requestPaint()
            
            minuteCircle.x = cx + Math.cos(rotM * 2 * Math.PI) * scaleContent.width / 2.75 - dotR
            minuteCircle.y = cy + Math.sin(rotM * 2 * Math.PI) * scaleContent.height / 2.75 - dotR
            
            minuteDisplay.x = cx - minuteDisplay.width / 2 + Math.cos(rotM * 2 * Math.PI) * scaleContent.width * .364
            minuteDisplay.y = cy - minuteDisplay.height / 2 + Math.sin(rotM * 2 * Math.PI) * scaleContent.width * .364
            minuteDisplay.text = wallClock.time.toLocaleString(Qt.locale(), "mm")
        }
    }
    
    Component.onCompleted: {
        var min = wallClock.time.getMinutes()
        var rotM = (min - 15) / 60
        var cx = scaleContent.width / 2
        var cy = scaleContent.height / 2
        var dotR = scaleContent.width / 8.6
        
        minuteArc.minute = min
        minuteArc.requestPaint()
        
        minuteCircle.x = cx + Math.cos(rotM * 2 * Math.PI) * scaleContent.width / 2.75 - dotR
        minuteCircle.y = cy + Math.sin(rotM * 2 * Math.PI) * scaleContent.height / 2.75 - dotR
        
        minuteDisplay.x = cx - minuteDisplay.width / 2 + Math.cos(rotM * 2 * Math.PI) * scaleContent.width * .364
        minuteDisplay.y = cy - minuteDisplay.height / 2 + Math.sin(rotM * 2 * Math.PI) * scaleContent.width * .364
        minuteDisplay.text = wallClock.time.toLocaleString(Qt.locale(), "mm")
        
        burnInProtectionManager.widthOffset = Qt.binding(function() { return width * .3 })
        burnInProtectionManager.heightOffset = Qt.binding(function() { return height * .3 })
    }
}
