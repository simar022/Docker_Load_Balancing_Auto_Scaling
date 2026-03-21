import requests
import time
import threading
import math

TARGET_URL = "http://localhost/"
DURATION = 120  
MAX_WORKERS = 40 

def send_requests(stop_event):
    while not stop_event.is_set():
        try:
            requests.get(TARGET_URL, timeout=1)
        except:
            pass

def traffic_orchestrator():
    start_time = time.time()
    threads = []
    stop_event = threading.Event()

    print("--- Starting Traffic Monitoring ---")
    while time.time() - start_time < DURATION:
        elapsed = time.time() - start_time
        
        target_now = int(MAX_WORKERS * math.sin((elapsed / DURATION) * math.pi))
        target_now = max(1, target_now)

        
        while len(threads) < target_now:
            t = threading.Thread(target=send_requests, args=(stop_event,))
            t.start()
            threads.append(t)
        
        while len(threads) > target_now:
            stop_event.set() 
            threads.pop().join()
            stop_event.clear()

        print(f"Time: {int(elapsed)}s | Active Traffic Workers: {len(threads)}")
        time.sleep(2)

    stop_event.set()
    print("--- Monitoring Ended ---")

if __name__ == "__main__":
    traffic_orchestrator()
