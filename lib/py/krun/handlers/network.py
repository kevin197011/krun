"""Network quality checks against public service nodes."""

from __future__ import annotations

import os
import re
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass

from krun.common import has_cmd

# region:ip:desc — nationwide public DNS / service endpoints
TEST_NODES: list[tuple[str, str, str]] = [
    ("北京", "114.114.114.114", "114DNS"),
    ("北京", "223.5.5.5", "阿里DNS"),
    ("北京", "119.29.29.29", "腾讯DNS"),
    ("北京", "180.76.76.76", "百度DNS"),
    ("天津", "114.114.115.115", "114DNS"),
    ("天津", "223.6.6.6", "阿里DNS"),
    ("石家庄", "119.28.28.28", "腾讯DNS"),
    ("石家庄", "8.8.8.8", "GoogleDNS"),
    ("太原", "114.114.114.114", "114DNS"),
    ("太原", "1.1.1.1", "Cloudflare"),
    ("呼和浩特", "223.5.5.5", "阿里DNS"),
    ("呼和浩特", "119.29.29.29", "腾讯DNS"),
    ("沈阳", "114.114.115.115", "114DNS"),
    ("沈阳", "180.76.76.76", "百度DNS"),
    ("大连", "114.114.114.114", "114DNS"),
    ("大连", "223.6.6.6", "阿里DNS"),
    ("长春", "119.28.28.28", "腾讯DNS"),
    ("长春", "8.8.4.4", "GoogleDNS"),
    ("哈尔滨", "114.114.114.114", "114DNS"),
    ("哈尔滨", "223.5.5.5", "阿里DNS"),
    ("上海", "180.76.76.76", "百度DNS"),
    ("上海", "119.29.29.29", "腾讯DNS"),
    ("上海", "114.114.114.114", "114DNS"),
    ("上海", "223.5.5.5", "阿里DNS"),
    ("南京", "114.114.115.115", "114DNS"),
    ("南京", "119.28.28.28", "腾讯DNS"),
    ("杭州", "223.6.6.6", "阿里DNS"),
    ("杭州", "114.114.114.114", "114DNS"),
    ("合肥", "180.76.76.76", "百度DNS"),
    ("合肥", "223.5.5.5", "阿里DNS"),
    ("福州", "119.29.29.29", "腾讯DNS"),
    ("福州", "114.114.115.115", "114DNS"),
    ("厦门", "119.28.28.28", "腾讯DNS"),
    ("厦门", "223.6.6.6", "阿里DNS"),
    ("南昌", "114.114.114.114", "114DNS"),
    ("南昌", "180.76.76.76", "百度DNS"),
    ("济南", "223.5.5.5", "阿里DNS"),
    ("济南", "119.29.29.29", "腾讯DNS"),
    ("青岛", "114.114.115.115", "114DNS"),
    ("青岛", "119.28.28.28", "腾讯DNS"),
    ("苏州", "223.6.6.6", "阿里DNS"),
    ("苏州", "114.114.114.114", "114DNS"),
    ("无锡", "180.76.76.76", "百度DNS"),
    ("无锡", "223.5.5.5", "阿里DNS"),
    ("宁波", "119.29.29.29", "腾讯DNS"),
    ("宁波", "114.114.115.115", "114DNS"),
    ("温州", "119.28.28.28", "腾讯DNS"),
    ("温州", "223.6.6.6", "阿里DNS"),
    ("郑州", "180.76.76.76", "百度DNS"),
    ("郑州", "114.114.114.114", "114DNS"),
    ("武汉", "223.5.5.5", "阿里DNS"),
    ("武汉", "119.29.29.29", "腾讯DNS"),
    ("长沙", "114.114.115.115", "114DNS"),
    ("长沙", "119.28.28.28", "腾讯DNS"),
    ("广州", "1.1.1.1", "Cloudflare"),
    ("广州", "114.114.114.114", "114DNS"),
    ("广州", "223.5.5.5", "阿里DNS"),
    ("广州", "119.29.29.29", "腾讯DNS"),
    ("深圳", "8.8.8.8", "GoogleDNS"),
    ("深圳", "114.114.115.115", "114DNS"),
    ("深圳", "223.6.6.6", "阿里DNS"),
    ("深圳", "180.76.76.76", "百度DNS"),
    ("南宁", "119.28.28.28", "腾讯DNS"),
    ("南宁", "114.114.114.114", "114DNS"),
    ("海口", "223.5.5.5", "阿里DNS"),
    ("海口", "119.29.29.29", "腾讯DNS"),
    ("佛山", "114.114.115.115", "114DNS"),
    ("佛山", "180.76.76.76", "百度DNS"),
    ("东莞", "119.28.28.28", "腾讯DNS"),
    ("东莞", "223.6.6.6", "阿里DNS"),
    ("中山", "114.114.114.114", "114DNS"),
    ("中山", "223.5.5.5", "阿里DNS"),
    ("珠海", "119.29.29.29", "腾讯DNS"),
    ("珠海", "114.114.115.115", "114DNS"),
    ("成都", "114.114.115.115", "114DNS"),
    ("成都", "223.5.5.5", "阿里DNS"),
    ("成都", "119.29.29.29", "腾讯DNS"),
    ("成都", "180.76.76.76", "百度DNS"),
    ("重庆", "119.28.28.28", "腾讯DNS"),
    ("重庆", "114.114.114.114", "114DNS"),
    ("重庆", "223.6.6.6", "阿里DNS"),
    ("贵阳", "114.114.115.115", "114DNS"),
    ("贵阳", "223.5.5.5", "阿里DNS"),
    ("昆明", "119.29.29.29", "腾讯DNS"),
    ("昆明", "180.76.76.76", "百度DNS"),
    ("拉萨", "114.114.114.114", "114DNS"),
    ("拉萨", "119.28.28.28", "腾讯DNS"),
    ("西安", "180.76.76.76", "百度DNS"),
    ("西安", "114.114.114.114", "114DNS"),
    ("西安", "223.5.5.5", "阿里DNS"),
    ("西安", "119.29.29.29", "腾讯DNS"),
    ("兰州", "114.114.115.115", "114DNS"),
    ("兰州", "119.28.28.28", "腾讯DNS"),
    ("西宁", "223.6.6.6", "阿里DNS"),
    ("西宁", "114.114.114.114", "114DNS"),
    ("银川", "180.76.76.76", "百度DNS"),
    ("银川", "223.5.5.5", "阿里DNS"),
    ("乌鲁木齐", "119.29.29.29", "腾讯DNS"),
    ("乌鲁木齐", "114.114.115.115", "114DNS"),
]


@dataclass
class NodeResult:
    region: str
    ip: str
    desc: str
    ok: bool
    latency_ms: float | None  # None = timeout


def _parse_targets() -> list[tuple[str, str, str]]:
    """IP_TARGETS=地区:IP:描述,... 覆盖默认节点；仅 IP 则用自定义标签。"""
    raw = os.environ.get("IP_TARGETS", "").strip()
    if not raw:
        return TEST_NODES
    nodes: list[tuple[str, str, str]] = []
    for item in raw.split(","):
        item = item.strip()
        if not item:
            continue
        parts = item.split(":")
        if len(parts) >= 3:
            nodes.append((parts[0], parts[1], parts[2]))
        else:
            nodes.append(("自定义", parts[0], "custom"))
    return nodes or TEST_NODES


def _ping_avg(ip: str, count: int = 4, timeout: int = 3) -> float | None:
    import subprocess

    if sys.platform == "darwin":
        cmd = ["ping", "-c", str(count), "-W", str(timeout * 1000), ip]
    else:
        cmd = ["ping", "-c", str(count), "-W", str(timeout), ip]
    proc = subprocess.run(cmd, capture_output=True, text=True, check=False)
    for line in proc.stdout.splitlines():
        if "avg" not in line:
            continue
        m = re.search(r"= ([\d.]+)/([\d.]+)/", line)
        if m:
            return float(m.group(2))
    return None


def _test_node(region: str, ip: str, desc: str) -> NodeResult:
    count = int(os.environ.get("PING_COUNT", "4"))
    timeout = int(os.environ.get("PING_TIMEOUT", "3"))
    latency = _ping_avg(ip, count, timeout)
    return NodeResult(region, ip, desc, latency is not None, latency)


def _grade_latency(ms: float) -> str:
    if ms < 50:
        return "excellent"
    if ms < 100:
        return "good"
    if ms < 200:
        return "fair"
    return "poor"


def _print_report(results: list[NodeResult]) -> None:
    total = len(results)
    success = sum(1 for r in results if r.ok)
    latencies = [r.latency_ms for r in results if r.latency_ms is not None]
    timeouts = total - len(latencies)

    buckets = {"excellent": 0, "good": 0, "fair": 0, "poor": 0}
    for ms in latencies:
        buckets[_grade_latency(ms)] += 1

    avg = sum(latencies) / len(latencies) if latencies else None
    success_rate = success * 100 // total if total else 0

    # regional success rate
    region_stats: dict[str, list[bool]] = {}
    for r in results:
        region_stats.setdefault(r.region, []).append(r.ok)

    region_count = len(region_stats)
    ex_reg = gd_reg = fr_reg = pr_reg = 0
    for oks in region_stats.values():
        rate = sum(oks) * 100 // len(oks)
        if rate >= 90:
            ex_reg += 1
        elif rate >= 70:
            gd_reg += 1
        elif rate >= 50:
            fr_reg += 1
        else:
            pr_reg += 1

    print("==========================================")
    print("网络质量评估报告")
    print("==========================================")
    print()

    print("【连通性评估】")
    if success_rate >= 95:
        print(f"  等级: 优秀 ({success_rate}%)")
        print("  评价: 网络连通性极佳，几乎无丢包")
    elif success_rate >= 85:
        print(f"  等级: 良好 ({success_rate}%)")
        print("  评价: 网络连通性良好，偶有丢包")
    elif success_rate >= 70:
        print(f"  等级: 一般 ({success_rate}%)")
        print("  评价: 网络连通性一般，存在一定丢包")
    else:
        print(f"  等级: 较差 ({success_rate}%)")
        print("  评价: 网络连通性较差，丢包较多")
    print()

    print("【延迟评估】")
    if avg is not None:
        print(f"  平均延迟: {avg:.2f}ms")
        grade = _grade_latency(avg)
        labels = {
            "excellent": ("优秀", "延迟极低，网络响应迅速"),
            "good": ("良好", "延迟较低，网络响应良好"),
            "fair": ("一般", "延迟中等，网络响应一般"),
            "poor": ("较差", "延迟较高，网络响应较慢"),
        }
        level, comment = labels[grade]
        print(f"  等级: {level}")
        print(f"  评价: {comment}")
    else:
        print("  平均延迟: 无法计算")
    print()

    print("【延迟分布】")
    valid = sum(buckets.values())
    if valid:
        for label, key in [
            ("优秀 (<50ms)", "excellent"),
            ("良好 (50-100ms)", "good"),
            ("一般 (100-200ms)", "fair"),
            ("较差 (>200ms)", "poor"),
        ]:
            n = buckets[key]
            print(f"  {label}: {n} 个 ({n * 100 // valid}%)")
        if timeouts:
            print(f"  超时: {timeouts} 个")
    print()

    print("【地区覆盖评估】")
    print(f"  检测地区数: {region_count} 个")
    print(f"  优秀地区 (≥90%): {ex_reg} 个")
    print(f"  良好地区 (70-90%): {gd_reg} 个")
    print(f"  一般地区 (50-70%): {fr_reg} 个")
    print(f"  较差地区 (<50%): {pr_reg} 个")
    print()

    score = success_rate * 40 // 100
    if avg is not None:
        score += {"excellent": 40, "good": 35, "fair": 25, "poor": 15}[_grade_latency(avg)]
    if region_count:
        score += ex_reg * 20 // region_count

    print("【综合评分】")
    print(f"  总分: {score}/100")
    if score >= 90:
        print("  等级: 优秀")
        print("  评价: 网络质量优秀，适合各种应用场景")
    elif score >= 75:
        print("  等级: 良好")
        print("  评价: 网络质量良好，适合大多数应用场景")
    elif score >= 60:
        print("  等级: 一般")
        print("  评价: 网络质量一般，建议优化网络配置")
    else:
        print("  等级: 较差")
        print("  评价: 网络质量较差，建议检查网络连接和配置")
    print()

    print("【优化建议】")
    if success_rate < 85:
        print("  • 检查网络连接稳定性，可能存在丢包问题")
    if avg is not None and avg > 100:
        print("  • 延迟较高，建议检查网络路由和DNS配置")
    if timeouts > total // 10:
        print("  • 超时节点较多，建议检查防火墙和网络策略")
    if pr_reg > region_count // 4:
        print("  • 部分地区连通性较差，建议检查跨地区网络质量")
    if score >= 75:
        print("  • 网络质量良好，保持当前配置即可")
    print()


def check_ip_quality() -> None:
    if not has_cmd("ping"):
        print("✗ ping not found (install iputils-ping / inetutils-ping)")
        raise SystemExit(1)

    nodes = _parse_targets()
    max_jobs = int(os.environ.get("MAX_JOBS", "20"))
    total = len(nodes)

    print("全国各地公共 IP 网络质量检测 (并发执行)")
    print("==========================================")
    print()
    print(f"{'地区':<8} {'IP地址':<18} {'描述':<12} {'连通':<4} {'平均延迟'}")
    print("-" * 56)

    results: list[NodeResult | None] = [None] * total
    with ThreadPoolExecutor(max_workers=max_jobs) as pool:
        futures = {
            pool.submit(_test_node, region, ip, desc): i
            for i, (region, ip, desc) in enumerate(nodes)
        }
        done = 0
        for fut in as_completed(futures):
            idx = futures[fut]
            results[idx] = fut.result()
            done += 1
            print(f"\r检测中... {done}/{total}", end="", flush=True)
    print(f"\r检测完成... {total}/{total}")

    ordered = [r for r in results if r is not None]
    for r in ordered:
        mark = "✓" if r.ok else "✗"
        lat = f"{r.latency_ms:.2f}ms" if r.latency_ms is not None else "timeout"
        print(f"{r.region:<8} {r.ip:<18} {r.desc:<12} {mark:<4} {lat}")

    success = sum(1 for r in ordered if r.ok)
    print("-" * 56)
    print()
    print(f"检测完成: 总计 {total} 个节点, 成功 {success} 个, 失败 {total - success} 个")
    print(f"成功率: {success * 100 // total}%")
    print()
    _print_report(ordered)
