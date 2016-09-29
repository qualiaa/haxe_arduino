#define BUFFER_SIZE 80
#define DIGITAL_PIN_COUNT 14
#define ANALOG_PIN_COUNT 6

#define CMD_SET       's'
#define CMD_MODE      'm'
#define CMD_READ      'r'

#define TYPE_ANALOG   'a'
#define TYPE_DIGITAL  'd'

#define SET_HIGH      'h'
#define SET_LOW       'l'

#define MODE_INPUT    'i'
#define MODE_OUTPUT   'o'
#define MODE_ACTIVE   '1'
#define MODE_INACTIVE '0'

#define MODE_

int  analogPinValues[ANALOG_PIN_COUNT];
bool analogPinActive[ANALOG_PIN_COUNT];
int  digitalPinValues[DIGITAL_PIN_COUNT];
int  digitalPinModes[DIGITAL_PIN_COUNT];
const bool pinIsPwm[DIGITAL_PIN_COUNT] = {
    0,0,0,1,0,1,1,0,0,1,1,1,0,0
};

void setup() {
    Serial.begin(9600);
    while (!Serial);

    for (int pin = 0; pin < DIGITAL_PIN_COUNT; ++pin) {
        setDigitalPinMode(pin, OUTPUT);
        digitalWrite(pin, LOW);
    }
    for (int pin = 0; pin < ANALOG_PIN_COUNT; ++pin) {
        setAnalogPinActive(pin, false);
        analogPinValues[pin] = 0;
    }

    digitalWrite(13,HIGH);

    establishContact();

    digitalWrite(13,LOW);
}

void establishContact()
{
    Serial.print('A');
    while(!Serial.available()) {
        delay(1000);
    }

    delay(1000);
    char b[2];
    Serial.readBytes(b,2);
    delay(500);

}

void setAnalogPinActive(int pin, bool active)
{
    analogPinActive[pin] = active;
}

void setDigitalPinMode(int pin, int mode)
{
    if (pinIsPwm[pin] == false) {
        pinMode(pin, mode);
        digitalPinModes[pin] = mode;
    }
}

void setDigitalPin(int pin, int value)
{
    digitalWrite(pin, value);
}

void endMessage()
{
    Serial.print('\n');
}

void sendAnalogPin(int pin, int val)
{
    Serial.print(val);
    Serial.print('a');
    Serial.print(pin);
    endMessage();
}

void sendDigitalPin(int pin, int val)
{
    char code = val == HIGH ? 'h' : 'l';
    Serial.print(code);
    Serial.print(pin);
    endMessage();
}

void send_readings() {
    for (int pin = 0; pin < ANALOG_PIN_COUNT; ++pin) {
        if (analogPinActive[pin]) {
            int val = analogRead(pin);
            if (val != analogPinValues[pin]) {
                analogPinValues[pin] = val;
                sendAnalogPin(pin, val);
            }
        }
    }
    for (int pin = 0; pin < DIGITAL_PIN_COUNT; ++pin) {
        if (digitalPinModes[pin] == INPUT) {
            int val = digitalRead(pin);
            if (val != digitalPinValues[pin]) {
                digitalPinValues[pin] = val;
                sendDigitalPin(pin, val);
            }
        }
    }
}

void receive_commands()
{
    char buffer[BUFFER_SIZE];

    while (Serial.available()) {
        int p = 0;
        char c;
        do
        {
            if (Serial.available())
            {
                c = Serial.read();
                buffer[p++] = c;
            }
        }
        while (c != '\n');
        Serial.print("Ard: Got your message: ");
        buffer[p] = '\0';
        Serial.println(buffer);
        processCommand(buffer);
    }
}

void processCommand(char* command)
{
    // could have used strtok here but w/e
    const char action = command[0];

    switch (action) {
        case CMD_SET: {
            Serial.println("Ard: Command is SET");
            const char type = command[2];
            char const* const pinStart = command + 4;
            char      * const pinEnd = strchr(pinStart,',');
            *pinEnd = '\0';
            const int pin = atoi(pinStart);
            Serial.print("Ard: pin is "); Serial.println(pin);
            if (digitalPinModes[pin] == OUTPUT) {
                switch(type) {
                    case TYPE_ANALOG: {
                        if (pinIsPwm[pin] == true) {
                            Serial.print("Ard: PWM ");
                            char const* const valStart = pinEnd+1;
                            char      * const valEnd = strchr(valStart,'\n');
                            *valEnd = '\0';
                            const int val = atoi(valStart);
                            Serial.print("val is "); Serial.println(val);
                            analogWrite(pin, val);
                        }
                        break;
                    }
                    case TYPE_DIGITAL: {
                        if (pinIsPwm[pin] == false) {
                            Serial.print("Ard: digtial ");
                            Serial.print("val is ");
                            switch (*(pinEnd+1)) {
                                case SET_HIGH:
                                    Serial.println("HIGH");
                                    digitalWrite(pin, HIGH);
                                    break;
                                case SET_LOW:
                                    Serial.println("LOW");
                                    digitalWrite(pin, LOW);
                                    break;
                                default: return;
                            }
                        }
                        break;
                    }
                    default: return;
                }
                break;
            }
        }
        case CMD_MODE: {
            Serial.println("Ard: Command is MODE");
            const char type = command[2];
            const char mode = command[4];
            char const* const pinStart = command+6;
            char      * const pinEnd = strchr(pinStart,'\n');
            *pinEnd = '\0';
            const int pin = atoi(pinStart);
            Serial.print("Ard: Mode is "); Serial.println(mode);
            Serial.print("Ard: pin is "); Serial.println(pin);
            switch (type) {
                case TYPE_DIGITAL: {
                    Serial.println("Ard: Type is digital");
                    switch (mode) {
                        case MODE_OUTPUT:
                            setDigitalPinMode(pin, OUTPUT);
                            break;
                        case MODE_INPUT:
                            setDigitalPinMode(pin, INPUT);
                            break;
                        default: return;
                    }
                }
                case TYPE_ANALOG: {
                    Serial.println("Ard: Type is analog");
                    switch (mode) {
                        case MODE_ACTIVE:
                            setAnalogPinActive(pin, true);
                            break;
                        case MODE_INACTIVE:
                            setAnalogPinActive(pin, false);
                            break;
                        default: return;
                    }
                }
            }
        }
        default: return;
    }
}

void loop()
{
    receive_commands();
    send_readings();
    delay(16);
    digitalWrite(13, digitalRead(13) == HIGH ? LOW : HIGH);
}
