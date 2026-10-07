\# F1 race database (2025 season)



A personal project: a MariaDB database with lap times, tyre compounds and pit stops for every race of the 2025 Formula 1 season, plus SQL queries that look at pit lane times and tyre wear.



I built it because I want to work in F1 one day, and I wanted to learn by working with real race data.



\## What's in it



\- 24 races, 21 drivers, 10 teams

\- 26,689 laps (lap time, tyre compound, tyre age, stint number)

\- 841 pit stops



Only the \*\*race\*\* session of each weekend is loaded so far. Practice, qualifying and sprint sessions are not.



\## Data source



All data is public and comes from \[FastF1](https://github.com/theOehrly/Fastf1). I do not have, and do not use, any team-internal data.



\## Database design



Seven tables: `teams`, `drivers`, `races`, `sessions`, `entries`, `laps`, `pit\_stops`. Times are stored as integer milliseconds. See `schema.sql`.



\## How to run it



1\. Start a MariaDB server (I use the `mariadb:11` Docker image on port 3307).

2\. Run `schema.sql` to create the database.

3\. Install the Python packages: `py -m pip install fastf1 pymysql`

4\. Set the database password and load the season:

5. Run the queries in `queries.sql`.

## Results and limitations

### Pit lane time per team

Average time in the pit lane (stops over 40 seconds removed):

| Team | Stops | Avg (s) |
|---|---|---|
| Mercedes | 88 | 22.65 |
| McLaren | 82 | 22.87 |
| Ferrari | 85 | 22.88 |
| Kick Sauber | 80 | 22.96 |
| Red Bull Racing | 86 | 23.18 |
| Racing Bulls | 74 | 23.31 |
| Alpine | 78 | 23.34 |
| Haas F1 Team | 78 | 23.49 |
| Aston Martin | 81 | 23.64 |
| Williams | 82 | 24.16 |

Limitations:
- This is the time from pit entry to pit exit, **not** the time the car is stationary. Pit lane length differs between tracks.
- The gap between the top teams is about 0.2 seconds. With 80-90 stops per team, I would not call that a real difference.
- The 40-second cut-off is my own choice.
- Some stops have no duration (for example Bearman's second stop in Hungary), because the pit exit time was missing in the data. These are stored as NULL.

### Tyre wear

I compared each lap time to the fastest lap of the same race, grouped by tyre age.

- Without any correction, laps get *faster* with older tyres. This is because the car gets lighter as fuel burns, and old tyres are used later in the race when the track is rubbered in.
- With a rough fuel correction of 0.035 s per lap, laps get *slower* with age. For the hard tyre, relative pace went from 1.0435 (laps 1-5) to 1.0504 (laps 26-30). That is roughly 0.6 seconds over 25 laps.

Limitations:
- The result depends on my fuel assumption (0.035 s per lap). It is an estimate, not a team figure.
- The soft tyre stays almost flat, which I did not expect. Drivers with worn tyres pit, so the oldest tyres in the data are the ones that held up best.
- Compounds are used at different tracks and times, so I would not use this to say one compound is faster than another.

## Ideas for next steps

- Load practice and qualifying sessions.
- Measure tyre wear per stint inside a single race instead of across the whole season.
- Add weather and safety car laps to separate them from tyre wear.

