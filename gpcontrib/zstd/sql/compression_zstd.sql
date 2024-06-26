-- Tests for zstd compression.

-- Check that callbacks are registered
SELECT * FROM pg_compression WHERE compname = 'zstd';

CREATE TABLE zstdtest (id int4, t text) WITH (appendonly=true, compresstype=zstd, orientation=column);

-- Check that the reloptions on the table shows compression type
SELECT reloptions FROM pg_class WHERE relname = 'zstdtest';

INSERT INTO zstdtest SELECT g, 'foo' || g FROM generate_series(1, 100000) g;
INSERT INTO zstdtest SELECT g, 'bar' || g FROM generate_series(1, 100000) g;

-- Check that we actually compressed data. With libzstd-1.4.4, the ratio is 2.66. With libzstd-1.3.7, the ratio is 2.62. With libzstd-1.3.3, the ration is 2.63.
SELECT get_ao_compression_ratio('zstdtest') IN (2.62, 2.63, 2.66);

-- Check contents, at the beginning of the table and at the end.
SELECT * FROM zstdtest ORDER BY (id, t) LIMIT 5;
SELECT * FROM zstdtest ORDER BY (id, t) DESC LIMIT 5;


-- Test different compression levels:
CREATE TABLE zstdtest_1 (id int4, t text) WITH (appendonly=true, compresstype=zstd, compresslevel=1);
CREATE TABLE zstdtest_10 (id int4, t text) WITH (appendonly=true, compresstype=zstd, compresslevel=10);
CREATE TABLE zstdtest_19 (id int4, t text) WITH (appendonly=true, compresstype=zstd, compresslevel=19);

INSERT INTO zstdtest_1 SELECT g, 'foo' || g FROM generate_series(1, 10000) g;
INSERT INTO zstdtest_1 SELECT g, 'bar' || g FROM generate_series(1, 10000) g;
SELECT * FROM zstdtest_1 ORDER BY (id, t) LIMIT 5;
SELECT * FROM zstdtest_1 ORDER BY (id, t) DESC LIMIT 5;

INSERT INTO zstdtest_19 SELECT g, 'foo' || g FROM generate_series(1, 10000) g;
INSERT INTO zstdtest_19 SELECT g, 'bar' || g FROM generate_series(1, 10000) g;
SELECT * FROM zstdtest_19 ORDER BY (id, t) LIMIT 5;
SELECT * FROM zstdtest_19 ORDER BY (id, t) DESC LIMIT 5;


-- Test the bounds of compresslevel. None of these are allowed.
CREATE TABLE zstdtest_invalid (id int4) WITH (appendonly=true, compresstype=zstd, compresslevel=-1);
CREATE TABLE zstdtest_invalid (id int4) WITH (appendonly=true, compresstype=zstd, compresslevel=0);
CREATE TABLE zstdtest_invalid (id int4) WITH (appendonly=true, compresstype=zstd, compresslevel=20);

-- CREATE TABLE for heap table with compresstype=zstd should fail
CREATE TABLE zstdtest_heap (id int4, t text) WITH (compresstype=zstd);
