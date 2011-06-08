//
// Automated distillation of up to 4 liters with a simple timer for
// two relays controlling a stil heating element and condenser fan.
// by Kyle Gabriel
//

int ledPin = 13, fanPin = 2, heatPin = 3; // LED and Relay pins

int clock = 998;  // Number of miliseconds to delay before incrementing seconds
int seconds = 0;  // Total seconds since being plugged in or a mode change
int loopsafe = 0; // Alters with user input- safety measure to prevent a power failure from turning relays on

int debug = 1;    // Turn status and serial communication on/off

int mode = 0, lastmode = 7; // Determine if the dial has been turned

int preset[6][3] = {        // Pre-programmed timer variables
   {                        //
      720, 6300, 1 }        // Preset 1: 1.5 liter cold water
   ,{                       //
      770, 9750, 1 }        // Preset 2: 2 liters cold water
   ,{                       //
      840, 11700, 1 }       // Preset 3: 3 liters cold water
   ,{                       //
      700, 5900, 1 }        // Preset 4: 1 liters cold water
   ,{                       //
      0, 0, 0 }             // Preset 5: OFF
   ,{                       //
      0, 15300, 1 }         // Preset 6: ON
};

void setup() {
  if (debug) Serial.begin(9600);
  pinMode(ledPin, OUTPUT);
  pinMode(fanPin, OUTPUT);
  pinMode(heatPin, OUTPUT);
  digitalWrite(fanPin, HIGH);  // Fan test begin
  blink(4, 550,550);
  digitalWrite(fanPin, LOW);   // Fan test end
}

void loop() {

  dialRead();
  
  if (loopsafe > 1) {
    if (preset[mode][2]) {
      if (seconds >= preset[mode][0]) {    // Turn fan on after heater has heated
        digitalWrite(fanPin, HIGH);        // the water x seconds (saves power)
      }
      if (seconds == 0) {                  // Turn heater on after switch has been
        digitalWrite(heatPin, HIGH);       // turned to an ON mode
        digitalWrite(ledPin, HIGH);
      }
      if (seconds > preset[mode][1]) {     // Turn all pins off after time has passed
        digitalWrite(ledPin, LOW);         // to distil selected volume
        digitalWrite(heatPin, LOW);
        digitalWrite(fanPin, LOW);
        loopsafe = 1;
      }
    }
    else {                                 // Power override to OFF
        digitalWrite(ledPin, LOW);
        digitalWrite(heatPin, LOW);
        digitalWrite(fanPin, LOW);
        loopsafe = 1;
    }
  }
  
  if (loopsafe && seconds % 2) blink(0, 50, 1);   // blink every other second when not in use

  if (debug) status();
  
  delay(clock);
  seconds++;
}

// Print status to Serial for debugging/logging
void status() {
    Serial.print(seconds);
    Serial.print(" [Mode: ");
    Serial.print(mode + 1);
    Serial.print("] [loopsafe: ");
    Serial.print(loopsafe);
    Serial.print("] [R1Heat: ");
    Serial.print(digitalRead(heatPin));
    Serial.print(", R2Fan:");
    Serial.print(digitalRead(fanPin));
    Serial.print("] [Fan on > ");
    Serial.print(preset[mode][0]);
    Serial.print(" sec] [Both off > ");
    Serial.print(preset[mode][1]);
    Serial.print(" sec] [Force OFF? 0=yes: ");
    Serial.print(preset[mode][2]);
    Serial.print("]");
    Serial.println();
}

//  Checks inputs 6-11 for HIGH (=1, Closed circuit, 100 ohm resistance) or LOW (=0, 10k ohm resistance)
void dialRead() {
   for (int c = 6; c < 12; c++) {
      if (digitalRead(c) == HIGH) {
         mode = c - 6;
         if (lastmode != mode) {
            digitalWrite(ledPin, LOW);
            digitalWrite(heatPin, LOW);
            digitalWrite(fanPin, LOW);
            if (loopsafe > 0) {
               Serial.print("Mode Changed To: ");
               Serial.print(mode + 1);
               Serial.println();
               blink(9, 50, 50);             // Blink 9 times, 50 ms on, 50 ms off
               blink(mode, 250, 250);        // Blink the number of the current mode
            }
            loopsafe++;
            seconds = 0;
            lastmode = mode;
         }
      }
   }
}

// Turn LED on #numblinks of times, #dur1 milliseconds on, #dur2 ms off
void blink(int numblinks, int dur1, int dur2) {
   for (int b = 0; b <= numblinks; b++) {
      digitalWrite(ledPin, HIGH);
      delay(dur1);
      digitalWrite(ledPin, LOW);
      delay(dur2);
   }
   delay(1000 - dur2);
}
