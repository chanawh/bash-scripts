CREATE TABLE IF NOT EXISTS country_wise_latest (
  Country_Region String,
  Confirmed UInt32,
  Deaths UInt32,
  Recovered UInt32,
  Active UInt32,
  New_case UInt32,
  New_death UInt32,
  New_recovered UInt32,
  Deaths_per_1M Float32,
  Recovered_per_1M Float32,
  Deaths_per_Confirmed Float32,
  Confirmed_1_week_change Int32,
  One_week_percent Float32,
  WHO_Region String
) ENGINE = MergeTree() ORDER BY Country_Region;
