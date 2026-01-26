import network
import time
import urequests
import json
import ntptime
from machine import ADC, Pin
import secrets
import rp2
import gc

# --- config
WIFI_SSID = secrets.WIFI_SSID
WIFI_PASS = secrets.WIFI_PASS

PROJECT_ID = secrets.PROJECT_ID
USER_UID = secrets.USER_UID

TZ_OFFSET = 2
rp2.country('RO')

# sensor config
SENSOR_PIN = 26
TEMP_PIN = 27
PUMP_RELAY_PIN = 16 
FAN_RELAY_PIN = 17   

DRY_VAL = 44186
WET_VAL = 17252

adc = ADC(Pin(SENSOR_PIN))
adc_temp = ADC(Pin(TEMP_PIN))
led = Pin("LED", Pin.OUT)

pump_relay = Pin(PUMP_RELAY_PIN, Pin.IN)
fan_relay = Pin(FAN_RELAY_PIN, Pin.IN)

def pump_on():
    pump_relay.init(mode=Pin.OUT)
    pump_relay.value(0)
    print(">>> PUMP ON")

def pump_off():
    pump_relay.init(mode=Pin.IN)
    print(">>> PUMP OFF")

def fan_on():
    fan_relay.init(mode=Pin.OUT)
    fan_relay.value(0)
    print(">>> FAN ON")

def fan_off():
    fan_relay.init(mode=Pin.IN)
    print(">>> FAN OFF")

def connect_wifi():
    rp2.country('RO') 
    wlan = network.WLAN(network.STA_IF)
    wlan.active(True)
    wlan.disconnect()
    
    # disable power saving (fixes dropouts)
    wlan.config(pm=0xa11140) 
    
    print(f"Connecting to {WIFI_SSID}...")
    wlan.connect(WIFI_SSID, WIFI_PASS)
    
    max_wait = 20
    while max_wait > 0:
        if wlan.status() < 0 or wlan.status() >= 3:
            break
        max_wait -= 1
        print(f"Waiting... Status: {wlan.status()}")
        led.toggle()
        time.sleep(1)

    if wlan.status() != 3:
        led.off()
        print("\nConnection Failed!")
        raise RuntimeError('Wi-Fi connection failed')
    else:
        print("\nConnected! IP:", wlan.ifconfig()[0])
        led.on()
        try: ntptime.settime()
        except: pass

def get_humidity_percent():
    raw = adc.read_u16()
    # print(f"RAW HUMIDITY: {raw}")
    if raw >= DRY_VAL: return 0
    elif raw <= WET_VAL: return 100
    else:
        percent = (DRY_VAL - raw) / (DRY_VAL - WET_VAL) * 100
        return round(percent, 1)

def get_temperature():
    calibration_offset = 0

    # 100 readings and average them to smooth out noise
    total_raw = 0
    samples = 100
    
    for _ in range(samples):
        total_raw += adc_temp.read_u16()
        time.sleep_ms(1) # tiny pause to let ADC settle
        
    avg_raw = total_raw // samples
    
    # conversion logic
    voltage = avg_raw * (3.3 / 65535)
    temp_celsius = voltage / 0.01 
    final_temp = temp_celsius - calibration_offset

    return round(final_temp, 1)

def get_hour_string():
    now = time.time() + (TZ_OFFSET * 3600)
    hour = time.localtime(now)[3]
    return str(hour)

def get_unix_timestamp():
    return time.time()

def check_and_clear_command(current_h, current_t):
    gc.collect() 
    
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/users/{USER_UID}"
    res = None 
    try:
        res = urequests.get(url)
        if res.status_code == 200:
            data = res.json()
            res.close()
            res = None 
            gc.collect()

            try:
                fields = data.get('fields', {})
                gh = fields.get('greenhouse', {}).get('mapValue', {}).get('fields', {})
                
                # --- humidity
                humid = gh.get('Humid', {}).get('mapValue', {}).get('fields', {})
                
                manual_water = humid.get('command', {}).get('booleanValue', False)
                auto_water_mode = humid.get('auto', {}).get('stringValue', 'off').lower() == 'on'
                target_humid = int(humid.get('targetHumid', {}).get('integerValue', 30))
                water_interval_sec = int(humid.get('waterTimeInt', {}).get('integerValue', 2)) * 3600
                last_water_ts = int(humid.get('lastWatering', {}).get('integerValue', 0))
                
                now = get_unix_timestamp()
                trigger_water = False

                if manual_water:
                    print("Cmd: Water")
                    trigger_water = True
                elif auto_water_mode:
                    if (current_h < target_humid) and ((now - last_water_ts) > water_interval_sec):
                        print("Auto: Water")
                        trigger_water = True

                if trigger_water:
                    pump_on()
                    time.sleep(1)
                    pump_off()
                    
                    patch_url = f"{url}?updateMask.fieldPaths=greenhouse.Humid.command&updateMask.fieldPaths=greenhouse.Humid.lastWatering"
                    payload = { "fields": { "greenhouse": { "mapValue": { "fields": { "Humid": { "mapValue": { "fields": { 
                        "command": { "booleanValue": False },
                        "lastWatering": { "integerValue": str(now) }
                    }}}}}}}}
                    
                    gc.collect()
                    r = urequests.patch(patch_url, json=payload)
                    r.close()
                    r = None
                    print("DB Updated (Water)")

                # --- temperature
                temp_field = gh.get('Temperature', {}).get('mapValue', {}).get('fields', {})
                
                manual_fan = temp_field.get('command', {}).get('booleanValue', False)
                auto_fan_mode = temp_field.get('auto', {}).get('stringValue', 'off').lower() == 'on'
                target_temp = int(temp_field.get('targetTemp', {}).get('integerValue', 25))
                fan_interval_sec = int(temp_field.get('fanTimeInt', {}).get('integerValue', 2)) * 3600
                last_fan_ts = int(temp_field.get('lastFanning', {}).get('integerValue', 0))

                trigger_fan = False

                if manual_fan:
                    print("Cmd: Fan")
                    trigger_fan = True
                elif auto_fan_mode:
                    if (current_t > target_temp) and ((now - last_fan_ts) > fan_interval_sec):
                        print("Auto: Fan")
                        trigger_fan = True

                if trigger_fan:
                    fan_on()
                    time.sleep(3)
                    fan_off()

                    patch_url = f"{url}?updateMask.fieldPaths=greenhouse.Temperature.command&updateMask.fieldPaths=greenhouse.Temperature.lastFanning"
                    payload = { "fields": { "greenhouse": { "mapValue": { "fields": { "Temperature": { "mapValue": { "fields": { 
                        "command": { "booleanValue": False },
                        "lastFanning": { "integerValue": str(now) }
                    }}}}}}}}
                    
                    gc.collect()
                    r = urequests.patch(patch_url, json=payload)
                    r.close()
                    r = None
                    print("DB Updated (Fan)")

            except Exception as e:
                print("Logic Error:", e)
        
        if res: res.close()
            
    except Exception as e:
        print("Network Error (Check):", e)
        if res: res.close()

last_history_hour = -1

def update_live_status(humid_val, temp_val):
    """Updates only the current value (Fast, runs every 3s)"""
    gc.collect()
    
    masks = [
        "greenhouse.Humid.value",
        "greenhouse.Temperature.value"
    ]
    mask_query = "&".join([f"updateMask.fieldPaths={m}" for m in masks])
    
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/users/{USER_UID}?{mask_query}"
    
    greenhouse_data = {
        "Humid": { 
            "mapValue": { "fields": { "value": { "doubleValue": humid_val } } } 
        },
        "Temperature": { 
            "mapValue": { "fields": { "value": { "doubleValue": temp_val } } } 
        }
    }
    
    payload = { "fields": { "greenhouse": { "mapValue": { "fields": greenhouse_data } } } }

    res = None
    try:
        res = urequests.patch(url, json=payload)
        res.close()
        print(f"Live Update: {humid_val}% | {temp_val}C")
    except Exception as e:
        print("Network Error (Live):", e)
        if res: res.close()

def log_history(humid_val, temp_val):
    """Updates the history chart (Slow, runs once per hour)"""
    gc.collect()
    
    hour_key = get_hour_string()
    print(f"Logging History for Hour: {hour_key}...")

    mask_query = f"updateMask.fieldPaths=greenhouse.history.`{hour_key}`"
    
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/users/{USER_UID}?{mask_query}"
    
    history_entry = {
        "mapValue": {
            "fields": {
                "humid": { "doubleValue": humid_val },
                "temp":  { "doubleValue": temp_val }
            }
        }
    }

    payload = {
        "fields": {
            "greenhouse": {
                "mapValue": {
                    "fields": {
                        "history": {
                            "mapValue": {
                                "fields": {
                                    hour_key: history_entry
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    res = None
    try:
        res = urequests.patch(url, json=payload)
        res.close()
        print(f"History Saved for Hour {hour_key}")
        return True
    except Exception as e:
        print("Network Error (History):", e)
        if res: res.close()
        return False

# -- main loop
connect_wifi()
print("Starting Loop...")
pump_off()
fan_off()

while True:
    h = get_humidity_percent()
    t = get_temperature()
    current_hour_str = get_hour_string()
    
    check_and_clear_command(h, t)

    update_live_status(h, t)
    
    # check if we need to log history (once per new hour)
    if current_hour_str != last_history_hour:
        if log_history(h, t):
            last_history_hour = current_hour_str
    
    gc.collect()
    time.sleep(3)