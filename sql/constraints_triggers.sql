-- 02_constraints_triggers.sql
-- Enforce the three constraints via triggers on MariaDB

USE cs3101p2;
DELIMITER $$

-- 1. A service cannot arrive after it departs a station.
CREATE TRIGGER trig_stop_arrival_ins
BEFORE INSERT ON stop
FOR EACH ROW
BEGIN
  DECLARE pdh CHAR(2);
  DECLARE pdm CHAR(2);
  -- fetch the departure differential for this planned location
  SELECT ddh, ddm
    INTO pdh, pdm
    FROM plan
   WHERE hc = NEW.hc
     AND frm = NEW.frm
     AND loc = NEW.loc;

  -- if arrival (adh,adm) > departure differential (pdh,pdm), abort
  IF (NEW.adh > pdh) OR (NEW.adh = pdh AND NEW.adm > pdm) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Arrival cannot be later than departure differential';
  END IF;
END$$

CREATE TRIGGER trig_stop_arrival_upd
BEFORE UPDATE ON stop
FOR EACH ROW
BEGIN
  DECLARE pdh CHAR(2);
  DECLARE pdm CHAR(2);
  SELECT ddh, ddm INTO pdh, pdm
    FROM plan
   WHERE hc = NEW.hc
     AND frm = NEW.frm
     AND loc = NEW.loc;
  IF (NEW.adh > pdh) OR (NEW.adh = pdh AND NEW.adm > pdm) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Arrival cannot be later than departure differential';
  END IF;
END$$

-- 2. Finite departure differential except at route destination.
-- Only the destination (no subsequent plan row) may have an infinite 'ω' differential.
-- Check on INSERT
CREATE TRIGGER trig_plan_dd_ins
BEFORE INSERT ON plan
FOR EACH ROW
BEGIN
  -- if an infinite differential is provided
  IF NEW.ddh = 'ω' OR NEW.ddm = 'ω' THEN
    -- ensure that this loc is not the "from" of any other plan (i.e. it's terminal)
    IF EXISTS(
      SELECT 1 FROM plan
       WHERE hc = NEW.hc
         AND frm = NEW.loc
    ) THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Only route destination may have infinite departure differential';
    END IF;
  END IF;
END$$

-- Check on UPDATE
CREATE TRIGGER trig_plan_dd_upd
BEFORE UPDATE ON plan
FOR EACH ROW
BEGIN
  IF NEW.ddh = 'ω' OR NEW.ddm = 'ω' THEN
    IF EXISTS(
      SELECT 1 FROM plan
       WHERE hc = NEW.hc
         AND frm = NEW.loc
    ) THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Only route destination may have infinite departure differential';
    END IF;
  END IF;
END$$

-- 3. A train cannot be part of two different services departing at the same time.
CREATE TRIGGER trig_service_unique_ins
BEFORE INSERT ON service
FOR EACH ROW
BEGIN
  IF EXISTS(
    SELECT 1 FROM service
     WHERE uid = NEW.uid
       AND dh = NEW.dh
       AND dm = NEW.dm
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Train already scheduled for a service at that time';
  END IF;
END$$

CREATE TRIGGER trig_service_unique_upd
BEFORE UPDATE ON service
FOR EACH ROW
BEGIN
  -- if departure time or train changes, re-check uniqueness
  IF (OLD.uid != NEW.uid OR OLD.dh != NEW.dh OR OLD.dm != NEW.dm)
     AND EXISTS(
       SELECT 1 FROM service
        WHERE uid = NEW.uid
          AND dh = NEW.dh
          AND dm = NEW.dm
     ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Train already scheduled for a service at that time';
  END IF;
END$$

DELIMITER ;
