import os
import time
import requests

RPS_THRESHOLD = 50
MAX_REPLICAS = 3
MIN_REPLICAS = 1
COOLDOWN_PERIOD = 30 

last_total_requests = 0
last_scale_time = 0
current_scale = MIN_REPLICAS

def get_rps():
    global last_total_requests
    try:
        resp = requests.get("http://localhost/nginx_status")
        total = int(resp.text.splitlines()[2].split()[2])
        if last_total_requests == 0:
            last_total_requests = total
            return 0
        rps = (total - last_total_requests) / 2
        last_total_requests = total
        return rps
    except: return 0

while True:
    rps = get_rps()
    now = time.time()
    print(f"Traffic: {rps:.2f} RPS | Current Scale: {current_scale}")

    if rps > RPS_THRESHOLD and current_scale < MAX_REPLICAS:
        print("!!! High Traffic Detected - Scaling Up !!!")
        os.system(f"docker compose up -d --no-recreate --scale website1={MAX_REPLICAS} --scale website2={MAX_REPLICAS} --scale website3={MAX_REPLICAS}")
        current_scale = MAX_REPLICAS
        last_scale_time = now

    elif rps < (RPS_THRESHOLD / 2) and current_scale > MIN_REPLICAS:
        
        if now - last_scale_time > COOLDOWN_PERIOD:
            print("--- Traffic Eased - Scaling Down ---")
            os.system(f"docker compose up -d --no-recreate --scale website1={MIN_REPLICAS} --scale website2={MIN_REPLICAS} --scale website3={MIN_REPLICAS}")
            current_scale = MIN_REPLICAS
        else:
            print(f"Waiting for Cooldown... ({int(COOLDOWN_PERIOD - (now - last_scale_time))}s left)")

    time.sleep(2)
