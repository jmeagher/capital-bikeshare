import xml.etree.ElementTree as ET
tree = ET.parse('data/bikeStations.xml')
root = tree.getroot()

for station in root:
    print station.find('terminalName').text + "," + station.find('lat').text + "," + station.find('long').text + "," + station.find('name').text


