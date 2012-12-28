## amex-alerts

This quick script, designed to be run as a cron, checks the balances on your
American Express rewards programmes (e.g. Membership Rewards or Avios) and
alerts you to their balance each day.

With backend storage based on Redis, this script will provide you with a
popup each day of your balance and how it has changed.

This is based on my [amex](https://github.com/timrogers/amex) gem which
uses a non-public American Express API to view your account.

### Requirements

* An American Express account (it might have to be a UK one, I'm not sure)
* [Redis](http://redis.io) installed on your machine
* Mac OS X with Notification Centre support

### Usage

* Set the `amex_username` and `amex_password` environmental variables with
your American Express online services username and password respectively *(you
can do this inline when executing the script)*
* Execute alerts.rb with Ruby

```
ruby alerts.rb
amex_username=chuck_norris amex_password=roundhouse ruby alerts.rb
```

 * On first run, you'll just get a popup notifying you that you have a balance
 on each of your American Express reward programmes (*if you have multiple
 cards on your account, you'll get an alert for each*)
 * On susbsequent runs:
  * If your balance has changed, you'll be told the change and your new balance
  * If there's no change, you'll just be shown your balance

### Running as a cron

The best way to use this is to set it up as a cron job to be run each day
at a time when you're likely to be using your computer.

For instance, to set it to run a midday every day:

```
editor=my_favourite_editor crontab -e
0 12  * * * amex_username=chuck_norris amex_password=roundhouse ruby /path/to/alerts.rb
```

Now, save the file and it'll be added as a cron. To check it's there, just
run `crontab -l`.

