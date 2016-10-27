# Bojangles

This script continually monitors the PVTA bus departures realtime feed for issues.

With Bundler and the correct Ruby installed, run:

> bundle exec whenever -w

To clear the entry from the crontab file:

> bundle exec whenever -c

For more information, [see the whenever docs](https://github.com/javan/whenever).

# How does it work?

In short, bojangles compares cached GTFS departure data which we obtain from PVTA to the real-time departure feed which serves data to many other services, including [BusInfoBoard](https://github.com/umts/BusInfoBoard) and [PVTrack](https://github.com/umts/pvta-multiplatform). It then sends email notifications to report on any discrepancies it finds.

# What assumptions does it make?

[Click here](https://github.com/umts/bojangles/tree/master/DETAILS.md).

# Development

We develop using [Mailcatcher](http://mailcatcher.me) - thanks to those folks for releasing their fantastic tool open-source.

They discourage including it in the Gemfile, and we listened - so you'll need to install it manually:

> gem install mailcatcher

Then run their daemon:

> mailcatcher

Setting the environment value in `config.json` to `"development"` will send emails to Mailcatcher's local SMTP server.

Then navigate to localhost:1080 to see your email output.

# Testing

You'll need RSpec.

> gem install rspec

# Attributions

Much thanks to the whenever and [Pony](https://github.com/benprew/pony) developers for releasing their code open-source.
