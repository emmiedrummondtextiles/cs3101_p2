
drop table if exists service;
drop table if exists stop;
drop table if exists plan;
drop table if exists route;
drop table if exists coach;
drop table if exists train;
drop table if exists station;
drop table if exists location;

-------------------------------------------------------------------------------
-- [Locations and Stations]

create table if not exists
  location(loc varchar(30) primary key);
create table if not exists
  station(
    loc varchar(30),
    code char(3) unique not null check (binary code=upper(code)),
    primary key (loc),
    foreign key (loc) references location (loc)
  );

insert into location values
  ("Edinburgh"),
  ("Princes St Gardens"),
  ("Haymarket"),
  ("Haymarket Central Jn"),
  ("Haymarket West Jn"),
  ("South Gyle"),
  ("Edinburgh Gateway"),
  ("Dalmeny Jn"),
  ("Dalmeny D.P.L."),
  ("Dalmeny"),
  ("North Queensferry"),
  ("Inverkeithing South Jn"),
  ("Inverkeithing"),
  ("Inverkeithing East Jn"),
  ("Dalgety Bay"),
  ("Aberdour"),
  ("Burntisland"),
  ("Kinghorn"),
  ("Kirkcaldy"),
  ("Thornton South Jn"),
  ("Thornton North Jn"),
  ("Markinch"),
  ("Ladybank"),
  ("Springfield"),
  ("Cupar"),
  ("Leuchars"),
  ("Tay Bridge South"),
  ("Dundee Central Jn"),
  ("Dundee");
insert into location values
  ("St. Fort Signal Ts26"),
  ("Inverkeithing U.P.L."),
  ("Dalmeny U.P.L.");
insert into location values
  ("Earlseat Junction"),
  ("Cameron Bridge"),
  ("Leven");
insert into station values
  ("Edinburgh", "EDB"),
  ("Haymarket", "HYM"),
  ("South Gyle", "SGL"),
  ("Edinburgh Gateway", "EGY"),
  ("Dalmeny", "DAM"),
  ("North Queensferry", "NQU"),
  ("Inverkeithing", "INK"),
  ("Dalgety Bay", "DAG"),
  ("Aberdour", "AUR"),
  ("Burntisland", "BTS"),
  ("Kinghorn", "KGH"),
  ("Kirkcaldy", "KDY"),
  ("Markinch", "MNC"),
  ("Ladybank", "LDY"),
  ("Springfield", "SPF"),
  ("Cupar", "CUP"),
  ("Leuchars", "LEU"),
  ("Dundee", "DEE"),
  ("Cameron Bridge", "CBX"),
  ("Leven", "LEV");

-------------------------------------------------------------------------------
-- [Trains]

create table if not exists
  train(
    uid char(6) check (uid regexp '[0-9]{6}'),
    primary key (uid)
  );
create table if not exists
  coach(
    uid char(6) references train(uid),
    lid char(1) check (binary lid=upper(lid)),
    primary key (uid, lid)
  );

insert into train values
  ("158704"),
  ("170406"),
  ("170394"),
  ("390124");
insert into coach values
  ("158704","A"),
  ("158704","B"),
  ("170406","A"),
  ("170406","B"),
  ("170406","C"),
  ("170394","A"),
  ("170394","B"),
  ("170394","C"),
  ("390124","A"),
  ("390124","B"),
  ("390124","C"),
  ("390124","D"),
  ("390124","E"),
  ("390124","F"),
  ("390124","U"),
  ("390124","G"),
  ("390124","H"),
  ("390124","J"),
  ("390124","K");

-------------------------------------------------------------------------------
-- [Services]

create table if not exists
  route(
    hc char(4) check(hc regexp '[0-9][A-Z][0-99]'),
    orig char(30) references location(loc),
    primary key (hc,orig)
  );

create table if not exists
  plan(
    hc char(4) references route(hc),
    frm varchar(30) references location(loc),
    loc varchar(30) not null references location(loc),
    ddh int(2) zerofill check(ddh <= 24),
    ddm int(2) zerofill check(ddm <= 60),
    primary key (hc,frm)
  );

create table if not exists
  stop(
    hc char(4) references plan(hc),
    frm varchar(30) references plan(frm),
    loc varchar(30) references plan(loc),
    adh int(2) zerofill not null check(adh <= 24),
    adm int(2) zerofill not null check(adm <= 60),
    pl  int unsigned not null,
    primary key (hc,frm,loc)
  );

create table if not exists
  service(
    hc char(4) references route(hc),
    dh int(2) zerofill not null check(dh <= 24),
    dm int(2) zerofill not null check(dm <= 60),
    pl int unsigned not null,
    uid char(6) not null references train(uid),
    toc char(2) not null check (
      binary toc = upper(toc)
      and
      (toc = "VT"
        or toc = "CS"
        or toc = "XC"
        or toc = "SR"
        or toc = "GR"
        or toc = "GW")
    ),
    primary key (hc,dh,dm)
  );

insert into route values
  ("2K69","Edinburgh"),
  ("1L27","Edinburgh"),
  ("1L32","Dundee");

insert into service values
  ("2K69",15,03,16,170406,"SR"),
  ("1L27",09,01,19,170394,"SR"),
  ("1L27",18,59,20,158704,"SR"),
  ("1L32",20,44,3,158704,"SR");

insert into plan values
  ("2K69","Edinburgh",             "Princes St Gardens",     00, 02),
  ("2K69","Princes St Gardens",    "Haymarket",              00, 03),
  ("2K69","Haymarket",             "Haymarket Central Jn",   00, 01),
  ("2K69","Haymarket Central Jn",  "Haymarket West Jn",      00, 01),
  ("2K69","Haymarket West Jn",     "South Gyle",             00, 02),
  ("2K69","South Gyle",            "Edinburgh Gateway",      00, 02),
  ("2K69","Edinburgh Gateway",     "Dalmeny Jn",             00, 04),
  ("2K69","Dalmeny Jn",            "Dalmeny D.P.L.",         00, 01),
  ("2K69","Dalmeny D.P.L.",        "Dalmeny",                00, 01),
  ("2K69","Dalmeny",               "North Queensferry",      00, 04),
  ("2K69","North Queensferry",     "Inverkeithing South Jn", 00, 02),
  ("2K69","Inverkeithing South Jn","Inverkeithing",          00, 02),
  ("2K69","Inverkeithing",         "Inverkeithing East Jn",  00, 01),
  ("2K69","Inverkeithing East Jn", "Dalgety Bay",            00, 02),
  ("2K69","Dalgety Bay",           "Aberdour",               00, 05),
  ("2K69","Aberdour",              "Burntisland",            00, 04),
  ("2K69","Burntisland",           "Kinghorn",               00, 05),
  ("2K69","Kinghorn",              "Kirkcaldy",              00, 05),
  ("2K69","Kirkcaldy",             "Thornton South Jn",      00, 05),
  ("2K69","Thornton South Jn",     "Thornton North Jn",      00, 02),
  ("2K69","Thornton North Jn",     "Earlseat Junction",      00, 01),
  ("2K69","Earlseat Junction",     "Cameron Bridge",         00, 06),
  ("2K69","Cameron Bridge",        "Leven",                  null, null);

insert into stop values
  ("2K69","Princes St Gardens",    "Haymarket",              00, 02, 2),
  ("2K69","South Gyle",            "Edinburgh Gateway",      00, 01, 2),
  ("2K69","Dalmeny D.P.L.",        "Dalmeny",                00, 01, 2),
  ("2K69","Dalmeny",               "North Queensferry",      00, 03, 2),
  ("2K69","Inverkeithing South Jn","Inverkeithing",          00, 01, 2),
  ("2K69","Inverkeithing East Jn", "Dalgety Bay",            00, 02, 2),
  ("2K69","Dalgety Bay",           "Aberdour",               00, 03, 2),
  ("2K69","Aberdour",              "Burntisland",            00, 03, 2),
  ("2K69","Burntisland",           "Kinghorn",               00, 04, 2),
  ("2K69","Kinghorn",              "Kirkcaldy",              00, 04, 2),
  ("2K69","Earlseat Junction",     "Cameron Bridge",         00, 05, 2),
  ("2K69","Cameron Bridge",        "Leven",                  00, 04, 1);

insert into plan values
  ("1L27","Edinburgh",             "Princes St Gardens",     00, 02),
  ("1L27","Princes St Gardens",    "Haymarket",              00, 03),
  ("1L27","Haymarket",             "Haymarket Central Jn",   00, 01),
  ("1L27","Haymarket Central Jn",  "Haymarket West Jn",      00, 01),
  ("1L27","Haymarket West Jn",     "South Gyle",             00, 02),
  ("1L27","South Gyle",            "Edinburgh Gateway",      00, 02),
  ("1L27","Edinburgh Gateway",     "Dalmeny Jn",             00, 04),
  ("1L27","Dalmeny Jn",            "Dalmeny D.P.L.",         00, 01),
  ("1L27","Dalmeny D.P.L.",        "Dalmeny",                00, 01),
  ("1L27","Dalmeny",               "North Queensferry",      00, 04),
  ("1L27","North Queensferry",     "Inverkeithing South Jn", 00, 02),
  ("1L27","Inverkeithing South Jn","Inverkeithing",          00, 02),
  ("1L27","Inverkeithing",         "Inverkeithing East Jn",  00, 01),
  ("1L27","Inverkeithing East Jn", "Dalgety Bay",            00, 02),
  ("1L27","Dalgety Bay",           "Aberdour",               00, 05),
  ("1L27","Aberdour",              "Burntisland",            00, 04),
  ("1L27","Burntisland",           "Kinghorn",               00, 05),
  ("1L27","Kinghorn",              "Kirkcaldy",              00, 05),
  ("1L27","Kirkcaldy",             "Thornton South Jn",      00, 05),
  ("1L27","Thornton South Jn",     "Thornton North Jn",      00, 02),
  ("1L27","Thornton North Jn",     "Markinch",               00, 04),
  ("1L27","Markinch",              "Ladybank",               00, 08),
  ("1L27","Ladybank",              "Springfield",            00, 04),
  ("1L27","Springfield",           "Cupar",                  00, 04),
  ("1L27","Cupar",                 "Leuchars",               00, 07),
  ("1L27","Leuchars",              "Tay Bridge South",       00, 07),
  ("1L27","Tay Bridge South",      "Dundee Central Jn",      00, 06),
  ("1L27","Dundee Central Jn",     "Dundee",                 null, null);

insert into stop values
  ("1L27","Princes St Gardens",    "Haymarket",              00, 03, 2),
  ("1L27","South Gyle",            "Edinburgh Gateway",      00, 01, 2),
  ("1L27","Inverkeithing South Jn","Inverkeithing",          00, 01, 2),
  ("1L27","Kinghorn",              "Kirkcaldy",              00, 04, 2),
  ("1L27","Thornton North Jn",     "Markinch",               00, 03, 2),
  ("1L27","Markinch",              "Ladybank",               00, 06, 2),
  ("1L27","Springfield",           "Cupar",                  00, 03, 2),
  ("1L27","Cupar",                 "Leuchars",               00, 06, 2),
  ("1L27","Dundee Central Jn",     "Dundee",                 00, 01, 3);

insert into plan values
  ("1L32","Dundee",                "Dundee Central Jn"      , 00, 01),
  ("1L32","Dundee Central Jn",     "Tay Bridge South"       , 00, 05),
  ("1L32","Tay Bridge South",      "St. Fort Signal Ts26"   , 00, 03),
  ("1L32","St. Fort Signal Ts26",  "Leuchars"               , 00, 04),
  ("1L32","Leuchars",              "Cupar"                  , 00, 08),
  ("1L32","Cupar",                 "Springfield"            , 00, 03),
  ("1L32","Springfield",           "Ladybank"               , 00, 04),
  ("1L32","Ladybank",              "Markinch"               , 00, 08),
  ("1L32","Markinch",              "Thornton North Jn"      , 00, 03),
  ("1L32","Thornton North Jn",     "Thornton South Jn"      , 00, 01),
  ("1L32","Thornton South Jn",     "Kirkcaldy"              , 00, 06),
  ("1L32","Kirkcaldy",             "Kinghorn"               , 00, 04),
  ("1L32","Kinghorn",              "Burntisland"            , 00, 03),
  ("1L32","Burntisland",           "Aberdour"               , 00, 04),
  ("1L32","Aberdour",              "Dalgety Bay"            , 00, 03),
  ("1L32","Dalgety Bay",           "Inverkeithing East Jn"  , 00, 01),
  ("1L32","Inverkeithing East Jn", "Inverkeithing U.P.L."   , 00, 01),
  ("1L32","Inverkeithing U.P.L.",  "Inverkeithing"          , 00, 01),
  ("1L32","Inverkeithing",         "Inverkeithing South Jn" , 00, 01),
  ("1L32","Inverkeithing South Jn","North Queensferry"      , 00, 03),
  ("1L32","North Queensferry",     "Dalmeny"                , 00, 03),
  ("1L32","Dalmeny",               "Dalmeny U.P.L."         , 00, 01),
  ("1L32","Dalmeny U.P.L.",        "Dalmeny Jn"             , 00, 01),
  ("1L32","Dalmeny Jn",            "Edinburgh Gateway"      , 00, 04),
  ("1L32","Edinburgh Gateway",     "South Gyle"             , 00, 02),
  ("1L32","South Gyle",            "Haymarket West Jn"      , 00, 03),
  ("1L32","Haymarket West Jn",     "Haymarket Central Jn"   , 00, 01),
  ("1L32","Haymarket Central Jn",  "Haymarket"              , 00, 02),
  ("1L32","Haymarket",             "Princes St Gardens"     , 00, 02),
  ("1L32","Princes St Gardens",    "Edinburgh"              , null, null);

insert into stop values
  ("1L32","St. Fort Signal Ts26",  "Leuchars"               , 00, 03, 1),
  ("1L32","Leuchars",              "Cupar"                  , 00, 07, 1),
  ("1L32","Springfield",           "Ladybank"               , 00, 03, 1),
  ("1L32","Ladybank",              "Markinch"               , 00, 07, 1),
  ("1L32","Thornton South Jn",     "Kirkcaldy"              , 00, 05, 1),
  ("1L32","Inverkeithing U.P.L.",  "Inverkeithing"          , 00, 01, 1),
  ("1L32","Dalmeny Jn",            "Edinburgh Gateway"      , 00, 03, 1),
  ("1L32","Haymarket Central Jn",  "Haymarket"              , 00, 01, 1),
  ("1L32","Princes St Gardens",    "Edinburgh"              , 00, 02, 15);


-------------------------------------------------------------------------------

