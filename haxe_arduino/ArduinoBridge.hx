package haxe_arduino;

import hxSerial.Serial;
using Lambda;

@:enum
abstract Command (String) to String {
    var READ    = "r";
    var SET     = "s";
    var MODE    = "m";
}

@:enum
abstract PinType (String) to String{
    var ANALOG  = "a";
    var DIGITAL = "d";
}

@:enum
abstract Mode (String) to String{
    var INPUT   = "i";
    var OUTPUT  = "o";
}

@:enum
abstract Level (String) to String{
    var HIGH    = "h";
    var LOW     = "l";
}

class ArduinoBridge
{
    static inline var ANALOG_PIN_COUNT = 6;
    static inline var DIGITAL_PIN_COUNT = 14;
    static inline var MAX_PWM_OUTPUT = 255;

    var device_ : Serial;
    var analogValues_ : Array<Null<Int>>   = [];
    var digitalValues_ : Array<Null<Bool>> = [];
    var analogMaxValues_ : Array<Int>      = [];
    var pinIsPwm_ : Array<Bool>      = [
        false, false, false, true, false, true, true, false, false, true, true,
        true, false, false
    ];


    public function new()
    {
        var deviceList = Serial.getDeviceList();
        var usbPath : Null<String>;

        do {
            usbPath = deviceList.find(function (path)
                    return path.toLowerCase().indexOf("usb") != -1);
            trace(usbPath);
            sleep(1);
        }
        while(usbPath == null);

        device_ = new Serial(usbPath, 9600, true);

        Sys.sleep(1);

        device_.writeBytes("A\n");
        device_.flush(true);



        for (i in 0 ... ANALOG_PIN_COUNT)
        {
            analogMaxValues_.push(1023);
            analogValues_.push(null);
        }

        for (i in 0 ... DIGITAL_PIN_COUNT)
        {
            digitalValues_.push(null);
        }
    }

    public function awaitResponse() : Void
    {
        var command;
        do {
            trace("WAITING");
            command = readCommand(true);
            trace("DONE WAITING: " + Lambda.map([for (i in 0...command.length) i], function(s){return command.charCodeAt(s);}));
        }
        while(!parseCommand(command));
        trace("DONE");
    }

    public function sync() : Void
    {
        while (device_.available() > 0)
        {
            var command = readCommand();
            parseCommand(command);
        }
    }

    private function readCommand(?wait:Bool = false) : Null<String>
    {
        if (device_.available() == 0 && !wait) return null;

        var command = "";
        var c : String = "";
        do
        {
            if (device_.available() > 0) {
                c = String.fromCharCode(device_.readByte());
                command = command + c;
            }
        }
        while (c != '\n');
        return command;
    }

    // Returns: Whether the command was useful (true) or debug (false)
    private function parseCommand(command: String) : Bool
    {
        trace(command);
        var firstByte = command.charAt(0);
        if(firstByte == "A" || firstByte == "\n" || firstByte == "\r") {
            trace("Treating as useless string");
            return false;
        }
        else if (firstByte == HIGH || firstByte == LOW) {
            var pin = Std.parseInt(command.substring(1));
            digitalValues_[pin] = (firstByte == HIGH) ? true : false;
            return true;
        } else {
            var indexOfPin = command.indexOf("a");
            var pin = Std.parseInt(command.substring(indexOfPin + 1));
            var value = Std.parseInt(command.substring(0, indexOfPin));
            analogValues_[pin] = value;
            return true;
        }
    }

    public function setDigitalPinMode(pin : Int, mode : Mode) {
        checkPin(DIGITAL, pin);

        sendCommand(MODE, [DIGITAL, mode, pin]);
    }

    public function setAnalogPinActive(pin : Int, active: Bool)
    {
        sendCommand(MODE, [ANALOG, active ? 1 : 0, pin]);
    }

    public function setDigitalPin(pin : Int, setting : Level)
    {
        if (pinIsPwm_[pin])
        {
            setPwmPin(pin, 255);
        }
        else
        {
            sendCommand(SET, [DIGITAL, pin, setting]);
        }
    }

    public function setPwmPin(pin : Int, setting : Int)
    {
        if (pinIsPwm_[pin] == false)
        {
            throw "Called setPwmPin on non-PWM pin " + pin;
        }
        if (setting < 0 || setting > MAX_PWM_OUTPUT)
        {
            throw "Invalid analog setting. Must be below" + MAX_PWM_OUTPUT;
        }
        sendCommand(SET, [ANALOG, pin, setting]);
    }


    public function setAnalogPinMax(pin : Int, maxVal: Int) : Void
    {
        checkPin(ANALOG, pin);
        analogMaxValues_[pin] = maxVal;
    }

    public function requestAnalogPin(pin : Int) : Void
    {
        checkPin(ANALOG, pin);
        sendCommand(READ, [ANALOG, pin]);
    }

    public function requestDigitalPin(pin : Int) : Void
    {
        checkPin(DIGITAL, pin);
        sendCommand(READ, [DIGITAL, pin]);
    }

    public function getAnalogPinRaw(pin : Int) : Null<Int>
    {
        return analogValues_[pin];
    }

    public function getAnalogPin(pin : Int) : Null<Float>
    {
        var rawVal = getAnalogPinRaw(pin);
        if (rawVal == null)
        {
            return null;
        }
        return Math.min(rawVal / analogMaxValues_[pin], 1);
    }

    public function getDigitalPin(pin : Int) : Null<Bool>
    {
        return digitalValues_[pin];
    }


    private function checkPin(type : PinType, pin : Int)
    {
        var n_pins = (type == ANALOG) ? ANALOG_PIN_COUNT : DIGITAL_PIN_COUNT;
        if (pin < 0 || pin >= n_pins) {
            throw "Invalid pin. Must be below " + n_pins;
        }
    }

    public function write(bytes : String) : Void
    {
        device_.writeBytes(bytes);
    }

    public function available() : Int
    {
        return device_.available();
    }

    public function read(bytesToRead : Int) : String
    {
        return device_.readBytes(bytesToRead);
    }

    private function sendCommand(command: String, ?args : Array<Dynamic>)
    {
        if (args != null) {
            command = command + args.fold(function(x, acc)
                    return  acc + "," + Std.string(x), "") + "\n";
        }

        trace("Sending command " + command);
        device_.writeBytes(command);
    }
}
