#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <ESP32Servo.h>

/* ── Wi-Fi credentials ── */
const char* WIFI_SSID = "Iphone(2)";
const char* WIFI_PASS = "ali10412";

/* ── Cloud API ── */
const char* API_BASE      = "https://quickpark.onrender.com";
const char* CMD_NEXT_PATH = "/api/cmd/next";
const char* API_KEY       = "MY_SECRET_DEVICE_TOKEN";

/* ── Pin map ── */
#define IR1_PIN 32
#define SERVO1_PIN  18
#define IR2_PIN     25
#define SERVO2_PIN  26
#define IR3_PIN     27
#define SERVO3_PIN  14
#define IR4_PIN     12
#define SERVO4_PIN  13
#define LED_PIN     2

Servo servo1, servo2, servo3, servo4;

/* ── Parking constants ── */
const int    CAR_PRESENT = LOW;
const unsigned long UNIT      = 600000UL;   // 15 s
const unsigned long WARN      =  15000UL;   //  5 s
const unsigned long START_TMO = 15000UL;   // 15 s
const unsigned long GATE_TIMEOUT = 120000UL; // 2 minutes for car entry

// Enhanced state machine
enum FState { BLOCKED, WAIT_DUR, START_ARMED, GATE_OPEN, DOWN, VIOLATION };
FState state = BLOCKED;

/* ── Runtime state ── */
unsigned long parkingStart = 0;
unsigned long paidWindow   = 0;
unsigned long startTime    = 0;
unsigned long gateOpenTime = 0;
bool warningSent  = false;
bool startPressed = false;
String selectedSlot = "";
String reservedUserName = ""; // Track who reserved the slot

/* ── Track server's last known state ── */
String serverState[5] = { "", "available", "available", "available", "available" };
unsigned long lastStateUpdate[5] = { 0, 0, 0, 0, 0 };

/* ── Forward declarations ── */
void handleCmd(const String& c);
Servo& getServo(const String& slot);
int   getIRPin(const String& slot);
bool  isCarPresent(int pin);
void  raiseFlaps();
void  printAvailability();
void  fetchStatus();
void  fetchNextCommand();
void  checkReservationTimeouts();
void  updateSlotStatus(const String& slot, const String& status, const String& userName = "");
void  handleGateLogic();

/* ─────────────────────────────────────────────────────────────
   1.  GET  /api/slots
   ───────────────────────────────────────────────────────────── */
void fetchStatus() {
  if (WiFi.status() != WL_CONNECTED) return;

  HTTPClient http;
  http.begin(String(API_BASE) + "/api/slots");
  http.addHeader("x-api-key", API_KEY);
  
  int code = http.GET();
  if (code == 200) {
    String body = http.getString();
    Serial.println("[SLOTS] Response received");

    StaticJsonDocument<1024> doc;
    DeserializationError error = deserializeJson(doc, body);
    
    if (!error) {
      JsonArray arr = doc.as<JsonArray>();
      for (JsonObject slot : arr) {
        int num = slot["slotNumber"];
        const char* st = slot["status"];
        
        if (num < 1 || num > 4) {
          Serial.printf("[WARN] Invalid slot number: %d\n", num);
          continue;
        }
        
        serverState[num] = String(st);
        lastStateUpdate[num] = millis();
        
        bool occupied = strcmp(st, "occupied") == 0;
        bool reserved = strcmp(st, "reserved") == 0;
        bool down = occupied;

        // Update servo position - BUT NOT during START_ARMED state
        if (state != START_ARMED || selectedSlot != ("A" + String(num < 10 ? "0" : "") + String(num))) {
          switch (num) {
            case 1: servo1.write(down ? 90 : 0); break;
            case 2: servo2.write(down ? 90 : 0); break;
            case 3: servo3.write(down ? 90 : 0); break;
            case 4: servo4.write(down ? 90 : 0); break;
          }
          Serial.printf("Slot A%02d → %s (servo: %d°)\n", num, st, down ? 90 : 0);
        } else {
          Serial.printf("Slot A%02d → %s (servo: keeping current position - waiting for START)\n", num, st);
        }
      }
    } else {
      Serial.printf("[ERROR] JSON parse failed: %s\n", error.c_str());
    }
  } else {
    Serial.printf("[ERROR] GET /slots → %d\n", code);
  }
  http.end();
}

/* ─────────────────────────────────────────────────────────────
   2.  GET  /api/cmd/next
   ───────────────────────────────────────────────────────────── */
void fetchNextCommand() {
  if (WiFi.status() != WL_CONNECTED) return;

  HTTPClient http;
  http.begin(String(API_BASE) + CMD_NEXT_PATH);
  http.addHeader("x-api-key", API_KEY);
  
  int code = http.GET();
  if (code == 200) {
    String body = http.getString();
    StaticJsonDocument<200> doc;
    DeserializationError error = deserializeJson(doc, body);
    
    if (!error) {
      const char* cmd  = doc["cmd"];
      const char* slot = doc["slot"] | "";
      const char* pin  = doc["pin"] | "";
      int dur = doc["duration"] | 0;

      if (strcmp(cmd, "PIN") == 0 && strlen(slot)) {
        handleCmd("PIN " + String(slot) + " " + String(pin));
      } else if (strcmp(cmd, "D") == 0 && dur > 0) {
        handleCmd("D" + String(dur));
      } else {
        handleCmd(String(cmd));
      }
      Serial.println("[CMD] " + String(body));
    } else {
      Serial.println("[ERROR] JSON parse /cmd/next");
    }
  } else if (code != 204) {
    Serial.printf("[ERROR] GET /cmd/next → %d\n", code);
  }
  http.end();
}

/* ─────────────────────────────────────────────────────────────
   3.  SETUP
   ───────────────────────────────────────────────────────────── */
void setup() {
  Serial.begin(115200);
  delay(300);

  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  Serial.print("[WiFi] Connecting");
  while (WiFi.status() != WL_CONNECTED) {
    delay(250); Serial.print('.');
  }
  Serial.println("\n[WiFi] Connected → " + WiFi.localIP().toString());

  /* Initialize servos */
  for (int p : {SERVO1_PIN,SERVO2_PIN,SERVO3_PIN,SERVO4_PIN}) {
    pinMode(p, OUTPUT); digitalWrite(p, LOW);
  }
  delay(300);
  servo1.setPeriodHertz(50); servo1.attach(SERVO1_PIN, 500,2400); servo1.write(0);
  servo2.setPeriodHertz(50); servo2.attach(SERVO2_PIN, 500,2400); servo2.write(0);
  servo3.setPeriodHertz(50); servo3.attach(SERVO3_PIN, 500,2400); servo3.write(0);
  servo4.setPeriodHertz(50); servo4.attach(SERVO4_PIN, 500,2400); servo4.write(0);

  pinMode(IR1_PIN, INPUT); pinMode(IR2_PIN, INPUT);
  pinMode(IR3_PIN, INPUT); pinMode(IR4_PIN, INPUT);
  pinMode(LED_PIN, OUTPUT); digitalWrite(LED_PIN, LOW);

  delay(1000);
  fetchStatus();
  
  Serial.println("[OK] Ready – polling server");
}

/* ─────────────────────────────────────────────────────────────
   4.  MAIN LOOP
   ───────────────────────────────────────────────────────────── */
unsigned long lastFetch = 0, lastCommand = 0, lastIRprint = 0;
const unsigned long FETCH_INTERVAL   = 5000;
const unsigned long COMMAND_INTERVAL = 1000;
const unsigned long IR_INTERVAL      = 5000;

void loop() {
  unsigned long now = millis();

  if (now - lastFetch >= FETCH_INTERVAL) { 
    fetchStatus(); 
    lastFetch = now; 
  }
  
  if (now - lastCommand >= COMMAND_INTERVAL) { 
    fetchNextCommand(); 
    lastCommand = now; 
  }
  
  if (now - lastIRprint >= IR_INTERVAL) { 
    printAvailability(); 
    lastIRprint = now; 
  }
  
  checkReservationTimeouts();

  // Enhanced gate logic
  handleGateLogic();

  // Handle parking session states
  if (state == DOWN || state == VIOLATION) {
    bool carHere = isCarPresent(getIRPin(selectedSlot));
    unsigned long elapsed = now - parkingStart;
    unsigned long left = (paidWindow > elapsed) ? paidWindow - elapsed : 0;

    if (state == DOWN) {
      if (!warningSent && left && left <= WARN) { 
        warningSent = true; 
        Serial.println("[WARN] Time almost up"); 
      }
      if (!carHere && elapsed < paidWindow) { 
        updateSlotStatus(selectedSlot, "available");
        raiseFlaps(); 
        Serial.println("[INFO] Driver left early"); 
      }
      if (elapsed >= paidWindow) {
            // 1️⃣ keep the flap up (0° blocks exit)
        getServo(selectedSlot).write(0);

        if (carHere) {
            /* ----- VIOLATION: car overstayed ----- */
            state = VIOLATION;                 // LED will start flashing
            digitalWrite(LED_PIN, HIGH);       // turn LED on solid for emphasis
            updateSlotStatus(selectedSlot,
                            "violation",      // or "overdue", "fine"—whatever your API expects
                            reservedUserName);

            Serial.println("[FINE] Session expired: car still present → fine applied");
        } else {
            /* ----- driver left on time ----- */
            state = BLOCKED;
            updateSlotStatus(selectedSlot, "available");
            raiseFlaps();
            Serial.println("[INFO] Time ended – slot free");
        }
      }
    } else {  // VIOLATION
      digitalWrite(LED_PIN, !digitalRead(LED_PIN));
      if (!carHere) { 
        updateSlotStatus(selectedSlot, "available");
        raiseFlaps(); 
        Serial.println("[OK] Violation cleared"); 
      }
    }
  }
  
  delay(10);
}

/* ─────────────────────────────────────────────────────────────
   5.  FIXED Gate Logic - Only Opens on START Command
   ───────────────────────────────────────────────────────────── */
void handleGateLogic() {
  unsigned long now = millis();

  // Gate should only open after START command
  if (state == START_ARMED && startPressed) {
    Serial.printf("[INFO] START command received → Opening gate for %s\n", selectedSlot.c_str());

    getServo(selectedSlot).write(90);  // Gate down (open)
    state = GATE_OPEN;
    gateOpenTime = now;
    startPressed = false;
    Serial.println("[DEBUG] Gate should now be open, state changed to GATE_OPEN");

  }

  if (state == GATE_OPEN) {
    Serial.printf("[DEBUG] Waiting for car at %s... (%.1f sec)\n", selectedSlot.c_str(), (now - gateOpenTime) / 1000.0);

    if (isCarPresent(getIRPin(selectedSlot))) {
      // Car successfully entered → mark slot as occupied
      Serial.printf("[INFO] Car detected at %s → Closing gate and starting session\n", selectedSlot.c_str());

      digitalWrite(LED_PIN, HIGH);
      getServo(selectedSlot).write(0);  // Close gate (flap up again)
      parkingStart = now;
      warningSent = false;
      state = DOWN;

      int slotNum = selectedSlot.substring(2).toInt();

      // Update server only if needed
      if (serverState[slotNum] != "occupied") {
        updateSlotStatus(selectedSlot, "occupied", reservedUserName);
      } else {
        Serial.printf("[WARN] Slot %s already marked as occupied on server\n", selectedSlot.c_str());
      }
    }

    else if (now - gateOpenTime > GATE_TIMEOUT) {
      // Car did not arrive → cancel reservation
      Serial.printf("[WARN] Timeout: No car detected at %s, closing gate\n", selectedSlot.c_str());

      getServo(selectedSlot).write(0);  // Gate up (close)
      updateSlotStatus(selectedSlot, "available");
      raiseFlaps();  // Reset state to BLOCKED
    }
  }
}
/* ─────────────────────────────────────────────────────────────
   6.  Helper Functions
   ───────────────────────────────────────────────────────────── */
void raiseFlaps() {
  for (auto s : { &servo1,&servo2,&servo3,&servo4 }) s->write(0);
  digitalWrite(LED_PIN, LOW); 
  startPressed = warningSent = false;
  selectedSlot = ""; 
  reservedUserName = "";
  state = BLOCKED;
  Serial.println("[INFO] SPACE BLOCKED – ready");
}

Servo& getServo(const String& slot) {
  if      (slot=="A01") return servo1;
  else if (slot=="A02") return servo2;
  else if (slot=="A03") return servo3;
  else                  return servo4;
}

int getIRPin(const String& slot) {
  if      (slot=="A01") return IR1_PIN;
  else if (slot=="A02") return IR2_PIN;
  else if (slot=="A03") return IR3_PIN;
  else                  return IR4_PIN;
}
bool isCarPresent(int pin) {
  int count = 0;
  for (int i = 0; i < 5; i++) {
    if (digitalRead(pin) == CAR_PRESENT) count++;
    delay(1);
  }
  return count >= 3; // 3 out of 5 reads must detect presence
}

/* ─────────────────────────────────────────────────────────────
   7.  Enhanced Sensor Monitoring
   ───────────────────────────────────────────────────────────── */
void printAvailability() {
  Serial.println("\n[REAL-TIME] SLOT STATUS:");
  
  // Ensure we have recent server state
  unsigned long now = millis();
  bool needsFetch = false;
  
  for (int i = 1; i <= 4; i++) {
    if (now - lastStateUpdate[i] > 10000) {
      needsFetch = true;
      break;
    }
  }
  
  if (needsFetch) {
    Serial.println("[INFO] Server state is stale, fetching fresh status...");
    fetchStatus();
    delay(200);
  }

  for (int slotNum = 1; slotNum <= 4; slotNum++) {
    String slotName = "A0" + String(slotNum);
    int pin = getIRPin(slotName);
    bool carDetected = isCarPresent(pin);
    
    Serial.printf("%s %s: Sensor=%s, Server=%s\n", 
                  carDetected ? "[X]" : "[✓]", 
                  slotName.c_str(), 
                  carDetected ? "Car" : "Empty",
                  serverState[slotNum].c_str());

    // Enhanced logic for occupied status handling
    if (serverState[slotNum] == "occupied") {
      if (!carDetected) {
        // Car left - always update to available
        Serial.printf("  ↳ UPDATE: Car left occupied slot\n");
        updateSlotStatus(slotName, "available");
      } else {
        Serial.printf("  ↳ SKIP: Slot occupied and car present\n");
      }
      continue;
    }
    
    if (carDetected) {
      if (serverState[slotNum] == "available") {
        // Unauthorized parking detected
        Serial.printf("  ↳ ALERT: Unauthorized parking detected!\n");
        updateSlotStatus(slotName, "occupied", "unauthorized_user");
      } else if (serverState[slotNum] == "reserved") {
        // Reserved slot occupied - check if it's our reservation
        if (selectedSlot == slotName && (state == GATE_OPEN || state == DOWN)) {
          Serial.printf("  ↳ SKIP: Our reserved slot being used\n");
        } else {
          Serial.printf("  ↳ ALERT: Reserved slot occupied by unauthorized user!\n");
          updateSlotStatus(slotName, "occupied", "unauthorized_user");
        }
      }
    } else {
      // No car detected
      if (serverState[slotNum] == "available") {
        Serial.printf("  ↳ SKIP: State already matches (available)\n");
      } else if (serverState[slotNum] == "reserved") {
        if (selectedSlot == slotName) {
          Serial.printf("  ↳ SKIP: Our reservation still active\n");
        } else {
          Serial.printf("  ↳ SKIP: Reserved by another user\n");
        }
      }
    }
  }
}

void checkReservationTimeouts() {
  static unsigned long lastCheck = 0;
  unsigned long now = millis();
  
  if (now - lastCheck < 60000) return;
  lastCheck = now;
  
  int reservedCount = 0;
  for (int i = 1; i <= 4; i++) {
    if (serverState[i] == "reserved") {
      reservedCount++;
    }
  }
  
  if (reservedCount > 0) {
    Serial.printf("[CHECK] Found %d reserved slot(s) - forcing status refresh\n", reservedCount);
    fetchStatus();
  }
}

/* ─────────────────────────────────────────────────────────────
   8.  FIXED Command Parser - Gate Only Opens on START
   ───────────────────────────────────────────────────────────── */
void handleCmd(const String& c) {
  if (c.equalsIgnoreCase("AVAIL")) { 
    printAvailability(); 
    return; 
  }

  if (c.startsWith("PIN") && state==BLOCKED) {
    int sp1=c.indexOf(' '), sp2=c.indexOf(' ',sp1+1);
    if (sp2>sp1){ 
      selectedSlot=c.substring(sp1+1,sp2);
      reservedUserName = c.substring(sp2+1); // Extract username from PIN command
      state=WAIT_DUR;
      // FIXED: Do NOT open gate here - only mark as reserved
      Serial.printf("[OK] PIN OK – Slot %s reserved for %s (gate remains closed)\n",selectedSlot.c_str(), reservedUserName.c_str()); 
    }
    return;
  }
  
  if (c.startsWith("D") && state==WAIT_DUR) {
    int n=c.substring(1).toInt();
    if(n>=1&&n<=3){ 
      paidWindow=n*UNIT; 
      state=START_ARMED; 
      startTime=millis();
      // FIXED: Do NOT open gate here - wait for START command
      Serial.printf("[INFO] Paid %lus – WAITING FOR START COMMAND (gate closed)\n",n*UNIT/1000); 
    }
    return;
  }
  
  if (c.equalsIgnoreCase("START") && state==START_ARMED) {
     Serial.println("[DEBUG] START command - conditions met, setting startPressed=true");
    startPressed=true;  // This will trigger gate opening in handleGateLogic()
    Serial.printf("[INFO] START received → will open gate for %s\n",selectedSlot.c_str()); 
    return;
  }
  
  if (c.startsWith("EXT") && state==DOWN && warningSent) {
    int n=c.substring(3).toInt();
    if(n>=1&&n<=3){ 
      paidWindow+=n*UNIT; 
      warningSent=false;
      Serial.printf("[INFO] Extended +%lus\n",n*UNIT/1000); 
    }
    return;
  }
  
  if (c.equalsIgnoreCase("CLR") && (state==WAIT_DUR||state==START_ARMED)) {
    raiseFlaps(); 
    Serial.println("[INFO] Cancelled → BLOCKED"); 
    return;
  }
}

/* ─────────────────────────────────────────────────────────────
   9.  Enhanced Update Slot Status on Server
   ───────────────────────────────────────────────────────────── */
void updateSlotStatus(const String& slot, const String& status, const String& userName) {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("[ERROR] WiFi not connected, cannot update slot status");
    return;
  }
  
  int slotNum = slot.substring(2).toInt();
  
  // Check current server state before updating to prevent conflicts
  if (status == "occupied" && serverState[slotNum] == "occupied") {
    Serial.printf("[WARN] Slot %s already occupied on server - skipping update\n", slot.c_str());
    return;
  }
  
  DynamicJsonDocument doc(256);
  doc["status"] = status;
  doc["from"] = "sensor";  // Changed from "esp32" to "sensor" for proper API handling
  
  // Enhanced userName handling for occupied status
  if (status == "occupied") {
    if (userName.length() > 0) {
      doc["userName"] = userName;
    } else if (selectedSlot == slot) {
      doc["userName"] = reservedUserName.length() > 0 ? reservedUserName : "reserved_user";
    } else {
      doc["userName"] = "unauthorized_user";
      Serial.printf("[ALERT] Unauthorized parking detected in %s\n", slot.c_str());
    }
  }
  
  String payload;
  serializeJson(doc, payload);
  
  HTTPClient http;
  http.begin(String(API_BASE) + "/api/slots/" + String(slotNum));
  http.addHeader("Content-Type", "application/json");
  http.addHeader("x-api-key", API_KEY);
  
  int resp = http.PUT(payload);
  
  if (resp == 200) {
    serverState[slotNum] = status;
    lastStateUpdate[slotNum] = millis();
    Serial.printf("[INFO] Slot %s status updated to %s\n", slot.c_str(), status.c_str());
  } else if (resp == 409 && status == "occupied") {
    Serial.printf("[WARN] Slot %s already occupied on server - syncing local state\n", slot.c_str());
    serverState[slotNum] = "occupied";  // Sync our local state
  } else {
    Serial.printf("[ERROR] Failed to update slot %s status: HTTP %d\n", slot.c_str(), resp);
    
    if (resp == 401) {
      Serial.println("[ERROR] Unauthorized - check API key");
    } else if (resp == 403) {
      Serial.println("[ERROR] Forbidden - slot may be reserved by another user");
    }
  }
  
  http.end();
}