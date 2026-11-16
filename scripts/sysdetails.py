#!/usr/bin/env python3
"""Print one JSON line every 2 s with CPU (P/E cores), memory and GPU memory details.

Used by modules/dashboard/performance/DetailsCard.qml. Run with --once for a single line.
"""
import json
import subprocess
import sys
import time
from pathlib import Path

CPU = Path("/sys/devices/system/cpu")


def parse_cpus(text: str) -> list[int]:
    """'0-3,8' -> [0, 1, 2, 3, 8]"""
    cpus = []
    for part in text.strip().split(","):
        if part:
            first, _, last = part.partition("-")
            cpus += range(int(first), int(last or first) + 1)
    return cpus


def groups() -> dict[str, list[int]]:
    """Hybrid Intel CPUs list their P and E cores in sysfs; everything else is one group."""
    found = {}
    for key, pmu in (("p", "cpu_core"), ("e", "cpu_atom")):
        try:
            found[key] = parse_cpus(Path(f"/sys/devices/{pmu}/cpus").read_text())
        except OSError:
            pass
    return found or {"all": parse_cpus((CPU / "online").read_text())}


def cpu_times() -> dict[int, tuple[int, int]]:
    """cpu number -> (busy, total) jiffies"""
    times = {}
    for line in Path("/proc/stat").read_text().splitlines():
        name, *fields = line.split()
        if name.startswith("cpu") and name[3:].isdigit():
            values = [int(v) for v in fields[:8]]
            idle = values[3] + values[4]
            times[int(name[3:])] = (sum(values) - idle, sum(values))
    return times


def read_int(path: Path) -> int:
    try:
        return int(path.read_text())
    except (OSError, ValueError):
        return 0


def memory() -> dict[str, int]:
    info = {}
    for line in Path("/proc/meminfo").read_text().splitlines():
        key, value = line.split(":")
        info[key] = int(value.split()[0])
    return {
        "total": info["MemTotal"],
        "used": info["MemTotal"] - info["MemAvailable"],
        "cached": info.get("Cached", 0) + info.get("SReclaimable", 0),
        "swapTotal": info["SwapTotal"],
        "swapUsed": info["SwapTotal"] - info["SwapFree"],
    }


def gpu() -> dict[str, float] | None:
    try:
        out = subprocess.run(
            ["nvidia-smi", "--query-gpu=memory.used,memory.total,utilization.gpu,power.draw,temperature.gpu",
             "--format=csv,noheader,nounits"],
            capture_output=True, text=True, timeout=3, check=True).stdout
        used, total, util, watts, temp = (float(v) for v in out.splitlines()[0].split(","))
    except (OSError, subprocess.SubprocessError, ValueError, IndexError):
        return None
    return {"vramUsed": used, "vramTotal": total, "util": util, "watts": watts, "temp": temp}


def snapshot(before, after, cpu_groups) -> dict:
    data = {"cpu": {}, "load": [float(v) for v in Path("/proc/loadavg").read_text().split()[:3]],
            "mem": memory(), "gpu": gpu()}
    for key, cpus in cpu_groups.items():
        usage = []
        for cpu in cpus:
            busy = after[cpu][0] - before[cpu][0]
            total = after[cpu][1] - before[cpu][1]
            usage.append(round(busy / total, 3) if total > 0 else 0)
        mhz = [read_int(CPU / f"cpu{cpu}/cpufreq/scaling_cur_freq") / 1000 for cpu in cpus]
        cores = {read_int(CPU / f"cpu{cpu}/topology/core_id") for cpu in cpus}
        data["cpu"][key] = {"cores": len(cores), "threads": len(cpus), "usage": usage,
                            "mhz": round(sum(mhz) / len(mhz)), "maxMhz": round(max(mhz))}
    return data


def main() -> None:
    assert parse_cpus("0-3,8\n") == [0, 1, 2, 3, 8] and parse_cpus("5") == [5]
    cpu_groups = groups()
    before = cpu_times()
    while True:
        time.sleep(0.5 if "--once" in sys.argv else 2)
        after = cpu_times()
        print(json.dumps(snapshot(before, after, cpu_groups)), flush=True)
        if "--once" in sys.argv:
            return
        before = after


if __name__ == "__main__":
    main()
