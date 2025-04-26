#!/usr/bin/env python3
import argparse
import mysql.connector
import sys

def get_connection():
    return mysql.connector.connect(
        host='your-host', user='you', password='pw', database='yourdb'
    )

def schedule(station):
    cnx = get_connection()
    cur = cnx.cursor()
    cur.execute("SELECT * FROM scheduleEDB WHERE orig = %s ORDER BY dep", (station,))
    rows = cur.fetchall()
    if not rows:
        print(f"No services departing {station}")
    else:
        print(f"Schedule for {station}:")
        for hc, dep, pl, dest, length, toc in rows:
            print(f" {dep}  Headcode {hc}  Plat. {pl} -> {dest}  Coaches: {length}  {toc}")
    cur.close(); cnx.close()

def service(hc, dep):
    cnx = get_connection()
    cur = cnx.cursor()
    cur.execute("SELECT loc, stn, pl, arr, dep FROM serviceEDBDEE WHERE hc = %s AND dep = %s ORDER BY ?",
                (hc, dep,))  # may need to adjust ORDER BY
    rows = cur.fetchall()
    if not rows:
        print(f"No service {hc} at {dep}")
    else:
        print(f"Stops for {hc} @ {dep}:")
        for loc, stn, pl, arr, d in rows:
            station_info = f" ({stn} plat {pl})" if stn else ""
            print(f" {loc}{station_info}  Arr: {arr or '--'}  Dep: {d or '--'}")
    cur.close(); cnx.close()

def main():
    p = argparse.ArgumentParser(description="Rail timetable tool")
    sub = p.add_subparsers(dest='cmd', required=True)
    sp = sub.add_parser('schedule', help='Show schedule for a station')
    sp.add_argument('station', metavar='STN')
    ss = sub.add_parser('service', help='Show stops for a service')
    ss.add_argument('hc', metavar='HEADCODE')
    ss.add_argument('dep', metavar='TIME')
    args = p.parse_args()
    if args.cmd == 'schedule':
        schedule(args.station)
    elif args.cmd == 'service':
        service(args.hc, args.dep)
    else:
        p.print_help()
        sys.exit(1)

if __name__ == '__main__':
    main()
