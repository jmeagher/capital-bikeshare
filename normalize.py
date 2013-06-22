import sys
import re
import datetime


duration_regex = re.compile('([0-9]+)h.* ([0-9]+)m.* ([0-9]+)s.*')

def duration_to_sec(duration):
    match = duration_regex.search(duration)
    h = match.group(1)
    m = match.group(2)
    s = match.group(3)
    return str(3600 * int(h) + 60 * int(m) + int(s))

def fix_date(date_string):
    format1='%m/%d/%Y %H:%M'
    format2='%Y-%m-%d %H:%M'
    return datetime.datetime.strptime(date_string, format1).strftime(format2)

    
def split_it(line):
    # Clean up extra newlines
    return " ".join(line.split()).split(',')


bike_regex = re.compile('^W[0-9]+$')

def proc_2013(row,line):
    row[0] = duration_to_sec(row[0])
    row[1] = fix_date(row[1])
    row[4] = fix_date(row[4])
    # Remove the station names, just the IDs are ok
    del row[5]
    del row[2]

    # A little cleanup
    row[5].upper()

    # A little error checking on the station names since they get screwed up sometimes
    if not bike_regex.search(row[5]):
        return
    # Ignore any rows with empty cells
    for s in row:
        if len(s) == 0:
            return


    print ",".join(row)

def proc_2012_early(row,line):
    del row[1]
    proc_2013(row,line)

station_ext = '[^,]*\(([0-9]+).'
extractor_2011 = re.compile('(.*),(.*),(.*),('+station_ext+'),('+station_ext+'),(.*),(.*)')
def proc_2011(row,line):
    # Need to extract the station id from the station name
    match = extractor_2011.search(line)
    if match:
        proc_2013([match.group(1), match.group(2), match.group(4), match.group(5), match.group(3), match.group(6), match.group(7), match.group(8), match.group(9)],line)
        #print ",".join(match.groups())


def proc_all(data, processor):
    for line in data:
        processor(split_it(line),line)

if __name__ == '__main__':
    if sys.argv[1] == '2013':
        proc_all(sys.stdin, proc_2013)
    elif sys.argv[1] == '2012_late':
        proc_all(sys.stdin, proc_2013)
    elif sys.argv[1] == '2012_early':
        proc_all(sys.stdin, proc_2012_early)
    elif sys.argv[1] == '2011':
        proc_all(sys.stdin, proc_2011)
    elif sys.argv[1] == '2010':
        proc_all(sys.stdin, proc_2011)
    else:
        print "Unknown conversion type"

