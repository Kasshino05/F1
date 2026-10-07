import os
import pandas as pd
import pymysql
import fastf1

SEASON = 2025
SESSION = "R"

os.makedirs("cache", exist_ok=True)
fastf1.Cache.enable_cache("cache")

db = pymysql.connect(host="127.0.0.1", port=3307, user="root",
                                          password=os.environ["F1_DB_PASSWORD"], database="f1", autocommit=False)
cur = db.cursor()

VALID = {"SOFT", "MEDIUM", "HARD", "INTERMEDIATE", "WET"}


def num(x):
    return None if pd.isna(x) else int(x)


def load_race(rnd):
    session = fastf1.get_session(SEASON, rnd, SESSION)
    session.load(telemetry=False, weather=False, messages=False)
    laps = session.laps
    results = session.results
    event = session.event

    cur.execute(
        "INSERT IGNORE INTO races (season, round, name, race_date) VALUES (%s,%s,%s,%s)",
        (SEASON, int(event["RoundNumber"]), event["EventName"], event["EventDate"].date()))
    cur.execute("SELECT race_id FROM races WHERE season=%s AND round=%s",
                (SEASON, int(event["RoundNumber"])))
    race_id = cur.fetchone()[0]

    cur.execute("INSERT IGNORE INTO sessions (race_id, session_type) VALUES (%s,%s)",
                (race_id, SESSION))
    cur.execute("SELECT session_id FROM sessions WHERE race_id=%s AND session_type=%s",
                (race_id, SESSION))
    session_id = cur.fetchone()[0]

    driver_ids = {}
    for _, r in results.iterrows():
        cur.execute("INSERT IGNORE INTO teams (name) VALUES (%s)", (r["TeamName"],))
        cur.execute("SELECT team_id FROM teams WHERE name=%s", (r["TeamName"],))
        team_id = cur.fetchone()[0]
        cur.execute("INSERT IGNORE INTO drivers (code, first_name, last_name) VALUES (%s,%s,%s)",
                    (r["Abbreviation"], r["FirstName"], r["LastName"]))
        cur.execute("SELECT driver_id FROM drivers WHERE code=%s", (r["Abbreviation"],))
        d_id = cur.fetchone()[0]
        driver_ids[r["Abbreviation"]] = d_id
        cur.execute("INSERT IGNORE INTO entries (race_id, driver_id, team_id) VALUES (%s,%s,%s)",
                    (race_id, d_id, team_id))

    lap_rows = 0
    for _, l in laps.iterrows():
        d_id = driver_ids.get(l["Driver"])
        if d_id is None:
            continue
        ms = None if pd.isna(l["LapTime"]) else int(l["LapTime"].total_seconds() * 1000)
        comp = l["Compound"] if l["Compound"] in VALID else None
        cur.execute(
            "INSERT IGNORE INTO laps (session_id, driver_id, lap_number, lap_time_ms, compound, tyre_age, stint_no) "
            "VALUES (%s,%s,%s,%s,%s,%s,%s)",
            (session_id, d_id, int(l["LapNumber"]), ms, comp, num(l["TyreLife"]), num(l["Stint"])))
        lap_rows += cur.rowcount

    pit_rows = 0
    for code, d_id in driver_ids.items():
        dl = laps[laps["Driver"] == code].sort_values("LapNumber").reset_index(drop=True)
        stop_no = 0
        for i in range(len(dl)):
            if pd.notna(dl.loc[i, "PitInTime"]):
                stop_no += 1
                dur = None
                if i + 1 < len(dl) and pd.notna(dl.loc[i + 1, "PitOutTime"]):
                    secs = (dl.loc[i + 1, "PitOutTime"] - dl.loc[i, "PitInTime"]).total_seconds()
                    if 0 < secs < 120:
                        dur = int(secs * 1000)
                cur.execute(
                    "INSERT IGNORE INTO pit_stops (session_id, driver_id, stop_no, lap_number, duration_ms) "
                    "VALUES (%s,%s,%s,%s,%s)",
                    (session_id, d_id, stop_no, int(dl.loc[i, "LapNumber"]), dur))
                pit_rows += cur.rowcount

    db.commit()
    return event["EventName"], lap_rows, pit_rows


schedule = fastf1.get_event_schedule(SEASON, include_testing=False)
rounds = [int(r) for r in schedule["RoundNumber"] if int(r) > 0]
print("Antal løb i sæsonen:", len(rounds))

failed = []
for rnd in rounds:
    try:
        name, laps_n, pits_n = load_race(rnd)
        print(f"Runde {rnd}: {name} - nye omgange {laps_n}, nye pitstop {pits_n}")
    except Exception as e:
        db.rollback()
        failed.append(rnd)
        print(f"Runde {rnd}: FEJLEDE ({type(e).__name__}: {e})")

print("Færdig. Fejlede runder:", failed if failed else "ingen")