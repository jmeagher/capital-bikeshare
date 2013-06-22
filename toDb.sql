create table rides(
    durationsec integer,
    startdate date,
    startterminal integer,
    enddate date,
    endterminal integer,
    bike varchar(8),
    ridertype varchar(12)
);

.separator ,
.import data/merged.rides rides

create table locations(
    terminal integer,
    lat float,
    lon float,
    name varchar(40)
);
.separator ,
.import data/stations.txt locations

.backup data/rides_normalized.db

create table fullrides as
select r.durationsec, 
    r.startdate, r.startterminal, lstart.lat as startlat, lstart.lon as startlon, lstart.name as startname,
    r.enddate, r.endterminal, lend.lat as endlat, lend.lon as endlon, lend.name as endname,
    r.bike, r.ridertype
from rides r
join locations lstart
on r.startterminal = lstart.terminal
join locations lend
on r.endterminal = lend.terminal
;

drop table locations;
drop table rides;

.backup data/rides_denormalized.db

