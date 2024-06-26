-- @Description Tests that the pg_class statistics are updated on
-- lazy vacuum.

CREATE TABLE uaocs_stats (a INT, b INT, c CHAR(128)) WITH (appendonly=true, orientation=column) DISTRIBUTED BY (a);
CREATE INDEX uaocs_stats_index ON uaocs_stats(b);
INSERT INTO uaocs_stats SELECT i as a, i as b, 'hello world' as c FROM generate_series(1, 50) AS i;
INSERT INTO uaocs_stats SELECT i as a, i as b, 'hello world' as c FROM generate_series(51, 100) AS i;
ANALYZE uaocs_stats;

-- ensure that the scan go through the index
SET enable_seqscan=false;
SELECT relname, reltuples FROM pg_class WHERE relname = 'uaocs_stats';
SELECT relname, reltuples FROM pg_class WHERE relname = 'uaocs_stats_index';
DELETE FROM uaocs_stats WHERE a < 16;
VACUUM uaocs_stats;
SELECT relname, reltuples FROM pg_class WHERE relname = 'uaocs_stats';

-- New strategy of VACUUM AO/CO was introduced by PR #13255 for performance enhancement.
-- Index dead tuples will not always be cleaned up completely after VACUUM, resulting
-- index stats pg_class->reltuples will not always be accurate. So ignore the stats check
-- for reltuples to coordinate with the new behavior.
-- start_ignore
SELECT relname, reltuples FROM pg_class WHERE relname = 'uaocs_stats_index';
-- end_ignore
