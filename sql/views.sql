-- 03_views.sql
-- Create the required views for CS3101 P2

USE cs3101p2;

-- 1. trainLEV: all services for train 170406
CREATE OR REPLACE VIEW trainLEV AS
SELECT
  s.hc,
  r.orig                AS orig,
  CONCAT(s.dh, s.dm)    AS dep
FROM service s
JOIN route   r         ON s.hc = r.hc
WHERE s.uid = '170406'
ORDER BY s.dh, s.dm;

-- 2. scheduleEDB: all services departing Edinburgh (EDB)
CREATE OR REPLACE VIEW scheduleEDB AS
SELECT
  s.hc,
  CONCAT(s.dh, s.dm)             AS dep,
  s.pl                          AS pl,
  COALESCE(next_st.code, p.loc) AS dest,
  (
    SELECT COUNT(*)
      FROM coach c
     WHERE c.uid = s.uid
  )                              AS len,
  s.toc
FROM service s
JOIN route    r         ON s.hc = r.hc
JOIN station  st_orig   ON r.orig = st_orig.loc
LEFT JOIN plan      p         ON p.hc = s.hc AND p.frm = r.orig
LEFT JOIN station   next_st   ON next_st.loc = p.loc
WHERE st_orig.code = 'EDB'
ORDER BY s.dh, s.dm;

-- 3. serviceEDBDEE: sequence of stops for the 18:59 1L27 service
CREATE OR REPLACE VIEW serviceEDBDEE AS
-- origin row
SELECT
  r.orig                          AS loc,
  st_o.code                       AS stn,
  s.pl                            AS pl,
  NULL                            AS arr,
  CONCAT(s.dh, s.dm)              AS dep
FROM service s
JOIN route    r    ON s.hc = r.hc
JOIN station  st_o ON r.orig = st_o.loc
WHERE s.hc = '1L27'
  AND s.dh = '18'
  AND s.dm = '59'

UNION ALL

-- intermediate stops where the train stops
SELECT
  p.loc                           AS loc,
  st_i.code                       AS stn,
  sp.pl                           AS pl,
  CONCAT(LPAD(sp.adh, 2, '0'), LPAD(sp.adm, 2, '0')) AS arr,
  CONCAT(LPAD(p.ddh, 2, '0'), LPAD(p.ddm, 2, '0'))   AS dep
FROM plan p
JOIN service s ON p.hc = s.hc
  AND s.hc = '1L27' AND s.dh = '18' AND s.dm = '59'
JOIN stop    sp ON sp.hc = p.hc AND sp.frm = p.frm AND sp.loc = p.loc
JOIN station st_i ON p.loc = st_i.loc

UNION ALL

-- destination stop (infinite departure differential)
SELECT
  p.loc                           AS loc,
  st_d.code                       AS stn,
  sp.pl                           AS pl,
  CONCAT(LPAD(sp.adh, 2, '0'), LPAD(sp.adm, 2, '0')) AS arr,
  NULL                            AS dep
FROM plan p
JOIN service s ON p.hc = s.hc
  AND s.hc = '1L27' AND s.dh = '18' AND s.dm = '59'
JOIN stop    sp ON sp.hc = p.hc AND sp.frm = p.frm AND sp.loc = p.loc
JOIN station st_d ON p.loc = st_d.loc
WHERE p.ddh = 'ω'

ORDER BY dep;
