# Docker Load Balancing + Auto Scaling

## 🚀 Project Summary

`Docker_Load_Balancing_Auto_Scaling` is a local/demo framework that demonstrates containerized load balancing, traffic generation, metrics collection, and autoscaling behavior using Docker Compose and Python scripting.

Key capabilities:
- Nginx reverse proxy load balancer
- Multiple static backend websites
- Asynchronous traffic generator
- Python autoscaler
- Prometheus scrape config (optional)
- Azure scripts for cloud-oriented orchestration

---

## 📁 Repository Structure

- `load.sh` - local shell traffic generator for Nginx endpoint
- `README.md` - this file

### `Azure_Misc/`
- `autoscale.sh` - Azure CLI autoscale workflow helper
- `traffic.sh` - Azure load generation helper

### `docker_load_balancer/`
- `docker-compose.yml` - core docker stack
- `prometheus.yml` - Prometheus job targets
- `autoscale.py` - Python autoscaler (original)
- `new_autoscale.py` - new/improved autoscaler variant
- `traffic.py` - Python load generator
- `logs/` - logs directory (runtime output)
- `nginx-lb/nginx.conf` - Nginx load balancer configuration
- `website1/index.html`, `website2/index.html`, `website3/index.html` - sample backends

---

## 🧩 Component Details

### 1. Nginx Load Balancer
- Configured in `docker_load_balancer/nginx-lb/nginx.conf`.
- Balances between `website1`, `website2`, `website3`.
- Exposes HTTP port 80 (host → container).
- May expose status endpoint like `/nginx_status` for metrics.

### 2. Static Backend Websites
- `website1`, `website2`, `website3` each serve their own `index.html`.
- Simple content for validating load balancing behavior.

### 3. Autoscaling Logic
- `docker_load_balancer/autoscale.py`: watches metrics (likely nginx_status or request rates) and scales services.
- `docker_load_balancer/new_autoscale.py`: newer autoscale logic; inspect to choose which to run.
- Targets scaling boundaries (min 1, max 3, or configurable in script).

### 4. Load Generation
- `docker_load_balancer/traffic.py`: generates traffic internally via HTTP requests.
- `load.sh`: wrapper script for directed stress tests.
- `Azure_Misc/traffic.sh`: Azure environment traffic helper.

### 5. Monitoring
- `prometheus.yml`: local Prometheus scrape config for endpoints (Nginx/stats exporters).
- Optional integration with GoAccess / Glances from older design notes.

---

## 🔧 Prerequisites

- Docker 20.10+
- Docker Compose v2+ (or Docker Compose plugin) 
- Python 3.8+
- Optional: `curl`, `ab` (ApacheBench) for load tests

---

## ▶️ Quick Start (Local)

1. Clone repository:

```bash
git clone https://github.com/simar022/Docker_Load_Balancing_Auto_Scaling.git
cd Docker_Load_Balancing_Auto_Scaling/docker_load_balancer
```

2. Start stack:

```bash
docker compose up -d
```

3. Confirm services:

```bash
docker compose ps
```

4. Check Nginx in browser or curl:

```bash
curl http://localhost/
```

5. View Nginx status (if configured):

```bash
curl http://localhost/nginx_status
```

6. Generate traffic:

```bash
cd ..
bash load.sh
# or
python3 docker_load_balancer/traffic.py
```

7. Run autoscaler:

```bash
python3 docker_load_balancer/autoscale.py
# or
python3 docker_load_balancer/new_autoscale.py
```

8. Watch scaling:

```bash
watch -n 2 docker compose ps
docker compose logs -f autoscale
```

---

## 🧪 Validation and Testing

- Validate load balancing by hitting root endpoint repeatedly; backends should alternate.
- Use `ab` (ApacheBench) for load tests:

```bash
ab -n 2000 -c 100 http://localhost/
```

- Verify autoscaler adjusts container counts.

- Confirm Prometheus metrics if running a monitoring stack.

---

## ☁️ Azure Notes

- `Azure_Misc/autoscale.sh` / `Azure_Misc/traffic.sh` are entry points for Azure CLI workflows.
- Running in Azure likely requires setting subscription/resource group and permissions.

---

## 💡 Improvements

- Add `docker-compose.override.yml` with scaled replica topology
- Provide a `Makefile` for common commands: `make up`, `make down`, `make test`
- Document exact metric thresholds in autoscale scripts
- Add architecture diagram (Mermaid or PNG) for visual clarity

---

## 🙋‍♂️ Who should use this

- Developers learning Docker + Nginx reverse proxy
- SREs experimenting with container autoscaling patterns
- Students building infrastructure automation demos
