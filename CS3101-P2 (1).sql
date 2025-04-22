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
-------------------------------------------------------------------------------

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

-------------------------------------------------------------------------------
-- [Trigger to Enforce Arrival Before Departure]

delimiter $$

create trigger check_arrival_before_departure
before insert on stop
for each row
begin
    declare v_ddh int(2); -- Departure hour
    declare v_ddm int(2); -- Departure minute

    -- Retrieve the departure time from the plan table
    select ddh, ddm
    into v_ddh, v_ddm
    from plan
    where hc = new.hc and frm = new.frm and loc = new.loc;

    -- Validate that arrival time is not after departure time
    if (new.adh > v_ddh or (new.adh = v_ddh and new.adm > v_ddm)) then
        signal sqlstate '45000'
        set message_text = 'Arrival time cannot be after departure time.';
    end if;
end$$

delimiter ;

-------------------------------------------------------------------------------

