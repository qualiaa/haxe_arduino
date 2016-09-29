build/Main: Main.hx ArduinoBridge.hx
	haxe -main Main.hx -cpp build -lib hxSerial
