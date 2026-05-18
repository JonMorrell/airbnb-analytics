import duckdb
import os

# Connect to DuckDB - this creates the file if it doesn't exist
con = duckdb.connect('data/airbnb.duckdb')

# Create raw schema
con.execute("CREATE SCHEMA IF NOT EXISTS raw")

# Load each CSV into its own table
files = {
    'listings': 'data/raw/listings.csv',
    'reviews': 'data/raw/reviews.csv',
    'calendar': 'data/raw/calendar.csv',
}

for table_name, file_path in files.items():
    print(f"Loading {table_name}...")
    con.execute(f"""
        CREATE OR REPLACE TABLE raw.{table_name} AS
        SELECT * FROM read_csv_auto('{file_path}', ignore_errors=true)
    """)
    count = con.execute(f"SELECT COUNT(*) FROM raw.{table_name}").fetchone()[0]
    print(f"  ✓ {table_name}: {count:,} rows loaded")

con.close()
print("\nDone! Database saved to data/airbnb.duckdb")