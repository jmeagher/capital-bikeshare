

DATA_DIR=data
DOWNLOAD_FILES=$(DATA_DIR)/2010-4th-quarter.csv $(DATA_DIR)/2011-1st-quarter.csv $(DATA_DIR)/2011-2nd-quarter.csv $(DATA_DIR)/2011-3rd-quarter.csv $(DATA_DIR)/2011-4th-quarter.csv $(DATA_DIR)/2012-1st-quarter.csv $(DATA_DIR)/2012-2nd-quarter.csv $(DATA_DIR)/2012-3rd-quarter.csv $(DATA_DIR)/2012-4th-quarter.csv $(DATA_DIR)/2013-1st-quarter.csv 
LOCATIONS_FILE=$(DATA_DIR)/locations.txt


# Easier rules

all: download locations

download: $(DOWNLOAD_FILES)

locations: $(LOCATIONS_FILE)


# Extract unique location names from the trip files
$(LOCATIONS_FILE): $(DOWNLOAD_FILES)
	cat $(DATA_DIR)/*.csv | cut -d, -f4-5 | tr "," "\n" | sort | uniq > $(LOCATIONS_FILE)



clean:
	-rm $(LOCATIONS_FILE)


clean_data:
	-rm $(DATA_DIR)/*.csv

# rule to download the main data files
%.csv:
	curl -o $*.csv http://www.capitalbikeshare.com/assets/files/trip-history-data/`basename $*`.csv


