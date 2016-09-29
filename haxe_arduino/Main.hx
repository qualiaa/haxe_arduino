package;

using Lambda;

class Main
{
    public static function main()
    {
        var bridge = new ArduinoBridge();
        var potPin = 0;
        bridge.setDigitalPin(4, HIGH);
        bridge.setPwmPin(3, 123);
        bridge.setDigitalPinMode(3,OUTPUT);
        bridge.setAnalogPinActive(potPin, true);
        while(true)
        {
            Sys.sleep(0.1);
            bridge.sync();
            trace(bridge.readAnalogPin(potPin));
        }
    }
}
