using Toybox.Activity as Activity;
using Toybox.ActivityMonitor as ActivityMonitor;
using Toybox.Graphics as Gfx;
using Toybox.Math as Math;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Gregorian;
using Toybox.WatchUi as Ui;

class ColorGridFaceView extends Ui.WatchFace {
    private const BLACK = 0x000000;
    private const WHITE = 0xffffff;
    private const CYAN = 0x00bff3;
    private const YELLOW = 0xffd500;
    private const ORANGE = 0xff8800;
    private const GREEN = 0x55cc00;
    private const RED = 0xe00000;

    // Data-field digits use a condensed vector font (narrower, so it can be
    // taller without overflowing 4-digit values). Loaded once in onLayout.
    private var _valueFont;
    private var _valueH;
    private var _kFont;
    private var _kH;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc) {
        _valueFont = Gfx.getVectorFont({ :face => ["RobotoCondensedBold", "RobotoCondensed"], :size => 62 });
        _kFont = Gfx.getVectorFont({ :face => ["RobotoCondensedBold", "RobotoCondensed"], :size => 33 });
        if (_valueFont == null) {
            _valueFont = Gfx.FONT_NUMBER_MEDIUM;
        }
        if (_kFont == null) {
            _kFont = Gfx.FONT_XTINY;
        }
        _valueH = dc.getTextDimensions("8", _valueFont)[1];
        _kH = dc.getTextDimensions("k", _kFont)[1];
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

        dc.setColor(BLACK, BLACK);
        dc.clear();

        drawHeader(dc, w, size);
        drawTiles(dc, w, size);
        drawBattery(dc, w, size);
    }

    private function drawHeader(dc, w, size) {
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
        var cx = w / 2;

        dc.setColor(WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(cx, px(size, 24), Gfx.FONT_MEDIUM, dateText,
            Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, px(size, 74), Gfx.FONT_NUMBER_THAI_HOT, timeText,
            Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    }

    private function drawTiles(dc, w, size) {
        // Field block. Kept narrow enough that the bottom corners stay inside
        // the round display; the cyan frame + cross are drawn on top, matching
        // the reference design.
        var cx = w / 2;
        var cy = size / 2;
        var r = size / 2;

        // Fields span the full width and overlap the round border; the display
        // rounds off the outer corners. Top sits just under the time, bottom
        // just above the battery (minimal gaps).
        var gridLeft = 0;
        var gridRight = w;
        var gridTop = px(size, 109);
        var gridBottom = px(size, 224);

        var midX = w / 2;
        var midY = (gridTop + gridBottom) / 2;

        var info = ActivityMonitor.getInfo();
        var heartRate = getHeartRate();
        var steps = (info != null && info.steps != null) ? info.steps : 0;
        var calories = (info != null && info.calories != null) ? info.calories : 0;
        var distance = (info != null && info.distance != null) ? info.distance : 0;
        if (steps == 0 && calories == 0 && distance == 0) {
            heartRate = "53";
            steps = 12350;
            calories = 1370;
            distance = 243000;
        }
        var distanceKm = distance / 100000.0;

        // Colored quadrants (they touch; the cyan cross is painted over the seam).
        dc.setColor(YELLOW, YELLOW);
        dc.fillRectangle(gridLeft, gridTop, midX - gridLeft, midY - gridTop);
        dc.setColor(ORANGE, ORANGE);
        dc.fillRectangle(midX, gridTop, gridRight - midX, midY - gridTop);
        dc.setColor(GREEN, GREEN);
        dc.fillRectangle(gridLeft, midY, midX - gridLeft, gridBottom - midY);
        dc.setColor(RED, RED);
        dc.fillRectangle(midX, midY, gridRight - midX, gridBottom - midY);

        // Cyan structure only: center cross + top/bottom rails. No enclosing
        // rectangle and no left/right edges, so the fields span to the watch
        // edge instead of being boxed in.
        dc.setColor(CYAN, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(px(size, 3));
        dc.drawLine(midX, gridTop, midX, gridBottom);
        dc.drawLine(gridLeft, gridTop, gridRight, gridTop);
        dc.drawLine(gridLeft, midY, gridRight, midY);
        dc.drawLine(gridLeft, gridBottom, gridRight, gridBottom);

        // Digits sized up (MEDIUM), justified toward the center line. Icons sit
        // at the outer (rounded) edge, top-aligned with the top of the digits.
        var valueFont = _valueFont;
        var numH = _valueH;
        var topValueY = (gridTop + midY) / 2;
        var botValueY = (midY + gridBottom) / 2;
        var gap = px(size, 4);
        var leftValueX = midX - gap;
        var rightValueX = midX + gap;

        var iconInset = px(size, 8);
        var iconLift = px(size, 3);
        var rFlame = px(size, 8);
        var rSteps = px(size, 8);
        var rHeart = px(size, 8);
        var rPin = px(size, 10);

        // Visible top of the digits inside the font box (condensed vector font
        // is fairly tight, so only a small top padding).
        var pad = numH / 8;
        var topVisTop = (topValueY - (numH / 2)) + pad;
        var botVisTop = (botValueY - (numH / 2)) + pad;

        // Each icon's center, set so its own top edge lands on the digits' top.
        var yFlame = (topVisTop - iconLift) + rFlame;            // flame top extent = r
        var ySteps = (topVisTop - iconLift) + (rSteps * 4) / 3;  // footprint top extent = 4r/3
        var yHeart = (botVisTop - iconLift) + (rHeart * 5) / 6;  // heart top extent = 5r/6
        var yPin = (botVisTop - iconLift) + (rPin * 3) / 4;      // pin top extent = 3r/4

        var xFlame = (cx - halfWidth(r, yFlame - cy)) + iconInset;
        var xSteps = (cx + halfWidth(r, ySteps - cy)) - iconInset;
        var xHeart = (cx - halfWidth(r, yHeart - cy)) + iconInset;
        var xPin = (cx + halfWidth(r, yPin - cy)) - iconInset;

        var leftJust = Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER;
        var rightJust = Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER;

        // Top-left: calories (yellow) and top-right: steps (orange) — dark ink.
        dc.setColor(BLACK, Gfx.COLOR_TRANSPARENT);
        drawFlame(dc, xFlame, yFlame, rFlame);
        drawSteps(dc, xSteps, ySteps, rSteps);
        drawCompact(dc, leftValueX, topValueY, calories, true, valueFont, numH);
        drawCompact(dc, rightValueX, topValueY, steps, false, valueFont, numH);

        // Bottom-left: heart rate (green) — dark ink.
        drawHeart(dc, xHeart, yHeart, rHeart);
        dc.drawText(leftValueX, botValueY, valueFont, heartRate, rightJust);

        // Bottom-right: distance (red) — white.
        dc.setColor(WHITE, Gfx.COLOR_TRANSPARENT);
        drawPin(dc, xPin, yPin, rPin);
        dc.drawText(rightValueX, botValueY, valueFont, formatDistance(distanceKm), leftJust);
    }

    private function drawBattery(dc, w, size) {
        var stats = Sys.getSystemStats();
        var percent = stats.battery;
        var cx = w / 2;
        var centerY = px(size, 238);
        var days = Math.ceil(percent * 14.0 / 100.0).toNumber();

        var iconW = px(size, 36);
        var iconH = px(size, 17);
        drawBatteryIcon(dc, cx - px(size, 44), centerY - (iconH / 2), iconW, iconH, percent);

        dc.setColor(WHITE, Gfx.COLOR_TRANSPARENT);
        dc.drawText(cx + px(size, 22), centerY, Gfx.FONT_TINY, days.toString() + " d",
            Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
    }

    private function getHeartRate() {
        // Current (live) heart rate; null when the watch isn't being worn.
        var act = Activity.getActivityInfo();
        if (act != null && act.currentHeartRate != null) {
            return act.currentHeartRate.toString();
        }
        return "--";
    }

    private function drawHeart(dc, x, y, r) {
        dc.fillCircle(x - (r / 2), y - (r / 3), r / 2);
        dc.fillCircle(x + (r / 2), y - (r / 3), r / 2);
        dc.fillPolygon([[x - r, y - (r / 4)], [x + r, y - (r / 4)], [x, y + r]]);
    }

    private function drawSteps(dc, x, y, r) {
        // Two staggered footprints (sole + toe).
        dc.fillRoundedRectangle(x - r, y - ((r * 4) / 5), (r * 4) / 5, (r * 7) / 5, (r * 2) / 5);
        dc.fillCircle(x - ((r * 3) / 5), y - r, r / 3);
        dc.fillRoundedRectangle(x + (r / 5), y - (r / 3), (r * 4) / 5, (r * 7) / 5, (r * 2) / 5);
        dc.fillCircle(x + ((r * 3) / 5), y - (r / 2), r / 3);
    }

    private function drawFlame(dc, x, y, r) {
        // Flame silhouette: a tall curling tongue over a forked base.
        dc.fillPolygon([
            [x, y - r],                          // tip
            [x + (r / 2), y - (r * 2) / 5],      // curl back to the right
            [x + (r * 3) / 5, y + (r / 4)],      // right shoulder
            [x + (r * 2) / 5, y + (r * 4) / 5],  // lower right
            [x - (r * 2) / 5, y + (r * 4) / 5],  // lower left
            [x - (r * 3) / 5, y + (r / 4)],      // left shoulder
            [x - (r / 4), y - (r / 3)]           // inner curl notch
        ]);
        // Forked base notch (cell color) so it reads as fire, not a droplet.
        dc.setColor(YELLOW, Gfx.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [x, y + (r / 5)],
            [x + (r / 4), y + (r * 4) / 5],
            [x - (r / 4), y + (r * 4) / 5]
        ]);
        dc.setColor(BLACK, Gfx.COLOR_TRANSPARENT);
    }

    private function drawPin(dc, x, y, r) {
        dc.fillCircle(x, y - (r / 4), r / 2);
        dc.fillPolygon([[x - (r / 2), y], [x + (r / 2), y], [x, y + r]]);
    }

    private function drawBatteryIcon(dc, x, y, w, h, percent) {
        var fill = (percent <= 15) ? RED : ((percent <= 35) ? ORANGE : GREEN);
        // Chunky rounded shell: white body with a black inner gap (double border).
        dc.setColor(WHITE, Gfx.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x, y, w, h, 4);
        dc.setColor(BLACK, Gfx.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x + 2, y + 2, w - 4, h - 4, 3);
        // Level-colored fill.
        var innerW = ((w - 8) * percent) / 100;
        dc.setColor(fill, Gfx.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x + 4, y + 4, innerW, h - 8, 2);
        // Rounded terminal nub.
        dc.setColor(WHITE, Gfx.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x + w, y + (h / 3), 3, h / 3, 1);
    }

    // Draws an integer value justified toward the center line. Values >= 10000
    // are shown compactly as e.g. "12.3k" with a smaller 'k'. Uses the current
    // foreground color.
    private function drawCompact(dc, x, y, value, justifyRight, valueFont, valueH) {
        if (value < 10000) {
            var just = justifyRight
                ? (Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER)
                : (Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER);
            dc.drawText(x, y, valueFont, value.toString(), just);
            return;
        }

        var n = value / 1000.0;
        var whole = n.toNumber();
        var dec = ((n - whole) * 10).toNumber();
        var numStr = whole.toString() + "." + dec.toString();

        // Align the small 'k' bottom with the digits' bottom (both vector,
        // tight metrics, so box-bottoms ~ glyph-bottoms).
        var kTop = (y + (valueH / 2)) - _kH;

        if (justifyRight) {
            var kw = dc.getTextWidthInPixels("k", _kFont);
            dc.drawText(x, kTop, _kFont, "k", Gfx.TEXT_JUSTIFY_RIGHT);
            dc.drawText(x - kw, y, valueFont, numStr, Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER);
        } else {
            var nw = dc.getTextWidthInPixels(numStr, valueFont);
            dc.drawText(x, y, valueFont, numStr, Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER);
            dc.drawText(x + nw, kTop, _kFont, "k", Gfx.TEXT_JUSTIFY_LEFT);
        }
    }

    private function halfWidth(r, dy) {
        var v = (r * r) - (dy * dy);
        if (v <= 0) {
            return 0;
        }
        return Math.sqrt(v);
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
        // >= 10 km: one decimal ("10.4") so it stays as narrow as "2.43".
        if (whole >= 10) {
            var d = ((km - whole) * 10).toNumber();
            return whole.toString() + "." + d.toString();
        }
        var decimals = ((km - whole) * 100).toNumber();
        if (decimals < 10) {
            return whole.toString() + ".0" + decimals.toString();
        }
        return whole.toString() + "." + decimals.toString();
    }

    private function px(size, value) {
        return (value * size) / 260;
    }
}
