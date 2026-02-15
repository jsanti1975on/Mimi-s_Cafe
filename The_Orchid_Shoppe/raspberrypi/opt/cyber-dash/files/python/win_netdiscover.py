import subprocess
import ipaddress
import platform
from concurrent.futures import ThreadPoolExecutor

def ping(ip):
    system = platform.system().lower()

    if system == "windows":
        cmd = ["ping", "-n", "1", "-w", "500", str(ip)]
    else:
        cmd = ["ping", "-c", "1", "-W", "1", str(ip)]

    try:
        subprocess.run(
            cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
    except Exception:
        pass

def is_valid_host(ip, mac):
    try:
        ip_obj = ipaddress.ip_address(ip)

        if ip_obj.is_multicast:
            return False

        if ip == "255.255.255.255" or ip.endswith(".255"):
            return False

        if mac.lower() in ["ff-ff-ff-ff-ff-ff", "ff:ff:ff:ff:ff:ff"]:
            return False

        return True

    except ValueError:
        return False

def get_arp_entries():
    output = subprocess.check_output(["arp", "-a"]).decode(errors="ignore")
    hosts = []

    for line in output.splitlines():
        parts = line.split()
        if len(parts) >= 2 and "." in parts[0]:
            ip, mac = parts[0], parts[1]

            if is_valid_host(ip, mac):
                hosts.append((ip, mac))

    return hosts

def discover(subnet):
    net = ipaddress.ip_network(subnet, strict=False)

    print(f"[*] Scanning {subnet} ...")

    with ThreadPoolExecutor(max_workers=100) as executor:
        for ip in net.hosts():
            executor.submit(ping, ip)

    print("\n[*] Live Hosts (ARP Cache):")
    for ip, mac in get_arp_entries():
        print(f"{ip:15} → {mac}")

if __name__ == "__main__":
    discover("10.10.10.10/24")
