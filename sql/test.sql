-- test.sql
-- 05_test.sql
USE cs3101p2;

-- 1) Test proc_new_service
-- ------------------------
-- Add a new service departing EDB @ 12:00, using train '000001' on TOC 'CS'
CALL proc_new_service('EDB', 1, '1200', '000001', 'CS');

-- Check that a new route & service were created.
-- We expect a route.hc starting with '1E' and service at 12:00
SELECT hc, orig
  FROM route
 WHERE orig = 'EDB'
   AND hc LIKE '1E%';

SELECT hc, CONCAT(dh,dm) AS dep, pl, uid, toc
  FROM service
 WHERE uid = '000001'
   AND CONCAT(dh,dm) = '1200';

-- 2) Test proc_add_loc (appending a non‐stop “pass‐through” location)
-- ------------------------------------------------------------------
-- Suppose we want to extend the new route by adding 'HYM' (Haymarket) after 'EDB',
-- with a 5-minute departure diff, no stop.
-- First find the HC of our new route:
SET @newhc := (
  SELECT hc FROM service WHERE uid = '000001' AND CONCAT(dh,dm) = '1200'
);

CALL proc_add_loc(@newhc, 'HYM', 'EDB', '0005', NULL, NULL);

-- Verify in plan (ddh=00, ddm=05) and no entry in stop
SELECT * FROM plan
 WHERE hc = @newhc AND frm = 'EDB' AND loc = 'HYM';

SELECT * FROM stop
 WHERE hc = @newhc AND frm = 'EDB' AND loc = 'HYM';

-- 3) Test proc_add_loc (adding a stop)
-- ------------------------------------
-- Now add 'PSG' (Princes St Gardens) as a stop after 'EDB', 2-minute dd and 1-minute arrival diff on plat 2
CALL proc_add_loc(@newhc, 'PSG', 'EDB', '0002', '0001', 2);

-- Verify both plan and stop entries
SELECT * FROM plan
 WHERE hc = @newhc AND frm = 'EDB' AND loc = 'PSG';

SELECT * FROM stop
 WHERE hc = @newhc AND frm = 'EDB' AND loc = 'PSG';

-- 4) Error cases
-- --------------
-- (a) Trying to stop without a platform or arrival diff should fail:
--     this will raise an error.
-- CALL proc_add_loc(@newhc, 'ABC', 'EDB', '0003', NULL, 3);

-- (b) Trying to add an infinite departure diff at a non-terminal point should fail:
--    after we added PSG and HYM, only the last added location ('PSG' or 'HYM' whichever was last)
--    can accept dd='ωω'. Others should trigger your plan trigger.
-- CALL proc_add_loc(@newhc, 'XYZ', 'EDB', 'ωω', NULL, NULL);

-- 5) Clean up (optional)
-- ----------------------
-- Remove the test service & route so you can re-run tests without conflicts:
DELETE FROM service WHERE uid='000001' AND CONCAT(dh,dm)='1200';
DELETE FROM stop    WHERE hc = @newhc;
DELETE FROM plan    WHERE hc = @newhc;
DELETE FROM route   WHERE hc = @newhc;
