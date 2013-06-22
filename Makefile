DATA_DIR=data

QUARTERS= $(DATA_DIR)/2010-4th-quarter.norm $(DATA_DIR)/2011-1st-quarter.norm $(DATA_DIR)/2011-2nd-quarter.norm $(DATA_DIR)/2011-3rd-quarter.norm $(DATA_DIR)/2011-4th-quarter.norm $(DATA_DIR)/2012-1st-quarter.norm $(DATA_DIR)/2012-2nd-quarter.norm $(DATA_DIR)/2012-3rd-quarter.norm $(DATA_DIR)/2012-4th-quarter.norm $(DATA_DIR)/2013-1st-quarter.norm 

MERGED=data/merged.rides

RIDES_NORM_DB=data/rides_normalized.db
RIDES_DENORM_DB=data/rides_denormalized.db

STATIONS=$(DATA_DIR)/bikeStations.xml
STATION_INFO=$(DATA_DIR)/stations.txt

LOCATIONS_FILE=$(DATA_DIR)/locations.txt
BIKES_FILE=$(DATA_DIR)/bikes.txt
TYPES_FILE=$(DATA_DIR)/types.txt


POPULAR_START_STATIONS=$(DATA_DIR)/popular_start.txt
POPULAR_END_STATIONS=$(DATA_DIR)/popular_end.txt
POPULAR_ROUTES=$(DATA_DIR)/popular_routes.txt
POPULAR_ROUTES_MONTHLY=$(DATA_DIR)/popular_routes_monthly.txt
POPULAR_ROUTES_MONTHLY_JSON=$(DATA_DIR)/popular_routes_monthly.json


###########################################################################
# The basics

all: $(MERGED) $(STATIONS) $(STATION_INFO) popular ui

# Cleans up all the generated working files
clean:
	-rm $(DATA_DIR)/*.norm
	-rm $(DATA_DIR)/*.txt
	-rm $(DATA_DIR)/*.rides
	-rm $(DATA_DIR)/*.db

# Cleans up the raw downloaded data (this shouldn't be needed very often)
clean_data:
	-rm $(DATA_DIR)/*.csv
	-rm $(DATA_DIR)/*.xml



###########################################################################
# Real data processing

popular: $(POPULAR_START_STATIONS) $(POPULAR_END_STATIONS) $(POPULAR_ROUTES) $(POPULAR_ROUTES_MONTHLY)

$(POPULAR_START_STATIONS): $(RIDES_DENORM_DB)
	echo ".separator , \n select startterminal, startname, startlat, startlon, count(*) cnt from fullrides group by startterminal, startname, startlat, startlon order by cnt desc;" | sqlite3 $(RIDES_DENORM_DB) > $(POPULAR_START_STATIONS)

$(POPULAR_END_STATIONS): $(RIDES_DENORM_DB)
	echo ".separator , \n select endterminal, endname, endlat, endlon, count(*) cnt from fullrides group by endterminal, endname, endlat, endlon order by cnt desc;" | sqlite3 $(RIDES_DENORM_DB) > $(POPULAR_END_STATIONS)

$(POPULAR_ROUTES): $(RIDES_DENORM_DB)
	echo ".separator , \n select  startterminal, startname, startlat, startlon, endterminal, endname, endlat, endlon, count(*) cnt from fullrides group by  startterminal, startname, startlat, startlon, endterminal, endname, endlat, endlon order by cnt desc;" | sqlite3 $(RIDES_DENORM_DB) > $(POPULAR_ROUTES)

$(POPULAR_ROUTES_MONTHLY): $(RIDES_DENORM_DB)
	echo ".separator , \n select  strftime('%Y-%m',startdate) as month, startterminal, startname, startlat, startlon, endterminal, endname, endlat, endlon, count(*) cnt from fullrides group by  month, startterminal, startname, startlat, startlon, endterminal, endname, endlat, endlon order by month, cnt desc;" | sqlite3 $(RIDES_DENORM_DB) > $(POPULAR_ROUTES_MONTHLY)



###########################################################################
# UI related things

ui: $(POPULAR_ROUTES_MONTHLY_JSON)

$(POPULAR_ROUTES_MONTHLY_JSON): $(POPULAR_ROUTES_MONTHLY) csvToJson.py
	cat $(POPULAR_ROUTES_MONTHLY) | python csvToJson.py month,startterminal,startname,startlat,startlon,endterminal,endname,endlat,endlon,count > $(POPULAR_ROUTES_MONTHLY_JSON)




###########################################################################
# Data conversion

$(STATION_INFO): $(STATIONS) stationLocation.py
	python stationLocation.py | sort > $(STATION_INFO)


# Sanity check the location to make sure we have geo data for all the used locations
location_check: $(LOCATIONS_FILE) $(STATION_INFO)
	join -t, -e MISSING -o 1.1,2.1,2.2,2.3 -a 1 $(LOCATIONS_FILE) $(STATION_INFO) | grep MISSING

$(MERGED): $(QUARTERS)
	# Merging all the normalized data
	cat $(QUARTERS) > $(MERGED)

db: $(RIDES_NORM_DB) $(RIDES_DENORM_DB)

$(RIDES_NORM_DB) $(RIDES_DENORM_DB): $(MERGED) toDb.sql
	# Generating sqlite databases, this takes a while
	sqlite3 < toDb.sql




# late 2012 and 2013 are the same
$(DATA_DIR)/2013-1st-quarter.norm: $(DATA_DIR)/2013-1st-quarter.csv
	cat $(DATA_DIR)/2013-1st-quarter.csv | tail -n+2 | python normalize.py 2013 > $(DATA_DIR)/2013-1st-quarter.norm

$(DATA_DIR)/2012-4th-quarter.norm: $(DATA_DIR)/2012-4th-quarter.csv
	cat $(DATA_DIR)/2012-4th-quarter.csv | tail -n+2 | python normalize.py 2012_late > $(DATA_DIR)/2012-4th-quarter.norm

$(DATA_DIR)/2012-3rd-quarter.norm: $(DATA_DIR)/2012-3rd-quarter.csv
	cat $(DATA_DIR)/2012-3rd-quarter.csv | tail -n+2 | python normalize.py 2012_late > $(DATA_DIR)/2012-3rd-quarter.norm

# 2 quarters in 2012 added an extra column that's not needed
$(DATA_DIR)/2012-2nd-quarter.norm: $(DATA_DIR)/2012-2nd-quarter.csv
	cat $(DATA_DIR)/2012-2nd-quarter.csv | tail -n+2 | python normalize.py 2012_early > $(DATA_DIR)/2012-2nd-quarter.norm

$(DATA_DIR)/2012-1st-quarter.norm: $(DATA_DIR)/2012-1st-quarter.csv
	cat $(DATA_DIR)/2012-1st-quarter.csv | tail -n+2 | python normalize.py 2012_early > $(DATA_DIR)/2012-1st-quarter.norm

# 2010 and 2011 are the same format
$(DATA_DIR)/2011-4th-quarter.norm: $(DATA_DIR)/2011-4th-quarter.csv
	cat $(DATA_DIR)/2011-4th-quarter.csv | tail -n+2 | python normalize.py 2011  > $(DATA_DIR)/2011-4th-quarter.norm

$(DATA_DIR)/2011-3rd-quarter.norm: $(DATA_DIR)/2011-3rd-quarter.csv
	cat $(DATA_DIR)/2011-3rd-quarter.csv | tail -n+2 | python normalize.py 2011 > $(DATA_DIR)/2011-3rd-quarter.norm

$(DATA_DIR)/2011-2nd-quarter.norm: $(DATA_DIR)/2011-2nd-quarter.csv
	cat $(DATA_DIR)/2011-2nd-quarter.csv | tail -n+2 | python normalize.py 2011 > $(DATA_DIR)/2011-2nd-quarter.norm

$(DATA_DIR)/2011-1st-quarter.norm: $(DATA_DIR)/2011-1st-quarter.csv
	cat $(DATA_DIR)/2011-1st-quarter.csv | tail -n+2 | python normalize.py 2011 > $(DATA_DIR)/2011-1st-quarter.norm

$(DATA_DIR)/2010-4th-quarter.norm: $(DATA_DIR)/2010-4th-quarter.csv
	cat $(DATA_DIR)/2010-4th-quarter.csv | tail -n+2 | python normalize.py 2010 > $(DATA_DIR)/2010-4th-quarter.norm



# rule to download the main data files
%.csv:
	curl -o $*.csv http://www.capitalbikeshare.com/assets/files/trip-history-data/`basename $*`.csv

# Thanks to https://github.com/nelsonmc/bikeshare-tracker for this one, I couldn't find it listed on the bikeshare site
$(STATIONS):
	curl -o $(STATIONS) http://www.capitalbikeshare.com/data/stations/bikeStations.xml



###########################################################################
# A few helpers for sanity checking the data


# Extract some really basic info to sanity check that the data looks good
extra_info: $(LOCATIONS_FILE) $(BIKES_FILE) $(TYPES_FILE)

# Extract unique location names from the trip files
# This is really for info only since it's available in the $(STATIONS) file
$(LOCATIONS_FILE): $(MERGED)
	# Extract unique location data
	# ***   This takes a little while    ****
	cat $(MERGED) | cut -d, -f 3,5 | tr "," "\n" | sort | uniq > $(LOCATIONS_FILE)

# Extract distinct bikes
$(BIKES_FILE): $(MERGED)
	# ***   This takes a little while    ****
	cat $(MERGED) | cut -d, -f 6 | sort | uniq > $(BIKES_FILE)

# Extract distinct subscription types
$(TYPES_FILE): $(MERGED)
	# ***   This takes a little while    ****
	cat $(MERGED) | cut -d, -f 7 | sort | uniq > $(TYPES_FILE)


