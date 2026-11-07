"""Local foreground-app accounting. Never stores window titles or document names."""
import datetime as dt
import os
from pathlib import Path
import sqlite3
import time

STATE=Path(os.environ.get('XDG_STATE_HOME',Path.home()/'.local/state'))/'macos-desktop'
DATABASE=STATE/'screen-time.sqlite3'
IDLE=Path(os.environ.get('XDG_RUNTIME_DIR',f'/run/user/{os.getuid()}'))/'macos-screen-time-idle'


def connect(path=DATABASE):
    path=Path(path);path.parent.mkdir(parents=True,exist_ok=True,mode=0o700)
    db=sqlite3.connect(path,timeout=5)
    path.chmod(0o600)
    db.executescript('''CREATE TABLE IF NOT EXISTS usage(day TEXT, hour INTEGER, app TEXT, seconds REAL NOT NULL, PRIMARY KEY(day,hour,app));
    CREATE TABLE IF NOT EXISTS preferences(key TEXT PRIMARY KEY,value TEXT NOT NULL);
    CREATE TABLE IF NOT EXISTS limits(app TEXT PRIMARY KEY,minutes INTEGER NOT NULL);
    CREATE TABLE IF NOT EXISTS reminders(day TEXT,app TEXT,PRIMARY KEY(day,app));''')
    return db


def setting(db,key,default=''):
    row=db.execute('SELECT value FROM preferences WHERE key=?',(key,)).fetchone()
    return row[0] if row else default


def configure(key,value,path=DATABASE):
    if key!='paused':raise ValueError('Unknown preference')
    with connect(path) as db:db.execute('INSERT OR REPLACE INTO preferences VALUES(?,?)',(key,'1' if value else '0'))


def set_limit(app,minutes,path=DATABASE):
    minutes=int(minutes)
    if not 0<=minutes<=1440:raise ValueError('Choose 0–1440 minutes')
    with connect(path) as db:
        if minutes:db.execute('INSERT OR REPLACE INTO limits VALUES(?,?)',(app,minutes))
        else:db.execute('DELETE FROM limits WHERE app=?',(app,))


def clear(path=DATABASE):
    with connect(path) as db:
        db.execute('DELETE FROM usage');db.execute('DELETE FROM reminders')
        db.execute('INSERT OR REPLACE INTO preferences VALUES(?,?)',('started',str(time.time())))


def record(db,app,start,end):
    """Split intervals at local hour/day boundaries, including midnight."""
    if not app or end<=start or end-start>15:return
    while start<end:
        local=dt.datetime.fromtimestamp(start)
        boundary=(local.replace(minute=0,second=0,microsecond=0)+dt.timedelta(hours=1)).timestamp()
        stop=min(end,boundary)
        if stop<=start:stop=end
        db.execute('INSERT INTO usage VALUES(?,?,?,?) ON CONFLICT(day,hour,app) DO UPDATE SET seconds=seconds+excluded.seconds',
                   (local.date().isoformat(),local.hour,app,stop-start))
        start=stop


def summary(days=1,offset=0,path=DATABASE):
    end=dt.date.today()-dt.timedelta(days=int(offset));start=end-dt.timedelta(days=int(days)-1)
    with connect(path) as db:
        apps=db.execute('SELECT app,SUM(seconds) FROM usage WHERE day BETWEEN ? AND ? GROUP BY app ORDER BY SUM(seconds) DESC',(start.isoformat(),end.isoformat())).fetchall()
        daily=dict(db.execute('SELECT day,SUM(seconds) FROM usage WHERE day BETWEEN ? AND ? GROUP BY day',(start.isoformat(),end.isoformat())))
        hours=dict(db.execute('SELECT hour,SUM(seconds) FROM usage WHERE day=? GROUP BY hour',(end.isoformat(),)))
        return {'apps':apps,'total':sum(v for _,v in apps),'daily':daily,'hours':hours,
                'limits':dict(db.execute('SELECT app,minutes FROM limits')),
                'paused':setting(db,'paused','0')=='1','started':setting(db,'started'),
                'start':start.isoformat(),'end':end.isoformat()}


def duration(seconds):
    seconds=int(seconds);hours,minutes=divmod(seconds//60,60)
    return f'{hours}h {minutes}m' if hours else f'{minutes}m {seconds%60}s'
