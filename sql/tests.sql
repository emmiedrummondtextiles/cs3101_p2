new route 

-- Find the headcode just created:
SELECT hc INTO @hc
  FROM service
 WHERE uid='000999'
   AND CONCAT(dh,dm)='1415';

-- Verify route:
SELECT * FROM route WHERE hc=@hc;

-- Verify service:
SELECT hc, CONCAT(dh,dm) AS dep, pl, uid, toc
  FROM service
 WHERE hc=@hc;

CALL proc_add_loc(@hc, 'HYM', (SELECT orig FROM route WHERE hc=@hc), '0005', NULL, NULL);
SELECT * FROM plan WHERE hc=@hc;

CALL proc_add_loc(@hc, 'PSG', 'HYM', '0002', '0001', 2);
SELECT * FROM plan WHERE hc=@hc;
SELECT * FROM stop WHERE hc=@hc;

DELETE FROM stop    WHERE hc=@hc;
DELETE FROM plan    WHERE hc=@hc;
DELETE FROM service WHERE hc=@hc;
DELETE FROM route   WHERE hc=@hc;
DELETE FROM train   WHERE uid='000999';
