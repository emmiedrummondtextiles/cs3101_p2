-- simplified view definitions matching lecture style

create view trainLEV as
 select s.hc, stn.code as orig, maketime(s.dh,s.dm,0) as dep
 from service s
 join route r using(hc)
 join station stn on stn.loc = r.orig
 where s.uid = '170406';

create view scheduleEDB as
 select s.hc,
        maketime(s.dh,s.dm,0) as dep,
        s.pl as pl,
        (select p2.loc
         from plan p2
         where p2.hc = s.hc and p2.frm = 'EDB'
         order by p2.ddh,p2.ddm limit 1) as dest,
        (select count(*) from coach c where c.uid = s.uid) as len,
        s.toc as toc
 from service s
 join route r using(hc)
 where r.orig = 'EDB';

create view serviceEDBDEE as
 select lo.loc as loc,
        stn.code as stn,
        lo.pl as pl,
        maketime(lo.adh,lo.adm,0) as arr,
        maketime(lo.ddh,lo.ddm,0) as dep
 from (
    select r.orig as loc,null as ddh,null as ddm,null as adh,null as adm,s.pl as pl
    from service s join route r using(hc)
    where s.hc='1L27' and s.dh=18 and s.dm=59
    union all
    select p.loc,p.ddh,p.ddm,st.adh,st.adm,st.pl
    from plan p join stop st using(hc,loc)
    where p.hc='1L27' and p.ddh is not null
    union all
    select p2.loc,null,null,st2.adh,st2.adm,null
    from plan p2 join stop st2 using(hc,loc)
    where p2.hc='1L27' and p2.ddh is null
 ) as lo
 left join station stn on stn.loc = lo.loc;


