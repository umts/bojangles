# Bojangles

This script continually monitors the PVTA bus departures realtime feed for issues.

With Bundler and the correct Ruby installed, run:

> bundle exec whenever -w

To clear the entry from the crontab file:

> bundle exec whenever -c

For more information, [see the whenever docs](https://github.com/javan/whenever).

# Development

We develop using [Mailcatcher](http://mailcatcher.me) - thanks to those folks for releasing their fantastic tool open-source.

They discourage including it in the Gemfile, and we listened - so you'll need to install it manually:

> gem install mailcatcher

Then run their daemon:

> mailcatcher

Executing the script with the BOJANGLES_DEVELOPMENT environment variable set will send emails to Mailcatcher's local SMTP server.

> BOJANGLES_DEVELOPMENT=true bundle exec script/runner.rb

Then navigate to localhost:1080 to see your email output.

# Attributions

Much thanks to the whenever and [Pony](https://github.com/benprew/pony) developers for releasing their code open-source.
