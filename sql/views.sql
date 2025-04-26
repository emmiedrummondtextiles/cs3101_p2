-- views.sql: define the three required views

-- 1. Services on which train 170406 operates (trainLEV)
CREATE OR REPLACE VIEW trainLEV AS
SELECT
    s.hc,
    r.orig   AS orig,
    MAKETIME(s.dh, s.dm, 0) AS dep
FROM service s
JOIN route r USING (hc)
WHERE s.uid = '170406'
ORDER BY dep;

-- 2. Services departing Edinburgh (EDB) (scheduleEDB)
CREATE OR REPLACE VIEW scheduleEDB AS
SELECT
    s.hc,
    MAKETIME(s.dh, s.dm, 0)                              AS dep,
    st.pl                                                 AS pl,
    (
      SELECT p2.loc
      FROM plan p2
      WHERE p2.hc = s.hc
        AND p2.frm = 'EDB'
      ORDER BY p2.ddh, p2.ddm
      LIMIT 1
    )                                                     AS dest,
    (
      SELECT COUNT(*)
      FROM coach c
      WHERE c.uid = s.uid
    )                                                     AS len,
    s.toc                                                 AS toc
FROM service s
JOIN route r USING (hc)
LEFT JOIN stop st
  ON st.hc = s.hc
 AND st.loc = 'EDB'
WHERE r.orig = 'EDB'
ORDER BY dep;

-- 3. Sequence of locations for the 18:59 1L27 service (serviceEDBDEE)
CREATE OR REPLACE VIEW serviceEDBDEE AS
SELECT locs.loc                                           AS loc,
       stn.code                                          AS stn,
       locs.pl                                            AS pl,
       MAKETIME(locs.adh, locs.adm, 0)                   AS arr,
       MAKETIME(locs.ddh, locs.ddm, 0)                   AS dep
FROM (
    -- origin
    SELECT
      r.orig                           AS loc,
      NULL                             AS ddh,
      NULL                             AS ddm,
      NULL                             AS adh,
      NULL                             AS adm,
      NULL                             AS pl,
      MAKETIME(s.dh, s.dm, 0)         AS dep_order
    FROM service s
    JOIN route r USING (hc)
    WHERE s.hc = '1L27' AND s.dh = 18 AND s.dm = 59

    UNION ALL

    -- intermediate stops
    SELECT
      p.loc                            AS loc,
      p.ddh                            AS ddh,
      p.ddm                            AS ddm,
      st.adh                           AS adh,
      st.adm                           AS adm,
      st.pl                            AS pl,
      MAKETIME(p.ddh, p.ddm, 0)       AS dep_order
    FROM plan p
    JOIN stop st
      ON st.hc = p.hc
     AND st.loc = p.loc
    WHERE p.hc = '1L27' AND NOT p.ddh IS NULL

    UNION ALL

    -- destination
    SELECT
      p2.loc                           AS loc,
      NULL                             AS ddh,
      NULL                             AS ddm,
      st2.adh                          AS adh,
      st2.adm                          AS adm,
      NULL                             AS pl,
      MAKETIME(st2.adh, st2.adm, 0)   AS dep_order
    FROM plan p2
    JOIN stop st2
      ON st2.hc = p2.hc
     AND st2.loc = p2.loc
    WHERE p2.hc = '1L27'
      AND p2.ddh IS NULL
) AS locs
LEFT JOIN station stn
  ON stn.loc = locs.loc
ORDER BY locs.dep_order;


