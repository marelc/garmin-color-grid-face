using Toybox.ActivityMonitor as ActivityMonitor;
using Toybox.Graphics as Gfx;
using Toybox.Math as Math;
using Toybox.SensorHistory as SensorHistory;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Gregorian;
using Toybox.WatchUi as Ui;

class ColorGridFaceView extends Ui.WatchFace {
    private const BLACK = 0x000000;
    private const WHITE = 0xffffff;
    private const INK = 0x101018;
    private const CYAN = 0x00bff3;
    private const PALE_BLUE = 0xcdeeff;
    private const PALE_PINK = 0xf4d4df;
    private const MINT = 0xa9e3c8;
    private const ROSE = 0xd95d88;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc) {
    }

    function onShow() {
    }

    function onUpdate(dc) {
        drawFace(dc);
    }

    function onHide() {
    }

    function onExitSleep() {
        Ui.requestUpdate();
    }

    function onEnterSleep() {
    }

    private function drawFace(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var size = (w < h) ? w : h;
        var cx = w / 2;
        var cy = h / 2;
        var radius = (size / 2) - 8;
        var left = cx - radius;
        var top = cy - radius;
        var diameter = radius * 2;
        var right = left + diameter;

        dc.setColor(BLACK, BLACK);
        dc.clear();

        dc.setColor(CYAN, BLACK);
        dc.setPenWidth(scale(size, 5));
        dc.drawCircle(cx, cy, radius);

        drawHeader(dc, left, top, diameter, size);
        drawTiles(dc, left, top, right, diameter, size);
        drawBattery(dc, left, top, diameter, size);
    }

    private function drawHeader(dc, left, top, diameter, size) {
        var now = Gregorian.info(Time.now(), Time.FORMAT_LONG);
        var hour = now.hour;
        if (!Sys.getDeviceSettings().is24Hour) {
            hour = hour % 12;
            if (hour == 0) {
                hour = 12;
            }
        }

        var dateText = now.day.toString() + " " + weekday(now.day_of_week);
        var timeText = hour.toString() + ":" + two(now.min);
        var headerBottom = top + scale(size, 145);
        var cx = left + (diameter / 2);

        dc.setColor(WHITE, BLACK);
        dc.drawText(cx, top + scale(size, 36), Gfx.FONT_SMALL, dateText, Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, top + scale(size, 58), Gfx.FONT_NUMBER_MEDIUM, timeText, Gfx.TEXT_JUSTIFY_CENTER);

        dc.setColor(CYAN, BLACK);
        dc.setPenWidth(scale(size, 4));
        dc.drawLine(left + scale(size, 16), headerBottom, left + diameter - scale(size, 16), headerBottom);

        if (Sys.getDeviceSettings().phoneConnected) {
            drawBluetooth(dc, left + diameter - scale(size, 52), headerBottom - scale(size, 45), scale(size, 20));
        }
    }

    private function drawTiles(dc, left, top, right, diameter, size) {
        var y1 = top + scale(size, 148);
        var y2 = top + scale(size, 206);
        var y3 = top + scale(size, 264);
        var centerX = left + (diameter / 2);
        var pad = scale(size, 10);

        var info = ActivityMonitor.getInfo();
        var heartRate = getHeartRate();
        var steps = (info != null && info.steps != null) ? info.steps : 2995;
        var calories = (info != null && info.calories != null) ? info.calories : 1370;
        var distance = (info != null && info.distance != null) ? info.distance : 2430;
        var distanceKm = distance / 1000.0;

        fillBand(dc, left, right, y1, y2, PALE_BLUE, PALE_PINK);
        fillBand(dc, left, right, y2, y3, MINT, ROSE);

        dc.setColor(CYAN, CYAN);
        dc.fillRectangle(centerX - scale(size, 2), y1, scale(size, 4), y3 - y1);
        dc.fillRectangle(left + pad, y2 - scale(size, 2), diameter - (pad * 2), scale(size, 4));

        dc.setColor(INK, Gfx.COLOR_TRANSPARENT);
        drawHeart(dc, left + scale(size, 38), y1 + scale(size, 26), scale(size, 15));
        drawSteps(dc, right - scale(size, 35), y1 + scale(size, 28), scale(size, 13));
        drawFlame(dc, left + scale(size, 35), y2 + scale(size, 28), scale(size, 14));
        drawPin(dc, right - scale(size, 35), y2 + scale(size, 27), scale(size, 14));

        dc.drawText(centerX - scale(size, 35), y1 + scale(size, 11), Gfx.FONT_LARGE, heartRate, Gfx.TEXT_JUSTIFY_RIGHT);
        dc.drawText(centerX + scale(size, 26), y1 + scale(size, 11), Gfx.FONT_LARGE, steps.toString(), Gfx.TEXT_JUSTIFY_LEFT);
        dc.drawText(centerX - scale(size, 28), y2 + scale(size, 11), Gfx.FONT_LARGE, calories.toString(), Gfx.TEXT_JUSTIFY_RIGHT);

        dc.setColor(WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX + scale(size, 29), y2 + scale(size, 12), Gfx.FONT_LARGE, formatDistance(distanceKm), Gfx.TEXT_JUSTIFY_LEFT);
    }

    private function drawBattery(dc, left, top, diameter, size) {
        var stats = Sys.getSystemStats();
        var percent = stats.battery;
        var y = top + scale(size, 286);
        var cx = left + (diameter / 2);
        var days = Math.ceil(percent * 14.0 / 100.0).toNumber();

        drawBatteryIcon(dc, cx - scale(size, 70), y + scale(size, 20), scale(size, 56), scale(size, 24), percent);

        dc.setColor(WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(cx + scale(size, 34), y + scale(size, 11), Gfx.FONT_SMALL, days.toString() + " d", Gfx.TEXT_JUSTIFY_CENTER);
    }

    private function fillBand(dc, left, right, top, bottom, leftColor, rightColor) {
        var mid = (left + right) / 2;
        dc.setColor(leftColor, leftColor);
        dc.fillRectangle(left + 10, top, mid - left - 10, bottom - top);
        dc.setColor(rightColor, rightColor);
        dc.fillRectangle(mid, top, right - mid - 10, bottom - top);
    }

    private function getHeartRate() {
        var samples = SensorHistory.getHeartRateHistory({ :period => 1, :order => SensorHistory.ORDER_NEWEST_FIRST });
        if (samples != null) {
            var sample = samples.next();
            if (sample != null && sample.data != null) {
                return sample.data.toString();
            }
        }
        return "53";
    }

    private function drawHeart(dc, x, y, r) {
        dc.fillCircle(x - (r / 2), y - (r / 3), r / 2);
        dc.fillCircle(x + (r / 2), y - (r / 3), r / 2);
        dc.fillPolygon([[x - r, y - (r / 4)], [x + r, y - (r / 4)], [x, y + r]]);
    }

    private function drawSteps(dc, x, y, r) {
        dc.fillCircle(x - r, y, r / 2);
        dc.fillCircle(x + r, y, r / 2);
        dc.fillCircle(x - (r / 2), y + r, r / 3);
        dc.fillCircle(x + (r / 2), y + r, r / 3);
    }

    private function drawFlame(dc, x, y, r) {
        dc.fillCircle(x, y + (r / 4), r / 2);
        dc.fillPolygon([[x, y - r], [x + r, y + r], [x - r, y + r]]);
        dc.setColor(MINT, Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(x, y + (r / 3), r / 4);
        dc.setColor(INK, Gfx.COLOR_TRANSPARENT);
    }

    private function drawPin(dc, x, y, r) {
        dc.fillCircle(x, y - (r / 4), r / 2);
        dc.fillPolygon([[x - (r / 2), y], [x + (r / 2), y], [x, y + r]]);
    }

    private function drawBluetooth(dc, x, y, s) {
        dc.setColor(CYAN, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(x, y, x, y + s);
        dc.drawLine(x, y, x + (s / 2), y + (s / 4));
        dc.drawLine(x + (s / 2), y + (s / 4), x - (s / 3), y + (s / 2));
        dc.drawLine(x - (s / 3), y + (s / 2), x + (s / 2), y + ((s * 3) / 4));
        dc.drawLine(x + (s / 2), y + ((s * 3) / 4), x, y + s);
    }

    private function drawBatteryIcon(dc, x, y, w, h, percent) {
        dc.setColor(WHITE, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawRectangle(x, y, w, h);
        dc.fillRectangle(x + w, y + (h / 3), 5, h / 3);
        dc.fillRectangle(x + 4, y + 4, ((w - 8) * percent) / 100, h - 8);
    }

    private function two(n) {
        if (n < 10) {
            return "0" + n.toString();
        }
        return n.toString();
    }

    private function weekday(day) {
        if (day == Gregorian.DAY_SUNDAY) {
            return "Sun";
        } else if (day == Gregorian.DAY_MONDAY) {
            return "Mon";
        } else if (day == Gregorian.DAY_TUESDAY) {
            return "Tue";
        } else if (day == Gregorian.DAY_WEDNESDAY) {
            return "Wed";
        } else if (day == Gregorian.DAY_THURSDAY) {
            return "Thu";
        } else if (day == Gregorian.DAY_FRIDAY) {
            return "Fri";
        } else if (day == Gregorian.DAY_SATURDAY) {
            return "Sat";
        }
        return "Mon";
    }

    private function formatDistance(km) {
        var whole = km.toNumber();
        var decimals = ((km - whole) * 100).toNumber();
        if (decimals < 10) {
            return whole.toString() + ".0" + decimals.toString();
        }
        return whole.toString() + "." + decimals.toString();
    }

    private function scale(size, value) {
        return (value * size) / 360;
    }
}
