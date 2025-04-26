-- procedures.sql: define the two required stored procedures

DELIMITER $$

-- 1. proc_new_service: add a new service with auto-generated headcode
CREATE OR REPLACE PROCEDURE proc_new_service(
    IN p_orig CHAR(3),      -- origin station code
    IN p_plat INT,          -- origin platform number
    IN p_dh INT,            -- departure hour (24h)
    IN p_dm INT,            -- departure minute
    IN p_uid CHAR(6),       -- train unit ID
    IN p_toc CHAR(2)        -- train operating company
)
BEGIN
    DECLARE newhc CHAR(4);
    DECLARE exists_count INT;

    -- generate a random headcode matching [0-9][A-Z][0-9][0-9]
    REPEAT
        SET newhc = CONCAT(
            FLOOR(RAND() * 10),
            CHAR(FLOOR(RAND() * 26) + 65),
            FLOOR(RAND() * 10),
            FLOOR(RAND() * 10)
        );
        SELECT COUNT(*) INTO exists_count
          FROM service
         WHERE hc = newhc;
    UNTIL exists_count = 0
    END REPEAT;

    -- insert into route (route only needs headcode and origin)
    INSERT INTO route(hc, orig)
    VALUES(newhc, p_orig);

    -- insert into service
    INSERT INTO service(hc, dh, dm, pl, uid, toc)
    VALUES(newhc, p_dh, p_dm, p_plat, p_uid, p_toc);
END$$

-- 2. proc_add_loc: add a planned location (and optional stop) to a route
CREATE OR REPLACE PROCEDURE proc_add_loc(
    IN p_hc CHAR(4),         -- headcode of route
    IN p_loc VARCHAR(100),   -- location being added
    IN p_prev_loc VARCHAR(100), -- preceding location in route
    IN p_ddh INT,             -- departure differential hours
    IN p_ddm INT,             -- departure differential minutes
    IN p_adh INT,             -- arrival differential hours (nullable)
    IN p_adm INT,             -- arrival differential minutes (nullable)
    IN p_plat INT             -- platform number (nullable)
)
BEGIN
    -- validate route and location exist
    IF NOT EXISTS(SELECT 1 FROM route WHERE hc = p_hc) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Route (headcode) does not exist';
    END IF;
    IF NOT EXISTS(SELECT 1 FROM location WHERE loc = p_loc) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Location does not exist';
    END IF;
    IF NOT EXISTS(SELECT 1 FROM plan WHERE hc = p_hc AND loc = p_prev_loc) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Preceding location not in route';
    END IF;

    -- insert into plan
    INSERT INTO plan(hc, frm, loc, ddh, ddm)
    VALUES(p_hc, p_prev_loc, p_loc, p_ddh, p_ddm);

    -- if arrival and platform provided, insert into stop
    IF p_adh IS NOT NULL AND p_adm IS NOT NULL AND p_plat IS NOT NULL THEN
        INSERT INTO stop(hc, frm, loc, adh, adm, pl)
        VALUES(p_hc, p_prev_loc, p_loc, p_adh, p_adm, p_plat);
    END IF;
END$$

DELIMITER ;

