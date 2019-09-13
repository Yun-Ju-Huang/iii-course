CREATE DATABASE IF NOT EXISTS TMP;
CREATE DATABASE IF NOT EXISTS STAGE;

USE TMP;

CREATE EXTERNAL TABLE IF NOT EXISTS TMP.TT_WEBLOG
(
DT STRING COMMENT 'page view datetime'
,URL STRING COMMENT 'page view url'
,UA STRING COMMENT 'user agent'
,UUID STRING COMMENT 'user id'
)
COMMENT 'STAGE page view log'
PARTITIONED BY (PARTITION_MDATE VARCHAR(8) COMMENT 'TMP partition (YYYYMMDD)', PARTITION_SDATE VARCHAR(2) COMMENT 'TMP partition (HR)')
ROW FORMAT DELIMITED FIELDS TERMINATED BY '|'
LOCATION '/user/hive/prestage/weblog';

--MDATE: 20170710 (YYYYMMDD)
--SDATE: 12 (HR)
DROP TABLE IF EXISTS TMP.T_WEBLOG;
CREATE EXTERNAL TABLE IF NOT EXISTS TMP.T_WEBLOG LIKE TMP.TT_WEBLOG;
ALTER TABLE TMP.T_WEBLOG
ADD IF NOT EXISTS PARTITION
(
PARTITION_MDATE='${MDATE}'
,PARTITION_SDATE='${SDATE}'
)
LOCATION '/user/hive/prestage/weblog/${MDATE}/${SDATE}';


USE STAGE;
CREATE TABLE IF NOT EXISTS STAGE.S_WEBLOG
(
DT STRING COMMENT 'page view datetime'
,URL STRING COMMENT 'page view url'
,UA STRING COMMENT 'user agent'
,UUID STRING COMMENT 'user id'
)
COMMENT 'STAGE page view log'
PARTITIONED BY (PARTITION_MDATE VARCHAR(8) COMMENT 'TMP partition (YYYYMMDD)', PARTITION_SDATE VARCHAR(2) COMMENT 'TMP partition (HR)')
STORED AS SEQUENCEFILE;

SET hive.exec.dynamic.partition.mode=nonstrict;
SET hive.exec.dynamic.partition=true;

ALTER TABLE STAGE.S_WEBLOG DROP IF EXISTS PARTITION (PARTITION_MDATE='${MDATE}', PARTITION_SDATE='${SDATE}');
INSERT INTO STAGE.S_WEBLOG PARTITION(PARTITION_MDATE, PARTITION_SDATE)
SELECT 
DT
,URL
,UA
,UUID
,PARTITION_MDATE
,PARTITION_SDATE
FROM TMP.T_WEBLOG;
