using Toybox.Application as App;
using Toybox.WatchUi as Ui;

class ColorGridFaceApp extends App.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        return [ new ColorGridFaceView() ];
    }
}

