-- 04_procedures.sql
-- Define proc_new_service and proc_add_loc per specification

USE cs3101p2;
DELIMITER $$

-- 1. proc_new_service:
--    Inputs: origin station code (e.g. 'EDB'), origin platform, departure time (HHMM), train ID, TOC
CREATE PROCEDURE proc_new_service(
  IN p_orig_code CHAR(3),      -- station CRS code
  IN p_pl         INT,
  IN p_dep        CHAR(4),     -- departure time as HHMM
  IN p_train      CHAR(6),
  IN p_toc        VARCHAR(2)
)
BEGIN
  DECLARE p_orig_loc VARCHAR(100);
  DECLARE new_hc      CHAR(4);

  -- Lookup the location name for the station code
  SELECT loc
    INTO p_orig_loc
    FROM station
   WHERE code = p_orig_code
   LIMIT 1;
  IF p_orig_loc IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid station code';
  END IF;

  -- Generate a fresh headcode: class '1', destination area = first letter of loc name, identifier = next seq
  SELECT CONCAT(
           '1',
           LEFT(p_orig_loc,1),
           LPAD(
             COALESCE(
               MAX(CAST(RIGHT(hc,2) AS UNSIGNED)),
               0
             ) + 1,
             2,
             '0'
           )
         )
    INTO new_hc
    FROM route
   WHERE LEFT(hc,1) = '1'
     AND SUBSTR(hc,2,1) = LEFT(p_orig_loc,1);

  -- Insert new route using the resolved location
  INSERT INTO route(hc, orig)
  VALUES(new_hc, p_orig_loc);

  -- Insert new service
  INSERT INTO service(hc, dh, dm, pl, uid, toc)
  VALUES(
    new_hc,
    LEFT(p_dep,2),
    RIGHT(p_dep,2),
    p_pl,
    p_train,
    p_toc
  );
END$$

-- 2. proc_add_loc:
--    Inputs: headcode, new location name or code? we're expecting location name
--    For consistency, accept station code for stops, and location names for pass-throughs.
CREATE PROCEDURE proc_add_loc(
  IN p_hc        CHAR(4),
  IN p_loc_name  VARCHAR(100),  -- location name
  IN p_prev_name VARCHAR(100),  -- preceding location name
  IN p_dd        CHAR(4),      -- departure differential
  IN p_ad        CHAR(4),      -- arrival differential (nullable)
  IN p_pl        INT           -- platform (nullable)
)
BEGIN
  DECLARE ddh CHAR(2);
  DECLARE ddm CHAR(2);
  DECLARE adh CHAR(2);
  DECLARE adm CHAR(2);

  -- Validate route exists
  IF NOT EXISTS(SELECT 1 FROM route WHERE hc = p_hc) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Route not found';
  END IF;

  -- Validate location exists
  IF NOT EXISTS(SELECT 1 FROM location WHERE loc = p_loc_name) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Location not found';
  END IF;

  -- Validate preceding location in plan
  IF NOT EXISTS(
    SELECT 1 FROM plan
     WHERE hc = p_hc
       AND loc = p_prev_name
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Preceding location not in route';
  END IF;

  -- Parse departure differential
  SET ddh = LEFT(p_dd,2);
  SET ddm = RIGHT(p_dd,2);

  -- If arrival differential or platform provided, require both
  IF p_ad IS NOT NULL OR p_pl IS NOT NULL THEN
    IF p_ad IS NULL OR p_pl IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Both arrival differential and platform required to stop';
    END IF;
    SET adh = LEFT(p_ad,2);
    SET adm = RIGHT(p_ad,2);
  END IF;

  -- Insert into plan
  INSERT INTO plan(hc, frm, loc, ddh, ddm)
  VALUES(p_hc, p_prev_name, p_loc_name, ddh, ddm);

  -- Insert into stop if stopping
  IF p_ad IS NOT NULL THEN
    INSERT INTO stop(hc, frm, loc, adh, adm, pl)
    VALUES(p_hc, p_prev_name, p_loc_name, adh, adm, p_pl);
  END IF;
END$$

DELIMITER ;

