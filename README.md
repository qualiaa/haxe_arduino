Haxe-Arduino Bridge
===================

This is a small library for communicating between a host PC and arduino device
in Haxe.

Example usage
-------------

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

Requirements
------------

`hxSerial`

Communication Protocol
======================

Host to Device commands
-----------------------
get analog pin value

    r,a,[pin]

get digital pin value

    r,d,[pin]

set pwm pin value

    s,a,[pin],[value]

set digital pin value

    s,d,[pin],[value]

set digital pin mode

    m,d,[i or o],[pin]

set analog pin active

    m,a,[1 or 0],[pin]

Device to Host commands
-----------------------
analog pin value

    [val]a[pin]

digital pin value

    h[pin]
    l[pin]
