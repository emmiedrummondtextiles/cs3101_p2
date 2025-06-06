-- constraints.sql: minimal constraints enforcing the three specified rules

-- 1. A service cannot arrive after it departs a station
CREATE TRIGGER trg_stop_arrival_before_departure
BEFORE INSERT OR UPDATE ON stop
FOR EACH ROW
BEGIN
    DECLARE plan_ddh INT;
    DECLARE plan_ddm INT;
    -- look up the departure differential for this stop
    SELECT ddh, ddm INTO plan_ddh, plan_ddm
      FROM plan
     WHERE hc = NEW.hc
       AND frm = NEW.frm
       AND loc = NEW.loc;
    -- ensure arrival differential ≤ departure differential
    IF (NEW.adh > plan_ddh) 
       OR (NEW.adh = plan_ddh AND NEW.adm > plan_ddm) THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'Arrival cannot occur after departure';
    END IF;
END;

-- 2. All non-terminal locations must have a finite departure differential
CREATE TRIGGER trg_plan_departure_finite
BEFORE INSERT OR UPDATE ON plan
FOR EACH ROW
BEGIN
    DECLARE next_count INT;
    -- count whether this location precedes another in the same route
    SELECT COUNT(*) INTO next_count
      FROM plan
     WHERE hc = NEW.hc
       AND frm = NEW.loc;
    -- if it does, it must have finite (non-NULL) ddh/ddm
    IF next_count > 0 AND (NEW.ddh IS NULL OR NEW.ddm IS NULL) THEN
        SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'Non-terminal must have finite departure differential';
    END IF;
END;

-- 3. A train cannot be part of two different services departing at the same time
ALTER TABLE service
  ADD CONSTRAINT uq_service_train_time UNIQUE (uid, dh, dm);

