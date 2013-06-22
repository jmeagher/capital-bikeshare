import sys

cols=sys.argv[1].split(',')

print '{routes_by_month: ['
first=True
for line in sys.stdin:
    if not first:
        print '  } ,'
    else:
        first=False

    print '  {'
    arr=line.split(',')
    firstVal=True
    for idx, val in enumerate(arr):
        if not firstVal:
            print ","
        else:
            firstVal=False

        # Wrap strings in quotes for output
        try:
            float(val)
        except ValueError:
            val = '"' + val + '"'

        sys.stdout.write('\t' + cols[idx] + ':' + val)

print '  }'
print '] }'
