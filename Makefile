DATA_DIR=data

QUARTERS= $(DATA_DIR)/2010-4th-quarter.norm $(DATA_DIR)/2011-1st-quarter.norm $(DATA_DIR)/2011-2nd-quarter.norm $(DATA_DIR)/2011-3rd-quarter.norm $(DATA_DIR)/2011-4th-quarter.norm $(DATA_DIR)/2012-1st-quarter.norm $(DATA_DIR)/2012-2nd-quarter.norm $(DATA_DIR)/2012-3rd-quarter.norm $(DATA_DIR)/2012-4th-quarter.norm $(DATA_DIR)/2013-1st-quarter.norm $(DATA_DIR)/2013-2nd-quarter.norm

MERGED=data/merged.rides

RIDES_NORM_DB=data/rides_normalized.db
RIDES_DENORM_DB=data/rides_denormalized.db

STATIONS=$(DATA_DIR)/bikeStations.xml
STATION_INFO=$(DATA_DIR)/stations.txt

ZIP_CODES=$(DATA_DIR)/zipCodes.zips
ZIP_CODES_HEADLESS=$(DATA_DIR)/zipCodes_headless.txt

DC_GEO=$(DATA_DIR)/DC.geojson
DC_TOPO=$(DATA_DIR)/DC.topojson

LOCATIONS_FILE=$(DATA_DIR)/locations.txt
BIKES_FILE=$(DATA_DIR)/bikes.txt
TYPES_FILE=$(DATA_DIR)/types.txt


POPULAR_START_STATIONS=$(DATA_DIR)/popular_start.txt
POPULAR_END_STATIONS=$(DATA_DIR)/popular_end.txt
POPULAR_ROUTES=$(DATA_DIR)/popular_routes.txt
POPULAR_ROUTES_MONTHLY=$(DATA_DIR)/popular_routes_monthly.txt
POPULAR_ROUTES_MONTHLY_JSON=$(DATA_DIR)/popular_routes_monthly.json

MONTHLY_STATS=$(DATA_DIR)/monthly.txt
MONTHLY_STATS_JSON=$(DATA_DIR)/monthly.json


###########################################################################
# The basics

all: $(POPULAR_ROUTES_MONTHLY) $(MONTHLY_STATS) geo

# Runs a simple python server for viewing the UI pages locally
pyserver:
	python -m SimpleHTTPServer

# Cleans up all the generated working files
clean:
	-rm $(DATA_DIR)/*.norm
	-rm $(DATA_DIR)/*.txt
	-rm $(DATA_DIR)/*.rides
	-rm $(DATA_DIR)/*.db
	-rm $(DATA_DIR)/*.geojson
	-rm $(DATA_DIR)/*.topojson

# Cleans up the raw downloaded data (this shouldn't be needed very often)
clean_data:
	-rm $(DATA_DIR)/*.csv
	-rm $(DATA_DIR)/*.xml
	-rm $(DATA_DIR)/*.zips
	-rm -rf $(DATA_DIR)/*.shp

geo: $(DC_TOPO)


###########################################################################
# Real data processing
analysis: popular stats

popular: $(POPULAR_START_STATIONS) $(POPULAR_END_STATIONS) $(POPULAR_ROUTES) $(POPULAR_ROUTES_MONTHLY)

$(POPULAR_START_STATIONS): $(RIDES_DENORM_DB)
	echo ".separator , \n.header ON \n select startterminal, startname, startlat, startlon, startzip count(*) rides, sum(durationsec) totalsec from fullrides group by startterminal, startname, startlat, startlon order by rides desc;" | sqlite3 $(RIDES_DENORM_DB) > $(POPULAR_START_STATIONS)

$(POPULAR_END_STATIONS): $(RIDES_DENORM_DB)
	echo ".separator , \n.header ON \n select endterminal, endname, endlat, endlon, endzip, count(*) rides, sum(durationsec) totalsec from fullrides group by endterminal, endname, endlat, endlon order by rides desc;" | sqlite3 $(RIDES_DENORM_DB) > $(POPULAR_END_STATIONS)

$(POPULAR_ROUTES): $(RIDES_DENORM_DB)
	echo ".separator , \n.header ON \n select  startterminal, startname, startlat, startlon, startzip, endterminal, endname, endlat, endlon, endzip, count(*) rides, sum(durationsec) totalsec from fullrides group by  startterminal, startname, startlat, startlon, endterminal, endname, endlat, endlon order by rides desc;" | sqlite3 $(RIDES_DENORM_DB) > $(POPULAR_ROUTES)

$(POPULAR_ROUTES_MONTHLY): $(RIDES_DENORM_DB)
	echo ".separator , \n.header ON \n select  strftime('%Y-%m',startdate) as month, startterminal, startname, startlat, startlon, startzip, endterminal, endname, endlat, endlon, endzip, count(*) rides, sum(durationsec) totalsec from fullrides group by  month, startterminal, startname, startlat, startlon, endterminal, endname, endlat, endlon order by month, rides desc;" | sqlite3 $(RIDES_DENORM_DB) > $(POPULAR_ROUTES_MONTHLY)

stats: $(MONTHLY_STATS)

$(MONTHLY_STATS): $(RIDES_NORM_DB)
	echo ".separator , \n.header ON \n select  strftime('%Y-%m',startdate) as month, count(*) rides, sum(durationsec) total_sec, count(distinct bike) bike_count, count(distinct startterminal) terminal_count from rides group by month order by month;" | sqlite3 $(RIDES_NORM_DB) > $(MONTHLY_STATS)

###########################################################################
# UI related things


$(POPULAR_ROUTES_MONTHLY_JSON): $(POPULAR_ROUTES_MONTHLY) csvToJson.py
	cat $(POPULAR_ROUTES_MONTHLY) | python csvToJson.py month,startterminal,startname,startlat,startlon,endterminal,endname,endlat,endlon,count > $(POPULAR_ROUTES_MONTHLY_JSON)

$(MONTHLY_STATS_JSON): $(MONTHLY_STATS) csvToJson.py
	cat $(MONTHLY_STATS) | python csvToJson.py month,rides,total_sec > $(MONTHLY_STATS_JSON)




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

$(RIDES_NORM_DB) $(RIDES_DENORM_DB): .makedb

.makedb: $(MERGED) toDb.sql $(STATION_INFO) $(ZIP_CODES_HEADLESS) 
	# Generating sqlite databases, this takes a while
	sqlite3 < toDb.sql
	touch .makedb




# late 2012 and 2013 are the same
$(DATA_DIR)/2013-2nd-quarter.norm: $(DATA_DIR)/2013-2nd-quarter.csv
	cat $(DATA_DIR)/2013-2nd-quarter.csv | tail -n+2 | python normalize.py 2013 > $(DATA_DIR)/2013-2nd-quarter.norm

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

$(ZIP_CODES):
	curl -o $(ZIP_CODES) http://geocommons.com/overlays/112367.csv

$(ZIP_CODES_HEADLESS): $(ZIP_CODES)
	tail -n+2 $(ZIP_CODES) > $(ZIP_CODES_HEADLESS)


%.topojson: %.geojson
	echo Convert $*.geojson to topojson
	topojson --bbox --id-propery GIS_ID -p name=NAME -p name -o $*.topojson $*.geojson


$(DC_GEO):
	curl -o $(DC_GEO) https://raw.github.com/benbalter/dc-maps/master/zip-codes.geojson


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


###########################################################################
# Attic for things that might need to be revived later


# This doesn't work well, but leaving it here in case it needs to be revived
#%.geojson: %.shp
#	#39.069, -77.295
#	#38.784, -76.829
#	ogr2ogr -f GeoJSON $*.geojson $*.shp/*.shp -clipdst -78.2 36.0 -75.8 40.0
#
# DC=11 MD=24 VA=51
#$(DC_SHP):
#	mkdir -p $(DC_SHP); cd $(DC_SHP); curl -o DC.zip ftp://ftp2.census.gov/geo/tiger/TIGER2012/COUSUB/tl_2012_11_cousub.zip; unzip *.zip
#$(MD_SHP):
#	mkdir -p $(MD_SHP); cd $(MD_SHP); curl -o MD.zip ftp://ftp2.census.gov/geo/tiger/TIGER2012/COUSUB/tl_2012_24_cousub.zip; unzip *.zip
#$(VA_SHP):
#	mkdir -p $(VA_SHP); cd $(VA_SHP); curl -o VA.zip ftp://ftp2.census.gov/geo/tiger/TIGER2012/COUSUB/tl_2012_51_cousub.zip; unzip *.zip

