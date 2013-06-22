create table rides(
    durationsec integer,
    startdate date,
    startlocation varchar(30),
    startterminal integer,
    enddate date,
    endlocation varchar(30),
    endterminal integer,
    bike varchar(8),
    ridertype varchar(12)
);

.separator ,
.import data/merged.rides rides;



