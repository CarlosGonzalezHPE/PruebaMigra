
-- Delivery datamodel changes for DEG Orange
-- HPE 2018

-- AUTOPROVISIONING TABLE:

DROP TABLE IF EXISTS DEG_AUTOPROVISIONING;

CREATE TABLE DEG_AUTOPROVISIONING(
        TIMESTAMP_QUERY               DATETIME,
        TIMESTAMP_SYSTEM              DATETIME,
        USERNAME                      VARCHAR(64) NOT NULL,
        NODE_ID                       VARCHAR(64),
        COMMAND                       VARCHAR(64),
        UNIQUE_ID                     VARCHAR(64),
        REALM                         VARCHAR(64),
        DETAILS                       VARCHAR(64) NOT NULL,
        REQUEST_ID                    VARCHAR(64),
        RESULT_CODE                   VARCHAR(64),
        PROVISIONED                   VARCHAR(64));

ALTER TABLE DEG_AUTOPROVISIONING ADD CONSTRAINT PK_DEG_AUTOPROVISIONING PRIMARY KEY(USERNAME, DETAILS);
CREATE INDEX DEG_AUTOPROVISIONING_IDX ON DEG_AUTOPROVISIONING(USERNAME, DETAILS);
