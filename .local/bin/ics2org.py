#!/usr/bin/env python3
"""ics2org: convert an iCalendar feed (stdin or file) to an org file.
Stdlib only. Expands recurrences (RRULE/EXDATE/RDATE/RECURRENCE-ID) into a
window around today and converts every time to local time (TZ env / system).
Usage: ics2org.py NAME [in.ics] > out.org
"""
import sys, re, datetime as dt
from zoneinfo import ZoneInfo

PAST_DAYS, FUTURE_DAYS = 60, 365
WINTZ = {  # common Outlook/Windows zone names -> IANA
 "Central Standard Time":"America/Chicago","Eastern Standard Time":"America/New_York",
 "Mountain Standard Time":"America/Denver","US Mountain Standard Time":"America/Phoenix",
 "Pacific Standard Time":"America/Los_Angeles","Alaskan Standard Time":"America/Anchorage",
 "Hawaiian Standard Time":"Pacific/Honolulu","GMT Standard Time":"Europe/London",
 "Greenwich Standard Time":"Atlantic/Reykjavik","W. Europe Standard Time":"Europe/Berlin",
 "Romance Standard Time":"Europe/Paris","Central Europe Standard Time":"Europe/Budapest",
 "India Standard Time":"Asia/Kolkata","China Standard Time":"Asia/Shanghai",
 "Tokyo Standard Time":"Asia/Tokyo","AUS Eastern Standard Time":"Australia/Sydney",
 "UTC":"UTC","Coordinated Universal Time":"UTC","Customized Time Zone":None}
def _local():
    import os
    for name in (os.environ.get("ICS2ORG_TZ"), os.environ.get("TZ", "").lstrip(":")):
        if name:
            try: return ZoneInfo(name)
            except Exception: pass
    try:
        link = os.path.realpath("/etc/localtime"); i = link.find("zoneinfo/")
        if i >= 0: return ZoneInfo(link[i+9:])
    except Exception: pass
    return dt.datetime.now().astimezone().tzinfo
LOCAL = _local()
DAYS = ["MO","TU","WE","TH","FR","SA","SU"]

def unfold(text):
    return re.sub(r"\r?\n[ \t]", "", text).splitlines()

def unesc(v):
    return (v.replace("\\n","\n").replace("\\N","\n").replace("\\,",",")
             .replace("\\;",";").replace("\\\\","\\"))

def zone(tzid):
    if not tzid: return None
    tzid = tzid.strip('"')
    if tzid in WINTZ: tzid = WINTZ[tzid]
    if tzid is None: return LOCAL
    try: return ZoneInfo(tzid)
    except Exception:
        m = re.search(r"([A-Za-z]+/[A-Za-z_]+)", tzid)   # e.g. /mozilla.org/.../America/Chicago
        try: return ZoneInfo(m.group(1)) if m else LOCAL
        except Exception: return LOCAL

def parse_dt(val, params):
    """-> (datetime-or-date, all_day)"""
    v = val.strip()
    if params.get("VALUE") == "DATE" or re.fullmatch(r"\d{8}", v):
        return dt.date(int(v[:4]), int(v[4:6]), int(v[6:8])), True
    d = dt.datetime.strptime(v[:15], "%Y%m%dT%H%M%S")
    if v.endswith("Z"): d = d.replace(tzinfo=dt.timezone.utc)
    else: d = d.replace(tzinfo=zone(params.get("TZID")) or LOCAL)
    return d, False

def parse(text):
    events, cur = [], None
    for line in unfold(text):
        if line == "BEGIN:VEVENT": cur = {"EXDATE": [], "RDATE": []}; continue
        if line == "END:VEVENT":
            if cur: events.append(cur)
            cur = None; continue
        if cur is None or ":" not in line: continue
        head, val = line.split(":", 1)
        parts = head.split(";"); name = parts[0].upper()
        params = dict(p.split("=",1) for p in parts[1:] if "=" in p)
        if name in ("DTSTART","DTEND","RECURRENCE-ID"): cur[name] = parse_dt(val, params)
        elif name in ("EXDATE","RDATE"):
            for x in val.split(","): cur[name].append(parse_dt(x, params)[0])
        elif name == "DURATION": cur[name] = val
        elif name == "RRULE": cur[name] = dict(p.split("=",1) for p in val.split(";") if "=" in p)
        elif name in ("SUMMARY","LOCATION","DESCRIPTION","UID","STATUS"): cur[name] = unesc(val)
    return events

def duration(s):
    m = re.fullmatch(r"([+-])?P(?:(\d+)W)?(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?", s)
    if not m: return dt.timedelta()
    w,d,h,mi,se = (int(x or 0) for x in m.groups()[1:])
    return dt.timedelta(weeks=w, days=d, hours=h, minutes=mi, seconds=se)

def nth_weekdays(year, month, byday):
    out = []
    for spec in byday:
        m = re.fullmatch(r"([+-]?\d+)?(MO|TU|WE|TH|FR|SA|SU)", spec)
        if not m: continue
        n, wd = (int(m.group(1)) if m.group(1) else None), DAYS.index(m.group(2))
        first = dt.date(year, month, 1)
        nxt = dt.date(year + (month == 12), month % 12 + 1, 1)
        days = [first + dt.timedelta(i) for i in range((nxt-first).days)
                if (first + dt.timedelta(i)).weekday() == wd]
        if n is None: out += days
        elif -len(days) <= n <= len(days) and n != 0: out.append(days[n-1 if n > 0 else n])
    return out

def expand(start, rr, wend):
    """yield start dates/datetimes per RRULE (no time-of-day rules)."""
    freq = rr.get("FREQ"); iv = int(rr.get("INTERVAL", 1)); count = int(rr["COUNT"]) if "COUNT" in rr else None
    until = None
    if "UNTIL" in rr:
        u, allday = parse_dt(rr["UNTIL"], {})
        until = u if allday else (u if u.tzinfo else u.replace(tzinfo=LOCAL))
    byday = rr["BYDAY"].split(",") if "BYDAY" in rr else None
    bymd = [int(x) for x in rr["BYMONTHDAY"].split(",")] if "BYMONTHDAY" in rr else None
    bymonth = [int(x) for x in rr["BYMONTH"].split(",")] if "BYMONTH" in rr else None
    sd = start if isinstance(start, dt.date) and not isinstance(start, dt.datetime) else start.date()
    def mk(d):
        return d if not isinstance(start, dt.datetime) else start.replace(year=d.year, month=d.month, day=d.day)
    def past_until(x):
        if until is None: return False
        a = x if isinstance(x, dt.datetime) == isinstance(until, dt.datetime) else (x.date() if isinstance(x, dt.datetime) else x)
        b = until if isinstance(a, type(until)) or not isinstance(until, dt.datetime) else until.date()
        try: return a > b
        except TypeError: return a > (b if not isinstance(b, dt.datetime) else b.date())
    n, k = 0, 0
    while k < 5000:
        if freq == "DAILY": cands = [sd + dt.timedelta(days=k*iv)]
        elif freq == "WEEKLY":
            wk0 = sd - dt.timedelta(days=sd.weekday()) + dt.timedelta(weeks=k*iv)
            cands = sorted(wk0 + dt.timedelta(DAYS.index(b[-2:])) for b in byday) if byday else [sd + dt.timedelta(weeks=k*iv)]
        elif freq in ("MONTHLY","YEARLY"):
            if freq == "MONTHLY":
                mo = sd.month - 1 + k*iv; months = [(sd.year + mo//12, mo%12 + 1)]
            else:
                y = sd.year + k*iv; months = [(y, m) for m in (bymonth or [sd.month])]
            cands = []
            for y, m in months:
                if byday: cands += nth_weekdays(y, m, byday)
                else:
                    for md in (bymd or [sd.day]):
                        try: cands.append(dt.date(y, m, md) if md > 0 else
                                          dt.date(y + (m==12), m%12+1, 1) + dt.timedelta(md))
                        except ValueError: pass
            cands.sort()
        else: yield start; return
        for c in cands:
            if c < sd: continue
            x = mk(c)
            if past_until(x) or (count is not None and n >= count): return
            n += 1; yield x
        if (cands and cands[0] > wend) : return
        k += 1

def key(x):
    return x.astimezone(dt.timezone.utc).strftime("%Y%m%dT%H%M%S") if isinstance(x, dt.datetime) else x.strftime("%Y%m%d")

def ts(s, e, allday):
    if allday:
        last = e - dt.timedelta(days=1) if e and e > s else s
        f = lambda d: d.strftime("<%Y-%m-%d %a>")
        return f(s) if last == s else f(s) + "--" + f(last)
    s, e = s.astimezone(LOCAL), (e or s).astimezone(LOCAL)
    if s.date() == e.date():
        return s.strftime("<%Y-%m-%d %a %H:%M") + ("-" + e.strftime("%H:%M") if e != s else "") + ">"
    return s.strftime("<%Y-%m-%d %a %H:%M>") + "--" + e.strftime("<%Y-%m-%d %a %H:%M>")

def main():
    name = sys.argv[1]
    text = open(sys.argv[2], encoding="utf-8", errors="replace").read() if len(sys.argv) > 2 else sys.stdin.read()
    today = dt.date.today()
    wstart, wend = today - dt.timedelta(PAST_DAYS), today + dt.timedelta(FUTURE_DAYS)
    evs = parse(text)
    overrides = {(e.get("UID"), key(e["RECURRENCE-ID"][0])): e for e in evs if "RECURRENCE-ID" in e}
    out = []
    for e in evs:
        if "DTSTART" not in e or "RECURRENCE-ID" in e or e.get("STATUS") == "CANCELLED": continue
        s, allday = e["DTSTART"]
        if "DTEND" in e: length = e["DTEND"][0] - s
        elif "DURATION" in e: length = duration(e["DURATION"])
        else: length = dt.timedelta(days=1) if allday else dt.timedelta()
        exd = {key(x) for x in e["EXDATE"]}
        starts = list(expand(s, e["RRULE"], wend)) if "RRULE" in e else [s]
        starts += e["RDATE"]
        for st in starts:
            d = st if not isinstance(st, dt.datetime) else st.astimezone(LOCAL).date()
            if d < wstart or d > wend or key(st) in exd: continue
            ov = overrides.pop((e.get("UID"), key(st)), None)
            ev, s2 = (ov, ov["DTSTART"][0]) if ov else (e, st)
            if ov and ov.get("STATUS") == "CANCELLED": continue
            if ov:
                l2 = ov["DTEND"][0] - s2 if "DTEND" in ov else length
            else: l2 = length
            out.append((s2, l2, ev, allday if not ov else ov["DTSTART"][1]))
    for ov in overrides.values():  # moved instances whose master is outside window
        s2, ad = ov["DTSTART"]
        l2 = ov["DTEND"][0] - s2 if "DTEND" in ov else dt.timedelta()
        out.append((s2, l2, ov, ad))
    sortkey = lambda t: (t[0] if isinstance(t[0], dt.datetime) else dt.datetime.combine(t[0], dt.time(), LOCAL)).astimezone(dt.timezone.utc)
    print(f"#+TITLE: {name} calendar (read-only, generated by ics2org — edits are overwritten)")
    print(f"#+FILETAGS: :{re.sub(r'[^A-Za-z0-9_@]', '_', name)}:")
    print(f"#+CATEGORY: {name}")
    print(f"#+STARTUP: overview\n")
    for s2, l2, ev, ad in sorted(out, key=sortkey):
        title = (ev.get("SUMMARY") or "(no title)").replace("\n", " ").strip()
        print(f"* {title}")
        print(f"  {ts(s2, s2 + l2 if l2 else None, ad)}")
        props = [("ICS_UID", ev.get("UID")), ("LOCATION", ev.get("LOCATION"))]
        props = [(k, v.replace('\n',' ')) for k, v in props if v]
        if props:
            print("  :PROPERTIES:"); [print(f"  :{k}: {v}") for k, v in props]; print("  :END:")
        desc = (ev.get("DESCRIPTION") or "").strip()
        if desc:
            for l in desc.splitlines()[:15]:
                l = l.rstrip()
                print("  " + ("," + l if l.startswith("*") else l))
main()
