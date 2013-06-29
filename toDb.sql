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

create table locationsraw(
    terminal integer,
    lat float,
    lon float,
    name varchar(40)
);
.separator ,
.import data/stations.txt locationsraw

create table zipcodes(
    name varchar(40),
    area float,
    shapelen float,
    gis varchar(40),
    zipcode int,
    areatype varchar(20),
    uninsured varchar(20),
    url varchar(80),
    medicaid int,
    lat double,
    lon double
);
.separator ,
.import data/zipCodes_headless.txt zipcodes


-- Rudimentary check to find the "closest" zip code to the station
-- it's not perfect, but should be good enough a first pass
create table terminal_zip_distances as
select terminal, name, zipcode, latdiff*latdiff + londiff*londiff as distancesq
from (
    select l.terminal, l.name, z.zipcode, z.lat-l.lat as latdiff, z.lon-l.lon as londiff
    from locationsraw l
    join zipcodes z
    on 1=1
) a
;

create table closestzips as
select t1.*
from terminal_zip_distances t1
join (
    select terminal, min(distancesq) as mindist
    from terminal_zip_distances
    group by terminal
) t2 on t1.terminal = t2.terminal and t1.distancesq = t2.mindist
;

create table locations as
select lr.*, c.zipcode
from locationsraw lr
join closestzips c on lr.terminal = c.terminal
;

-- drop temp tables
drop table closestzips;
drop table terminal_zip_distances;


.backup data/rides_normalized.db

create table fullrides as
select r.durationsec, 
    r.startdate, r.startterminal, lstart.lat as startlat, lstart.lon as startlon, lstart.name as startname, lstart.zipcode as startzip,
    r.enddate, r.endterminal, lend.lat as endlat, lend.lon as endlon, lend.name as endname, lend.zipcode as endzip,
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

