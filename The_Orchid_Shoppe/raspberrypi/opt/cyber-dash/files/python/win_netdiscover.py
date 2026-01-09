import subprocess
import ipaddress
import platform
from concurrent.futures import ThreadPoolExecuter

def ping(ip):
# Cont. writting this out
    param = "-n" if platform.system().lower() == "windows" else "-c"
    try:
        subprocess.run(
            ["ping", param, "1", "-w", "500", str(ip)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
    except Exception:
        pass

def is_valid_host(ip, mac):
    try:
        ip_obj = ipaddress.ip_address(ip)

        # Remove multicast
        if ip_obj.is_multicast:
            return False

        # Remove broadcast
        if ip == "255.255.255.255" or ip.endswith(".255"):
            return False

        # Remove broadcast MAC
        if mac.lower() == "ff-ff-ff-ff-ff-ff":
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
# Next work on parsing the IP address. 
if __name__ == "__main__":
    discover("0.0.0.0/24")
