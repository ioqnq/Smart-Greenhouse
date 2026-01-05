import network
import time
import urequests
import json
import ntptime
from machine import ADC, Pin
import secrets

# --- config
WIFI_SSID = secrets.WIFI_SSID
WIFI_PASS = secrets.WIFI_PASS
PROJECT_ID = secrets.PROJECT_ID
USER_UID = secrets.USER_UID
TZ_OFFSET = 3

# sensor config
SENSOR_PIN = 26
TEMP_PIN = 27
RELAY_PIN = 16
DRY_VAL = 65535
WET_VAL = 20000

adc = ADC(Pin(SENSOR_PIN))
adc_temp = ADC(Pin(TEMP_PIN))
led = Pin("LED", Pin.OUT)

relay = Pin(RELAY_PIN, Pin.IN)

def relay_on():
    """Turn Relay ON (Active LOW)"""
    relay.init(mode=Pin.OUT)
    relay.value(0)
    print(">>> RELAY ON (Watering)")

def relay_off():
    """Turn Relay OFF (High-Z Input)"""
    relay.init(mode=Pin.IN)
    print(">>> RELAY OFF")

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
    try: ntptime.settime()
    except: pass

def get_humidity_percent():
    raw = adc.read_u16()
    if raw >= DRY_VAL: return 0
    elif raw <= WET_VAL: return 100
    else:
        percent = (DRY_VAL - raw) / (DRY_VAL - WET_VAL) * 100
        return round(percent, 1)

def get_temperature():
    raw = adc_temp.read_u16()
    voltage = raw * (3.3 / 65535)
    temp = voltage / 0.01 
    return round(temp, 1)

def get_hour_string():
    now = time.time() + (TZ_OFFSET * 3600)
    hour = time.localtime(now)[3]
    return str(hour)

def check_and_clear_command():
    # read command from db
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/users/{USER_UID}"
    try:
        res = urequests.get(url)
        if res.status_code == 200:
            data = res.json()
            try:
                fields = data.get('fields', {})
                gh = fields.get('greenhouse', {}).get('mapValue', {}).get('fields', {})
                humid = gh.get('Humid', {}).get('mapValue', {}).get('fields', {})
                
                # check value
                should_water = humid.get('command', {}).get('booleanValue', False)
                
                if should_water:
                    relay_on()
                    time.sleep(3)  # water for 3 seconds
                    relay_off()
                    
                    # reset to False
                    patch_url = f"{url}?updateMask.fieldPaths=greenhouse.Humid.command"
                    payload = {
                        "fields": {
                            "greenhouse": {
                                "mapValue": {
                                    "fields": {
                                        "Humid": {
                                            "mapValue": {
                                                "fields": {
                                                    "command": { "booleanValue": False }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    urequests.patch(patch_url, json=payload).close()
                    print("Command reset to False.")
            except Exception as e:
                pass 
        res.close()
    except Exception as e:
        print("Check Command Error:", e)

def update_firestore(humid_val, temp_val):
    hour_key = get_hour_string()
    masks = [
        "greenhouse.Humid.value",
        "greenhouse.Temperature.value",
        f"greenhouse.history.`{hour_key}`.humid",
        f"greenhouse.history.`{hour_key}`.temp"
    ]
    mask_query = "&".join([f"updateMask.fieldPaths={m}" for m in masks])
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/users/{USER_UID}?{mask_query}"
    
    payload = {
        "fields": {
            "greenhouse": {
                "mapValue": {
                    "fields": {
                        "Humid": {
                            "mapValue": {"fields": {"value": { "doubleValue": humid_val }}}
                        },
                        "Temperature": {
                            "mapValue": {"fields": {"value": { "doubleValue": temp_val }}}
                        },
                        "history": {
                            "mapValue": {
                                "fields": {
                                    hour_key: {
                                        "mapValue": {
                                            "fields": {
                                                "humid": { "doubleValue": humid_val },
                                                "temp":  { "doubleValue": temp_val }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    try:
        urequests.patch(url, json=payload).close()
        print(f"Updated DB: {humid_val}% | {temp_val}C")
    except Exception as e:
        print("Network Error:", e)

# -- main loop
connect_wifi()
print("Starting Loop...")

# ensure relay is OFF at start
relay_off()

while True:
    # check if user pressed button
    check_and_clear_command()
    
    # read sensors + update db
    h = get_humidity_percent()
    t = get_temperature()
    update_firestore(h, t)
    
    time.sleep(3)