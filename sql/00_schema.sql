-- 00_schema.sql
-- Raw table that mirrors the Volve "Daily Production Data" sheet.
-- Column names are lower-cased versions of the original headers.

DROP TABLE IF EXISTS daily_production;

CREATE TABLE daily_production (
    date_prd                 TEXT NOT NULL,      -- YYYY-MM-DD
    well_bore_code           TEXT,
    npd_well_bore_code       TEXT,
    npd_well_bore_name       TEXT NOT NULL,      -- the well name used in all analysis
    npd_field_code           TEXT,
    npd_field_name           TEXT,
    npd_facility_code        TEXT,
    npd_facility_name        TEXT,
    on_stream_hrs            REAL,
    avg_downhole_pressure    REAL,
    avg_downhole_temperature REAL,
    avg_dp_tubing            REAL,
    avg_annulus_press        REAL,
    avg_choke_size_p         REAL,
    avg_choke_uom            TEXT,
    avg_whp_p                REAL,
    avg_wht_p                REAL,
    dp_choke_size            REAL,
    bore_oil_vol             REAL,               -- Sm3
    bore_gas_vol             REAL,               -- Sm3
    bore_wat_vol             REAL,               -- Sm3
    bore_wi_vol              REAL,               -- Sm3 water injected
    flow_kind                TEXT,               -- e.g. production / injection
    well_type                TEXT                -- e.g. OP (oil producer) / WI (water injector)
);

CREATE INDEX idx_dp_well_date ON daily_production (npd_well_bore_name, date_prd);
CREATE INDEX idx_dp_date      ON daily_production (date_prd);
