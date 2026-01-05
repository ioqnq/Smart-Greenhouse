import network
import time
import urequests
import json
from machine import ADC, Pin
import secrets

# --- config
WIFI_SSID = secrets.WIFI_SSID
WIFI_PASS = secrets.WIFI_PASS

PROJECT_ID = secrets.PROJECT_ID

USER_UID = secrets.USER_UID

# sensor config (dry and wet vals currently inaccurate)
SENSOR_PIN = 26        # GP26 (ADC0)
TEMP_PIN = 27          # GP27 (ADC1)
DRY_VAL = 65535
WET_VAL = 20000

adc = ADC(Pin(SENSOR_PIN))
adc_temp = ADC(Pin(TEMP_PIN))
led = Pin("LED", Pin.OUT)

def connect_wifi():
    wlan = network.WLAN(network.STA_IF)
    wlan.active(True)
    wlan.connect(WIFI_SSID, WIFI_PASS)
    print("Connecting to WiFi...", end="")
    while not wlan.isconnected():
        led.toggle()
        time.sleep(0.2)
        print(".", end="")
    print("\nConnected! IP:", wlan.ifconfig()[0])
    led.on()

def get_humidity_percent():
    raw = adc.read_u16()

    if raw >= DRY_VAL:
        return 0
    elif raw <= WET_VAL:
        return 100
    else:
        percent = (DRY_VAL - raw) / (DRY_VAL - WET_VAL) * 100
        return round(percent, 1) # 1. decimal

def get_temperature():
    raw = adc_temp.read_u16()
    
    # convert to voltage (3.3V) then to celsius (10mV/C)
    voltage = raw * (3.3 / 65535)
    temp = voltage / 0.01 
    
    return round(temp, 1)

def update_firestore(humid_val, temp_val):
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/users/{USER_UID}?updateMask.fieldPaths=greenhouse.Humid.value&updateMask.fieldPaths=greenhouse.Temperature.value"
    
    payload = {
        "fields": {
            "greenhouse": {
                "mapValue": {
                    "fields": {
                        "Humid": {
                            "mapValue": {
                                "fields": {
                                    "value": { "doubleValue": humid_val }
                                }
                            }
                        },
                        "Temperature": {
                            "mapValue": {
                                "fields": {
                                    "value": { "doubleValue": temp_val }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    try:
        # patch to update existing document
        response = urequests.patch(url, json=payload)
        if response.status_code == 200:
            print(f"Updated DB: {humid_val}% | {temp_val}C")
        else:
            print(f"Error {response.status_code}: {response.text}")
        response.close()
    except Exception as e:
        print("Network Error:", e)

# -- main loop
connect_wifi()

print("Starting Sensor Loop...")
while True:
    current_humid = get_humidity_percent()
    current_temp = get_temperature()
    
    update_firestore(current_humid, current_temp)
    
    time.sleep(3)