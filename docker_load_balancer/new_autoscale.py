import os
import time
import requests
import psutil 

RPS_THRESHOLD = 500
CPU_THRESHOLD = 70.0  
RAM_THRESHOLD = 80.0  

MAX_REPLICAS = 4
MIN_REPLICAS = 1
COOLDOWN_PERIOD = 30 

last_total_requests = 0
last_scale_time = 0
current_scale = MIN_REPLICAS

def get_rps():
    global last_total_requests
    try:
        resp = requests.get("http://localhost/nginx_status", timeout=1)
        total = int(resp.text.splitlines()[2].split()[2])
        if last_total_requests == 0:
            last_total_requests = total
            return 0
        rps = (total - last_total_requests) / 2 
        last_total_requests = total
        return rps
    except Exception as e:
        print(f"Error fetching RPS: {e}")
        return 0

def get_system_metrics():
    cpu = psutil.cpu_percent(interval=None)
    ram = psutil.virtual_memory().percent
    return cpu, ram

def scale(replicas):
    global current_scale, last_scale_time
    print(f"Executing Scale to {replicas}...")
    cmd = (f"docker compose up -d --no-recreate "
           f"--scale website1={replicas} "
           f"--scale website2={replicas} "
           f"--scale website3={replicas}")
    os.system(cmd)
    current_scale = replicas
    last_scale_time = time.time()

print("--- Multi-Metric Autoscaler Started ---")

while True:
    rps = get_rps()
    cpu, ram = get_system_metrics()
    now = time.time()

    print(f"Stats -> RPS: {rps:.1f} | CPU: {cpu}% | RAM: {ram}% | Replicas: {current_scale}")

    should_scale_up = (
        rps > RPS_THRESHOLD or 
        cpu > CPU_THRESHOLD or 
        ram > RAM_THRESHOLD
    )

    should_scale_down = (
        rps < (RPS_THRESHOLD / 2) and 
        cpu < (CPU_THRESHOLD - 20) and 
        ram < (RAM_THRESHOLD - 10)
    )

    if should_scale_up and current_scale < MAX_REPLICAS:
        print("!!! High Load Detected (RPS/CPU/RAM) - Scaling Up !!!")
        scale(MAX_REPLICAS)

    elif should_scale_down and current_scale > MIN_REPLICAS:
        if now - last_scale_time > COOLDOWN_PERIOD:
            print("--- Environment Stable - Scaling Down ---")
            scale(MIN_REPLICAS)
        else:
            cooldown_left = int(COOLDOWN_PERIOD - (now - last_scale_time))
            print(f"Waiting for Cooldown... ({cooldown_left}s left)")

    time.sleep(2)
