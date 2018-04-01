
-- Delivery datamodel changes for DEG Orange
-- HPE 2018

-- BLACKLIST TABLE:

DROP TABLE IF EXISTS DEG_BLACKLIST_RANGES;

CREATE TABLE DEG_BLACKLIST_RANGES(
        DEG_RANGENAME   VARCHAR(32),
        DEG_RANGESTART  BIGINT NOT NULL,
        DEG_RANGEEND    BIGINT DEFAULT 999999999999999,
        DEG_LASTUPDATE  TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6));

ALTER TABLE DEG_BLACKLIST_RANGES ADD CONSTRAINT PK_DEG_BLACKLIST_RANGES PRIMARY KEY(DEG_RANGESTART, DEG_RANGEEND);
CREATE INDEX DEG_BLACKLIST_RANGES_IDX ON DEG_BLACKLIST_RANGES(DEG_RANGESTART, DEG_RANGEEND);
ALTER TABLE DEG_BLACKLIST_RANGES ADD CONSTRAINT UNIQUE (DEG_RANGENAME, DEG_RANGESTART, DEG_RANGEEND);

