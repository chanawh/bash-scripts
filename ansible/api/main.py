from fastapi import FastAPI
from pathlib import Path
from typing import Dict, List, Any
import re
import subprocess

app = FastAPI()

INVENTORY_PATH = "/opt/fastapi-topology/ansible-hosts3"

def parse_ansible_inventory(path: str) -> Dict[str, List[str]]:
    result = {}
    current_group = None
    group_re = re.compile(r'^\[(.+)\]')
    if not Path(path).exists():
        return result
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            match = group_re.match(line)
            if match:
                current_group = match.group(1)
                result[current_group] = []
            elif current_group:
                # Only take the host/IP (ignore ansible_user, etc.)
                host = line.split()[0]
                result[current_group].append(host)
    return result

def get_host_status(host: str) -> str:
    """Ping the host to determine if it's up."""
    try:
        result = subprocess.run(
            ["ping", "-c", "1", "-W", "1", host],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        if result.returncode == 0:
            return "healthy"
        else:
            return "down"
    except Exception:
        return "down"


def estimate_latency(from_host: str, to_host: str) -> float:
    """Ping to_host from the API server and get latency in ms (float, real ms)."""
    try:
        result = subprocess.run(
            ["ping", "-c", "1", "-W", "1", to_host],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        if result.returncode == 0:
            # Look for 'time=0.013 ms' or similar
            match = re.search(r'time[=<]([\d\.]+)', result.stdout)
            if match:
                ms = float(match.group(1))
                return ms  # real ms, e.g. 0.013
        return -1  # -1 means unreachable or failed
    except Exception:
        return -1

def get_link_type(from_group: str, to_group: str) -> str:
    if from_group == "web" and to_group == "db":
        return "database"
    elif from_group == "dns" and to_group == "web":
        return "network"
    elif from_group == "dns" and to_group == "db":
        return "network"
    else:
        return "unknown"

@app.get("/topology")
def topology():
    groups = parse_ansible_inventory(INVENTORY_PATH)
    servers = []
    links = []
    for group, hosts in groups.items():
        for host in hosts:
            servers.append({
                "hostname": host,
                "role": group
            })
    group_pairs = [
        ("dns", "web"),
        ("web", "db"),
        ("dns", "db")
    ]
    for from_group, to_group in group_pairs:
        if from_group in groups and to_group in groups:
            for from_host in groups[from_group]:
                for to_host in groups[to_group]:
                    links.append({
                        "from": from_host,
                        "to": to_host,
                        "type": get_link_type(from_group, to_group)
                    })
    return {
        "servers": servers,
        "links": links,
        "groups": groups
    }

@app.get("/topology/details")
def topology_details():
    groups = parse_ansible_inventory(INVENTORY_PATH)
    servers = []
    for group, hosts in groups.items():
        for host in hosts:
            status = get_host_status(host)
            servers.append({
                "hostname": host,
                "role": group,
                "status": status
            })
    # Build a status lookup
    status_map = {s["hostname"]: s["status"] for s in servers}
    links = []
    group_pairs = [
        ("dns", "web"),
        ("web", "db"),
        ("dns", "db")
    ]
    for from_group, to_group in group_pairs:
        if from_group in groups and to_group in groups:
            for from_host in groups[from_group]:
                for to_host in groups[to_group]:
                    if status_map.get(from_host) == "healthy" and status_map.get(to_host) == "healthy":
                        latency = estimate_latency(from_host, to_host)
                        links.append({
                            "from": from_host,
                            "to": to_host,
                            "type": get_link_type(from_group, to_group),
                            "latency_ms": latency
                        })
    return {
        "servers": servers,
        "links": links
    }
