# Bojangles — technical details

## GTFS files

We use almost all of the GTFS files we obtain from PVTA, and at the moment we do expect them to have certain fields.

### calendar.txt

We look for a `service_id` column, and for its entries to contain the letters `UMTS`. Currently, Bojangles is only interested in UMass Transit Services's bus data. We place no other constraints on this ID, as long the identifiers match those found in trips.txt.

We also look for columns `monday`, `tuesday`, etc., which we expect to have boolean values representing whether a vehicle schedule does or does not operate on the given weekday.

Finally, we use the `start_date` and `end_date` columns to determine whether a particular vehicle schedule runs on today's example of today's weekday. We expect these dates to be formatted year-month-day, as in `20161027`.

### stops.txt

We use two columns in this file: `stop_name` and `stop_id`. We expect the stop IDs given here to match the stop IDs given in stop_times.txt.

### trips.txt

We expect the `service_id` column to match the `service_id` column from calendar.txt.

We then use the `trip_id` column to identify trips, which we expect to match the trip IDs given in stop_times.txt.

We expect the `route_id` to match the `ShortName` of the route at the Avail endpoint.

The `direction_id` and `headsign` must be present. We have no other constraints on their format.

### stop_times.txt

We expect `trip_id` and `stop_id` to match the IDs from `trips.txt` and `stops.txt` respectively.

We expect `departure_time` to be a time in the format H:M:S, as in `16:36:00`.

## Avail departures endpoint

We expect the object which we receive at the configured endpoint to have a `RouteDirections` object.

We expect each of those `RouteDirections` to have a `route_id` matching the route ID at the routes endpoint, and to have a `Departures` object.

We expect those `Departures` to be ordered by estimated departure time.

Within each departure we expect an `SDT` Unix timestamp with a timezone of +0400 or +0500, and we expect a `Trip` object.

We expect that `Trip` object to have an `InternetServiceDesc` which should match the headsign we got from trips.txt.
