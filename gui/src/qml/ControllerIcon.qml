import QtQuick

// Static controller silhouette for the Controllers page: gray body, dark gray outline.
// PS5 gets the DualSense shape (long curved grips), PS4 the DualShock 4 shape and everything else
// the compact Xbox shape, all traced from photos of real controllers.
Item {
    id: icon
    property string kind: "generic"
    implicitWidth: 220
    implicitHeight: 154

    onKindChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.scale(width / 220, height / 154);

            ctx.beginPath();
            if (icon.kind === "ps4") {
                // DualShock 4: short fat grips, traced in a 1740 x 1275 box
                ctx.save();
                ctx.scale(220 / 1740, 154 / 1275);
                ctx.moveTo(200, 70);
                ctx.bezierCurveTo(520, 25, 1220, 25, 1540, 70);
                ctx.bezierCurveTo(1650, 90, 1722, 160, 1732, 330);
                ctx.bezierCurveTo(1745, 600, 1735, 940, 1700, 1130);
                ctx.bezierCurveTo(1685, 1215, 1650, 1262, 1560, 1274);
                ctx.bezierCurveTo(1470, 1285, 1400, 1240, 1350, 1160);
                ctx.bezierCurveTo(1290, 1060, 1200, 900, 1050, 832);
                ctx.bezierCurveTo(960, 812, 780, 812, 690, 832);
                ctx.bezierCurveTo(540, 900, 450, 1060, 390, 1160);
                ctx.bezierCurveTo(340, 1240, 270, 1285, 180, 1274);
                ctx.bezierCurveTo(90, 1262, 55, 1215, 40, 1130);
                ctx.bezierCurveTo(5, 940, -5, 600, 8, 330);
                ctx.bezierCurveTo(18, 160, 90, 90, 200, 70);
                ctx.restore();
            } else if (icon.kind === "ps5") {
                ctx.moveTo(40, 8);
                ctx.bezierCurveTo(80, 2, 140, 2, 180, 8);
                ctx.bezierCurveTo(205, 12, 214, 34, 216, 60);
                ctx.bezierCurveTo(220, 100, 214, 130, 204, 148);
                ctx.bezierCurveTo(198, 156, 186, 154, 180, 146);
                ctx.bezierCurveTo(170, 128, 160, 108, 148, 98);
                ctx.bezierCurveTo(138, 94, 120, 93, 110, 93);
                ctx.bezierCurveTo(100, 93, 82, 94, 72, 98);
                ctx.bezierCurveTo(60, 108, 50, 128, 40, 146);
                ctx.bezierCurveTo(34, 154, 22, 156, 16, 148);
                ctx.bezierCurveTo(6, 130, 0, 100, 4, 60);
                ctx.bezierCurveTo(6, 34, 15, 12, 40, 8);
            } else {
                ctx.moveTo(60, 14);
                ctx.bezierCurveTo(80, 10, 140, 10, 160, 14);
                ctx.bezierCurveTo(186, 18, 204, 34, 212, 58);
                ctx.bezierCurveTo(220, 84, 220, 120, 206, 140);
                ctx.bezierCurveTo(196, 152, 176, 152, 166, 138);
                ctx.bezierCurveTo(156, 124, 146, 114, 128, 112);
                ctx.bezierCurveTo(116, 111, 104, 111, 92, 112);
                ctx.bezierCurveTo(74, 114, 64, 124, 54, 138);
                ctx.bezierCurveTo(44, 152, 24, 152, 14, 140);
                ctx.bezierCurveTo(0, 120, 0, 84, 8, 58);
                ctx.bezierCurveTo(16, 34, 34, 18, 60, 14);
            }
            ctx.closePath();
            ctx.fillStyle = "#8e8e96";
            ctx.fill();
            ctx.lineWidth = 3;
            ctx.lineJoin = "round";
            ctx.strokeStyle = "#3a3a40";
            ctx.stroke();
        }
    }
}
