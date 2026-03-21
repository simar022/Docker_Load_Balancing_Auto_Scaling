#!/bin/bash
read -r -d '' Website1 <<'EOF'
<!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>CloudSync SaaS</title>
        <script src="https://cdn.tailwindcss.com"></script>
    </head>
    <body class="bg-slate-50 font-sans">
        <nav class="p-6 bg-white shadow-sm flex justify-between items-center">
        <div class="text-2xl font-bold text-blue-600">CloudSync</div>
        <div class="space-x-6 text-gray-600">
            <a href="#">Features</a><a href="#">Pricing</a>
            <button class="bg-blue-600 text-white px-4 py-2 rounded-lg">Get Started</button>
        </div>
        </nav>
        <header class="py-20 text-center">
        <h1 class="text-6xl font-extrabold text-slate-900 mb-4">Master your workflow.</h1>
        <p class="text-xl text-slate-600 mb-8">The all-in-one platform for modern teams.</p>
        <div class="flex justify-center gap-4">
            <div class="p-8 bg-white shadow-xl rounded-2xl w-64 border-t-4 border-blue-500">
                <h3 class="font-bold">Fast Delivery</h3>
                <p class="text-sm text-gray-500">Global edge network distribution.</p>
            </div>
            <div class="p-8 bg-white shadow-xl rounded-2xl w-64 border-t-4 border-blue-500">
                <h3 class="font-bold">Secure Data</h3>
                <p class="text-sm text-gray-500">AES-256 bank-grade encryption.</p>
            </div>
        </div>
        </header>
        <footer class="mt-10 p-4 bg-blue-600 text-white text-center">Website 1 - Balanced by Nginx</footer>
    </body>
    </html>
EOF
read -r -d '' Website2 <<'EOF'
<!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Visuals by Alex</title>
        <style>
        body { background: #0a0a0a; color: #fff; font-family: 'Inter', sans-serif; margin: 0; }
        .hero { height: 80vh; display: flex; flex-direction: column; justify-content: center; 
        align-items: center; border: 20px solid #1a1a1a; }
        h1 { font-size: 5rem; letter-spacing: -2px; margin: 0; color: #d4af37; }
        .grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; padding: 20px; }
        .box { background: #1a1a1a; height: 200px; transition: 0.3s; cursor: pointer; }
        .box:hover { background: #d4af37; }
        footer { padding: 20px; text-align: center; color: #444; text-transform: uppercase; letter-spacing: 2px; }
        </style>
    </head>
    <body>
        <div class="hero">
        <p>CREATIVE DIRECTOR</p>
        <h1>ALEX RIVERA</h1>
        <p>STORYTELLING THROUGH PIXELS</p>
        </div>
        <div class="grid">
        <div class="box"></div><div class="box"></div><div class="box"></div>
        </div>
        <footer>Website 2 - Luxury Node - Nginx Priority</footer>
    </body>
    </html>
EOF
read -r -d '' Website3 <<'EOF'
<!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Apex Consulting</title>
        <script src="https://cdn.tailwindcss.com"></script>
    </head>
    <body class="bg-gray-100">
        <div class="w-full h-2 bg-emerald-500"></div>
        <div class="max-w-5xl mx-auto py-12 px-6">
        <div class="flex justify-between items-end mb-12">
            <div>
                <h1 class="text-4xl font-serif font-bold text-gray-800 uppercase">Apex Consulting</h1>
                <p class="text-emerald-600 font-bold italic">Strategy. Growth. Results.</p>
            </div>
            <div class="text-right text-sm text-gray-500">Est. 1998</div>
        </div>
        <div class="grid grid-cols-3 gap-8">
            <div class="col-span-2 space-y-6">
                <div class="bg-white p-8 rounded shadow-sm">
                    <h2 class="text-2xl font-bold mb-4">Our Mission</h2>
                    <p class="text-gray-600 leading-relaxed">To provide market-leading financial advice 
                    to global enterprises through data-driven analysis and expert local knowledge.</p>
                </div>
            </div>
            <div class="bg-gray-800 p-8 text-white rounded">
                <h2 class="text-xl font-bold mb-4">Contact Us</h2>
                <p class="text-gray-400 text-sm">100 Wall Street, NY<br>contact@apex.com</p>
            </div>
        </div>
        </div>
        <footer class="mt-20 border-t p-8 text-center text-gray-400">Website 3 - Enterprise Instance</footer>
    </body>
    </html>
EOF

if [ ! -w "." ]; then
    echo "Error: You do not have write permissions in this directory."
    exit 1
fi

echo "Checking for Docker..."
sleep 2
if ! [ -x "$(command -v docker)" ]; then
  echo "Installing Docker..."
  sudo apt-get update
  sudo apt-get install -y docker.io docker-compose
  sudo systemctl start docker
  sudo systemctl enable docker
fi
echo "Docker found in the system, proceeding further !"
sleep 2
echo "System cleanup and health check..."

docker compose down --remove-orphans 2>/dev/null
docker network rm lb_network 2>/dev/null || true

force_cleanup() {
    local name=$1
    if [ "$(docker ps -aq -f name=$name)" ]; then
        echo "Cleaning up existing container: $name..."
        docker rm -f $name 2>/dev/null
    fi
}

if [ -f "docker-compose.yml" ]; then
    docker compose down 2>/dev/null
fi

force_cleanup "nginx-lb"
force_cleanup "glances"
force_cleanup "prometheus"
force_cleanup "grafana"
force_cleanup "nginx-exporter"

sleep 2
echo "Creating project directory..."
PROJECT_DIR="docker_load_balancer"
mkdir -p $PROJECT_DIR/nginx-lb
cd $PROJECT_DIR
sleep 2
echo "Writing static websites..."
mkdir -p website1 website2 website3
echo "$Website1" > website1/index.html
echo "$Website2" > website2/index.html
echo "$Website3" > website3/index.html
sleep 2
echo "Writing Nginx configuration file..."
cat <<'EOF' > nginx-lb/nginx.conf
events { worker_connections 1024; }
http {
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$upstream_addr"';
    access_log /var/log/nginx/access.log main;
    upstream static_sites {
        server website1:80 max_fails=3 fail_timeout=10s weight=3;
        server website2:80 max_fails=3 fail_timeout=10s weight=1;
        server website3:80 max_fails=3 fail_timeout=10s weight=1;
    }
    server {
       listen 80;
       
       location / {
          proxy_pass http://static_sites;
          proxy_next_upstream error timeout http_500 http_502 http_503 http_504;
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header Connection "";
          keepalive_timeout 60;
          add_header Cache-Control "no-store, no-cache, must-revalidate, max-age=0";
          expires off;
       }

       location /system/ {
            proxy_pass http://glances:61208/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            sub_filter_once off;
            sub_filter 'src="' 'src="/system/';
            sub_filter 'href="' 'href="/system/';
       }
       
       location /grafana/ {
           proxy_pass http://grafana:3000; 
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection "upgrade";
       }

       location /static/ {
            proxy_pass http://glances:61208/static/;
       }

       location /nginx_status { stub_status; }
    }
}
EOF
sleep 2
echo "Writing Docker compose file..."

cat <<EOF > docker-compose.yml
services:
  website1:
    image: nginx:alpine
    volumes:
      - ./website1:/usr/share/nginx/html:ro
    networks:
      - lb_network
  website2:
    image: nginx:alpine
    volumes:
      - ./website2:/usr/share/nginx/html:ro
    networks:
      - lb_network
  website3:
    image: nginx:alpine
    volumes:
      - ./website3:/usr/share/nginx/html:ro
    networks:
      - lb_network

  lb:
    image: nginx:alpine
    container_name: nginx-lb
    ports:
      - "80:80"
    volumes:
      - ./nginx-lb/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./logs:/var/log/nginx
    networks:
      - lb_network
    depends_on:
      - website1
      - website2
      - website3

  glances:
    image: nicolargo/glances:latest-full
    container_name: glances
    pid: host
    volumes: ["/var/run/docker.sock:/var/run/docker.sock:ro"]
    environment: ["GLANCES_OPT=-w"]
    networks:
      - lb_network
    
  nginx-exporter:
    image: nginx/nginx-prometheus-exporter:latest
    container_name: nginx-exporter
    networks:
      - lb_network
    command:
      - -nginx.scrape-uri=http://nginx-lb/nginx_status
    ports:
      - "9113:9113"
    depends_on:
      - lb

  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    networks:
      - lb_network
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    networks:
      - lb_network
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_SERVER_DOMAIN=localhost 
      - GF_SERVER_ROOT_URL=http://localhost/grafana/
      - GF_SERVER_SERVE_FROM_SUB_PATH=true
      
networks:
  lb_network:
    driver: bridge
    enable_ipv6: false
EOF

cat <<EOF > prometheus.yml
global:
  scrape_interval: 5s

scrape_configs:
  - job_name: 'nginx'
    static_configs:
      - targets: ['nginx-exporter:9113']
EOF
sleep 2
echo "Starting containers..."
docker compose up -d
sleep 2
echo "----------------------------------------------------------------------------------------------"
sleep 2
echo "Setting up auto-scaling..."
cat <<EOF > autoscale.py
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
EOF

#python3 autoscale.py > autoscale.log 2>&1 &

cat <<EOF > new_autoscale.py
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
EOF

python3 new_autoscale.py > new_autoscale.log 2>&1 &
sleep 2
echo "Creating traffic monitoring dashboard..."
cat <<EOF > traffic.py
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
EOF
sleep 2
echo "Setup complete !"
sleep 2
echo "Access website at http://localhost/"
sleep 2
echo "Access container scaling statistics at http://localhost/system/"
sleep 2
echo "Access nginx stub status at http://localhost/nginx_status/"
sleep 2
echo "Access Grafana dashboard at http://localhost/grafana/"
sleep 2
echo "Sending traffic on http://localhost/"
sleep 2
echo "----------------------------------------------------------------------------------------------"
sleep 20
python3 traffic.py > traffic.log 2>&1 &
watch -n 1 'echo "--- CONTAINER RESOURCE USAGE ---"; \
docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.CPUPerc}}"; \
echo "\n--- LOAD BALANCER TRAFFIC STATS ---"; \
curl -s localhost/nginx_status' > stats.log 2>&1 &
