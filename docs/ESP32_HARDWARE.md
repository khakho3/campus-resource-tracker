# ESP32 hardware demo

This guide wires the ESP32 demo hardware to the FastAPI backend used by the
mobile app.

## Data flow

```text
ESP32 sensors -> FastAPI backend -> MySQL -> Flutter phone app
```

The phone does not receive data directly from the ESP32. Refresh the phone app
after a sensor update to show the latest backend state.

## Connections

All component grounds must connect to ESP32 `GND`.

```text
LDR:
ESP32 3.3V -> LDR leg 1
LDR leg 2 -> GPIO34
GPIO34 -> 10k resistor -> GND
```

```text
LED:
GPIO26 -> 220 ohm resistor -> LED long leg
LED short leg -> GND
```

```text
Pushbutton:
Button leg 1 -> GPIO27
Button leg 2 -> GND
```

```text
PIR motion sensor:
VCC -> VIN / 5V
GND -> GND
OUT -> GPIO14
```

```text
RFID MFRC522:
SDA / SS -> GPIO21
SCK      -> GPIO18
MOSI     -> GPIO23
MISO     -> GPIO19
RST      -> GPIO22
3.3V     -> ESP32 3.3V
GND      -> ESP32 GND
```

Use `3.3V` for the MFRC522. Do not power it from `5V`.

```text
Ultrasonic A1:
VCC  -> VIN / 5V
GND  -> GND
TRIG -> GPIO32
ECHO -> voltage divider -> GPIO25
```

```text
Ultrasonic A2:
VCC  -> VIN / 5V
GND  -> GND
TRIG -> GPIO33
ECHO -> voltage divider -> GPIO35
```

Each HC-SR04 `ECHO` pin is 5V. Use a voltage divider before the ESP32 pin:

```text
HC-SR04 ECHO -> 1k resistor -> ESP32 echo pin
ESP32 echo pin -> 2k resistor -> GND
```

## Backend setup

Start the backend:

```powershell
Set-Location backend
.\.venv\Scripts\Activate.ps1
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Find the laptop Wi-Fi IPv4 address with `ipconfig`, then put that address in
the ESP32 sketch:

```cpp
const char* BACKEND_BASE_URL = "http://YOUR_LAPTOP_IP:8000";
```

## Arduino sketch

Install the `MFRC522` library in Arduino IDE. Replace `YOUR_WIFI_NAME`,
`YOUR_WIFI_PASSWORD`, and `YOUR_LAPTOP_IP`.

```cpp
#include <WiFi.h>
#include <HTTPClient.h>
#include <SPI.h>
#include <MFRC522.h>

const char* WIFI_NAME = "YOUR_WIFI_NAME";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";
const char* BACKEND_BASE_URL = "http://YOUR_LAPTOP_IP:8000";

const int LDR_PIN = 34;
const int LED_PIN = 26;
const int BUTTON_PIN = 27;
const int PIR_PIN = 14;
const int A1_TRIG_PIN = 32;
const int A1_ECHO_PIN = 25;
const int A2_TRIG_PIN = 33;
const int A2_ECHO_PIN = 35;
const int RFID_SS_PIN = 21;
const int RFID_RST_PIN = 22;
const int LIGHT_THRESHOLD = 1800;
const int OCCUPIED_DISTANCE_CM = 45;

MFRC522 rfid(RFID_SS_PIN, RFID_RST_PIN);

bool lastLibraryOpen = false;
bool lastMotionDetected = false;
bool lastA1Occupied = false;
bool lastA2Occupied = false;
bool firstRun = true;

unsigned long lastIotSendTime = 0;
const unsigned long IOT_SEND_INTERVAL_MS = 5000;

void setup() {
  Serial.begin(115200);
  delay(1000);

  pinMode(LED_PIN, OUTPUT);
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  pinMode(PIR_PIN, INPUT);
  pinMode(A1_TRIG_PIN, OUTPUT);
  pinMode(A1_ECHO_PIN, INPUT);
  pinMode(A2_TRIG_PIN, OUTPUT);
  pinMode(A2_ECHO_PIN, INPUT);

  SPI.begin(18, 19, 23, RFID_SS_PIN);
  rfid.PCD_Init();

  WiFi.mode(WIFI_STA);
  WiFi.setSleep(true);
  WiFi.setTxPower(WIFI_POWER_8_5dBm);
  WiFi.begin(WIFI_NAME, WIFI_PASSWORD);

  Serial.print("Connecting to WiFi");
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 40) {
    delay(500);
    Serial.print(".");
    attempts++;
  }

  Serial.println();
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("WiFi connected");
    Serial.print("ESP32 IP: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("WiFi failed");
  }
}

void loop() {
  bool buttonPressed = digitalRead(BUTTON_PIN) == LOW;
  digitalWrite(LED_PIN, buttonPressed ? HIGH : LOW);
  delay(100);

  int ldrValue = analogRead(LDR_PIN);
  bool lightDetected = ldrValue > LIGHT_THRESHOLD;
  bool libraryOpen = lightDetected;
  bool pirDetected = digitalRead(PIR_PIN) == HIGH;

  float a1Distance = readDistanceCm(A1_TRIG_PIN, A1_ECHO_PIN);
  float a2Distance = readDistanceCm(A2_TRIG_PIN, A2_ECHO_PIN);
  bool a1Occupied = isSeatOccupied(a1Distance);
  bool a2Occupied = isSeatOccupied(a2Distance);
  bool motionDetected = pirDetected || lightDetected;

  printStatus(buttonPressed, ldrValue, libraryOpen, pirDetected,
      a1Distance, a1Occupied, a2Distance, a2Occupied);

  if (firstRun || libraryOpen != lastLibraryOpen) {
    sendLibraryState(libraryOpen);
    lastLibraryOpen = libraryOpen;
  }

  bool iotChanged = firstRun ||
      motionDetected != lastMotionDetected ||
      a1Occupied != lastA1Occupied ||
      a2Occupied != lastA2Occupied;
  bool timeToSend = millis() - lastIotSendTime >= IOT_SEND_INTERVAL_MS;

  if (iotChanged || timeToSend) {
    sendIotReading(motionDetected, a1Occupied, a1Distance,
        a2Occupied, a2Distance);
    lastMotionDetected = motionDetected;
    lastA1Occupied = a1Occupied;
    lastA2Occupied = a2Occupied;
    lastIotSendTime = millis();
  }

  handleRfidScan();
  firstRun = false;
  delay(500);
}

float readDistanceCm(int trigPin, int echoPin) {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  long duration = pulseIn(echoPin, HIGH, 30000);
  if (duration == 0) {
    return -1;
  }
  return duration * 0.0343 / 2;
}

bool isSeatOccupied(float distanceCm) {
  return distanceCm >= 0 && distanceCm <= OCCUPIED_DISTANCE_CM;
}

void printStatus(bool buttonPressed, int ldrValue, bool libraryOpen,
    bool pirDetected, float a1Distance, bool a1Occupied,
    float a2Distance, bool a2Occupied) {
  Serial.print("Button: ");
  Serial.print(buttonPressed ? "PRESSED" : "NOT PRESSED");
  Serial.print(" | LDR: ");
  Serial.print(ldrValue);
  Serial.print(" | Library: ");
  Serial.print(libraryOpen ? "OPEN" : "CLOSED");
  Serial.print(" | PIR: ");
  Serial.print(pirDetected ? "YES" : "NO");
  Serial.print(" | A1: ");
  Serial.print(a1Distance);
  Serial.print("cm ");
  Serial.print(a1Occupied ? "OCCUPIED" : "FREE");
  Serial.print(" | A2: ");
  Serial.print(a2Distance);
  Serial.print("cm ");
  Serial.println(a2Occupied ? "OCCUPIED" : "FREE");
}

void handleRfidScan() {
  if (!rfid.PICC_IsNewCardPresent() || !rfid.PICC_ReadCardSerial()) {
    return;
  }

  String uid = "";
  for (byte i = 0; i < rfid.uid.size; i++) {
    if (rfid.uid.uidByte[i] < 0x10) {
      uid += "0";
    }
    uid += String(rfid.uid.uidByte[i], HEX);
    if (i < rfid.uid.size - 1) {
      uid += "-";
    }
  }
  uid.toUpperCase();

  Serial.print("RFID UID: ");
  Serial.println(uid);
  sendStaffScan(uid);
  rfid.PICC_HaltA();
  rfid.PCD_StopCrypto1();
  delay(1500);
}

void sendLibraryState(bool isOpen) {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi disconnected, library state not sent");
    return;
  }

  HTTPClient http;
  http.begin(String(BACKEND_BASE_URL) + "/api/v1/library/state");
  http.addHeader("Content-Type", "application/json");

  String payload = String("{\"is_open\":") + (isOpen ? "true" : "false") + "}";
  int statusCode = http.sendRequest("PATCH", payload);

  Serial.print("Library HTTP status: ");
  Serial.println(statusCode);
  Serial.println(http.getString());
  http.end();
}

void sendIotReading(bool motionDetected, bool a1Occupied, float a1Distance,
    bool a2Occupied, float a2Distance) {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi disconnected, IoT reading not sent");
    return;
  }

  HTTPClient http;
  http.begin(String(BACKEND_BASE_URL) + "/api/v1/iot/readings");
  http.addHeader("Content-Type", "application/json");

  String payload = "{";
  payload += "\"device_id\":\"esp32-library-01\",";
  payload += "\"motion_detected\":";
  payload += motionDetected ? "true" : "false";
  payload += ",\"seats\":[";
  payload += "{\"code\":\"A1\",\"occupied\":";
  payload += a1Occupied ? "true" : "false";
  payload += ",\"distance_cm\":";
  payload += String(a1Distance, 1);
  payload += "},{\"code\":\"A2\",\"occupied\":";
  payload += a2Occupied ? "true" : "false";
  payload += ",\"distance_cm\":";
  payload += String(a2Distance, 1);
  payload += "}]}";

  int statusCode = http.POST(payload);
  Serial.print("IoT HTTP status: ");
  Serial.println(statusCode);
  Serial.println(http.getString());
  http.end();
}

void sendStaffScan(String uid) {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi disconnected, RFID not sent");
    return;
  }

  HTTPClient http;
  http.begin(String(BACKEND_BASE_URL) + "/api/v1/staff/scan");
  http.addHeader("Content-Type", "application/json");

  String payload = String("{\"rfid_uid\":\"") + uid + "\"}";
  int statusCode = http.POST(payload);

  Serial.print("Staff HTTP status: ");
  Serial.println(statusCode);
  Serial.println(http.getString());
  http.end();
}
```

## Register an RFID card

Scan the card once and copy the UID from Serial Monitor. It will look like
`AA-BB-CC-DD`. Register that UID for the seeded staff member:

```powershell
Set-Location backend
.\.venv\Scripts\python.exe -c "from sqlalchemy import select; from app.database import SessionLocal; from app.models.entities import Staff; db=SessionLocal(); staff=db.scalar(select(Staff).where(Staff.staff_code=='STAFF-001')); staff.rfid_uid='PASTE_UID_HERE'; db.commit(); db.close()"
```

After registration, scanning the card should print `Staff HTTP status: 200`.

## Upload checklist

1. Start MySQL and the backend.
2. Confirm `http://127.0.0.1:8000/health` returns `ok`.
3. Put the laptop IP in `BACKEND_BASE_URL`.
4. Upload the sketch and open Serial Monitor at `115200`.
5. Confirm `Library HTTP status: 200`, `IoT HTTP status: 200`, and
   `Staff HTTP status: 200`.
6. Pull down to refresh the mobile app.

If the ESP32 restarts with `Brownout detector was triggered`, use a stronger
USB cable, a laptop USB port directly, or a power bank.
