rtt
#argparse piss easy to make 

# library reads 

# help thing for it 

import argparse
from decimal import Decimal
import mysql.connector as mariadb
import sys

def connect():
    try:
        conn = mariadb.connect(
            user="<username>",
            password="<password>",
            host="<username>.teaching.cs.st-andrews.ac.uk",
            port=3306,
            database="<database>"
        )
        return conn
    except mariadb.Error as e:
        print(f"Error connecting to MariaDB: {e}")
        sys.exit(1)

def schedule(loc):
    conn = connect()
    cur = conn.cursor()
    try:
        # now just pull from the view
        query = """
            SELECT hc, dep, pl, dest, len, toc
              FROM scheduleEDB
        """
        cur.execute(query)           # no need for a WHERE, the view already filters EDB
        rows = cur.fetchall()
        if not rows:
            print(f"No schedule found in scheduleEDB.")
            return

        for hc, dep, pl, dest, length, toc in rows:
            print(f"{dep}  HC:{hc:<4}  Plat:{pl:<2}  Dest:{dest:<3}  Coaches:{length:<2}  TOC:{toc}")
    except mariadb.Error as e:
        print(f"Error fetching schedule: {e}")
    finally:
        cur.close()
        conn.close()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Train schedule and service information")
    parser.add_argument('--schedule', help='Schedule for a given station')
    args = parser.parse_args()

    if args.schedule:
        schedule(args.schedule)
    else:
        parser.print_help()
