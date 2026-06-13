import json
import sys
from datetime import datetime

TARGET_DATE = "2026-04-06"


def load_logs(filepath):
    with open(filepath, "r") as f:
        return json.load(f)


def filter_by_date(records, date_str):
    filtered = []
    for r in records:
        exec_date = r.get("execution_date", "")
        if exec_date.startswith(date_str):
            filtered.append(r)
    return filtered


def count_by_state(records):
    counts = {}
    for r in records:
        state = r["state"]
        if state not in counts:
            counts[state] = 0
        counts[state] += 1
    return counts


def get_failed_tasks(records):
    return [r for r in records if r["state"] in ("failed", "upstream_failed")]


def get_longest_task(records):
    longest = None
    for r in records:
        if longest is None or r["duration_seconds"] > longest["duration_seconds"]:
            longest = r
    return longest


def main():
    records = load_logs("airflow_logs.json")
    daily = filter_by_date(records, TARGET_DATE)

    state_counts = count_by_state(daily)
    failed = get_failed_tasks(daily)
    longest = get_longest_task(daily)

    print(f"=== Airflow Health Report for {TARGET_DATE} ===")
    print(f"Total tasks: {len(daily)}")

    print("\nTasks by state:")
    for state, count in state_counts.items():
        print(f"  {state}: {count}")

    print("\nFailed tasks:")
    for task in failed:
        dag = task["dag_id"]
        t_id = task["task_id"]
        if task["state"] == "upstream_failed":
            print(f"  {dag} → {t_id} (upstream_failed)")
        else:
            print(f"  {dag} → {t_id}")

    print("\nLongest running task:")
    print(f"  {longest['dag_id']} / {longest['task_id']} — {longest['duration_seconds']} seconds")


if __name__ == "__main__":
    main()
