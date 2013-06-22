

DATA_DIR=data

QUARTERS= $(DATA_DIR)/2010-4th-quarter.norm $(DATA_DIR)/2011-1st-quarter.norm $(DATA_DIR)/2011-2nd-quarter.norm $(DATA_DIR)/2011-3rd-quarter.norm $(DATA_DIR)/2011-4th-quarter.norm $(DATA_DIR)/2012-1st-quarter.norm $(DATA_DIR)/2012-2nd-quarter.norm $(DATA_DIR)/2012-3rd-quarter.norm $(DATA_DIR)/2012-4th-quarter.norm $(DATA_DIR)/2013-1st-quarter.norm 

MERGED=data/merged.rides

STATIONS=$(DATA_DIR)/bikeStations.xml
GEO_LOCATIONS=$(DATA_DIR)/geolocation.txt

LOCATIONS_FILE=$(DATA_DIR)/locations.txt


# Easier rules

all: $(MERGED) $(STATIONS) $(GEO_LOCATIONS)


$(GEO_LOCATIONS): $(STATIONS)
	python stationLocation.py | sort > $(GEO_LOCATIONS)


# Sanity check the location to make sure we have geo data for all the used locations
location_check: $(LOCATIONS_FILE) $(GEO_LOCATIONS)
	join -t, -e MISSING -o 1.1,2.1,2.2,2.3,1.2 -a 1 $(LOCATIONS_FILE) $(GEO_LOCATIONS) | grep MISSING

# Extract unique location names from the trip files
# This is really for info only since it's available in the $(STATIONS) file
$(LOCATIONS_FILE): $(MERGED)
	# Extract unique location data
	# ***   This takes a little while    ****
	cat $(MERGED) | awk -F, '{print $$4 "," $$3 "\n" $$7 "," $$6 }' | sort | uniq > $(LOCATIONS_FILE)

$(MERGED): $(QUARTERS)
	# Merging all the normalized data
	cat $(QUARTERS) > $(MERGED)


clean:
	-rm $(DATA_DIR)/*.norm
	-rm $(DATA_DIR)/*.norm1
	-rm $(DATA_DIR)/*.txt
	-rm $(DATA_DIR)/*.xml
	-rm $(DATA_DIR)/*.rides



clean_data:
	-rm $(DATA_DIR)/*.csv


# Extra cleanup that's common to the semi-normalized files
# Strip extra spaces around the ","
# convert "min" and "sec" to "m" and "s"
# remove a few "odd" looking records seen in the data
%.norm: %.norm1
	# Cleanup data for $*
	cat $*.norm1 | \
		sed "s/ *, */,/g" | \
		sed "s/min\./m/g" | sed "s/sec\./s/g" | \
		egrep -v "\? \(0x[A-F0-9]+\)," | grep -v ",," \
		> $*.norm

# Messy rules for normalizing the slightly different data formats
# Yeah, this can be cleaner, but it works
# Use the 2013-1st quarter as the normalized format

# late 2012 and 2013 are the same
$(DATA_DIR)/2013-1st-quarter.norm1: $(DATA_DIR)/2013-1st-quarter.csv
	cat $(DATA_DIR)/2013-1st-quarter.csv | tail -n+2 > $(DATA_DIR)/2013-1st-quarter.norm1

$(DATA_DIR)/2012-4th-quarter.norm1: $(DATA_DIR)/2012-4th-quarter.csv
	cat $(DATA_DIR)/2012-4th-quarter.csv | tail -n+2 > $(DATA_DIR)/2012-4th-quarter.norm1

$(DATA_DIR)/2012-3rd-quarter.norm1: $(DATA_DIR)/2012-3rd-quarter.csv
	cat $(DATA_DIR)/2012-3rd-quarter.csv | tail -n+2 > $(DATA_DIR)/2012-3rd-quarter.norm1

# 2 quarters in 2012 added an extra column that's not needed
$(DATA_DIR)/2012-2nd-quarter.norm1: $(DATA_DIR)/2012-2nd-quarter.csv
	cat $(DATA_DIR)/2012-2nd-quarter.csv | tail -n+2 | cut -d, -f 1,3,4,5,6,7,8,9,10 > $(DATA_DIR)/2012-2nd-quarter.norm1

$(DATA_DIR)/2012-1st-quarter.norm1: $(DATA_DIR)/2012-1st-quarter.csv
	cat $(DATA_DIR)/2012-1st-quarter.csv | tail -n+2 | cut -d, -f 1,3,4,5,6,7,8,9,10 > $(DATA_DIR)/2012-1st-quarter.norm1

# 2010 and 2011 are the same format
$(DATA_DIR)/2011-4th-quarter.norm1: $(DATA_DIR)/2011-4th-quarter.csv
	cat $(DATA_DIR)/2011-4th-quarter.csv | tail -n+2 | awk -F, 'BEGIN{OFS=","} {print $$1,$$2,$$4,$$3,$$5,$$6,$$7}' | sed -r "s/^(.*) \(([0-9]+)\),(.*)/\1,\2,\3/" | sed -r "s/^(.*) \(([0-9]+)\),(.*)/\1,\2,\3/" > $(DATA_DIR)/2011-4th-quarter.norm1

$(DATA_DIR)/2011-3rd-quarter.norm1: $(DATA_DIR)/2011-3rd-quarter.csv
	cat $(DATA_DIR)/2011-3rd-quarter.csv | tail -n+2 |  awk -F, 'BEGIN{OFS=","} {print $$1,$$2,$$4,$$3,$$5,$$6,$$7}' | sed -r "s/^(.*) \(([0-9]+)\),(.*)/\1,\2,\3/" | sed -r "s/^(.*) \(([0-9]+)\),(.*)/\1,\2,\3/" > $(DATA_DIR)/2011-3rd-quarter.norm1

$(DATA_DIR)/2011-2nd-quarter.norm1: $(DATA_DIR)/2011-2nd-quarter.csv
	cat $(DATA_DIR)/2011-2nd-quarter.csv | tail -n+2 |  awk -F, 'BEGIN{OFS=","} {print $$1,$$2,$$4,$$3,$$5,$$6,$$7}' | sed -r "s/^(.*) \(([0-9]+)\),(.*)/\1,\2,\3/" | sed -r "s/^(.*) \(([0-9]+)\),(.*)/\1,\2,\3/" > $(DATA_DIR)/2011-2nd-quarter.norm1

$(DATA_DIR)/2011-1st-quarter.norm1: $(DATA_DIR)/2011-1st-quarter.csv
	cat $(DATA_DIR)/2011-1st-quarter.csv | tail -n+2 |  awk -F, 'BEGIN{OFS=","} {print $$1,$$2,$$4,$$3,$$5,$$6,$$7}' | sed -r "s/^(.*) \(([0-9]+)\),(.*)/\1,\2,\3/" | sed -r "s/^(.*) \(([0-9]+)\),(.*)/\1,\2,\3/" > $(DATA_DIR)/2011-1st-quarter.norm1

$(DATA_DIR)/2010-4th-quarter.norm1: $(DATA_DIR)/2010-4th-quarter.csv
	cat $(DATA_DIR)/2010-4th-quarter.csv | tail -n+2 | awk -F, 'BEGIN{OFS=","} {print $$1,$$2,$$4,$$3,$$5,$$6,$$7}' | sed -r "s/^(.*) \(([0-9]+)\),(.*)/\1,\2,\3/" | sed -r "s/^(.*) \(([0-9]+)\),(.*)/\1,\2,\3/" > $(DATA_DIR)/2010-4th-quarter.norm1




# rule to download the main data files
%.csv:
	curl -o $*.csv http://www.capitalbikeshare.com/assets/files/trip-history-data/`basename $*`.csv

# Thanks to https://github.com/nelsonmc/bikeshare-tracker for this one, I couldn't find it listed on the bikeshare site
$(STATIONS):
	curl -o $(STATIONS) http://www.capitalbikeshare.com/data/stations/bikeStations.xml

