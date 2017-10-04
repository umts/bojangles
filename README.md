# Bojangles

This script continually monitors the PVTA bus departures realtime feed for issues.

First in `config`, create a `config.json` file according to the `config.json.example` file, and a `database.json` file according to `database.json.example`.

With Bundler and the correct Ruby installed, run:

> bundle exec rake bojangles:daily

to initialize the process. Then, begin monitoring with:

> bundle exec whenever -w

To clear the entry from the crontab file:

> bundle exec whenever -c

For more information, [see the whenever docs](https://github.com/javan/whenever).

You can also test the process as you like with:

> bundle exec rake bojangles:run

# How does it work?

In short, bojangles compares cached GTFS departure data which we obtain from PVTA to the real-time departure feed which serves data to many other services, including [BusInfoBoard](https://github.com/umts/BusInfoBoard) and [PVTrack](https://github.com/umts/pvta-multiplatform). It then sends email notifications to report on any discrepancies it finds.

# What assumptions does it make?

[Click here](https://github.com/umts/bojangles/tree/master/DETAILS.md).
