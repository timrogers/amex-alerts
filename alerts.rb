require 'rubygems'
require 'amex'
require 'terminal-notifier'

require 'redis'
require 'redis-namespace'

class AmexAlerts
  attr_reader :client

  def initialize

    # Check that the username and password are available to use
    unless ENV['amex_username'] and ENV['amex_password']
      raise "Your American Express username and password must be passed in" +
      "the environmental variables 'amex_username' and 'amex_password'."
    end

    # If they're ready to go, set up a client object for future use
    @accounts = Amex::Client.
      new(ENV['amex_username'], ENV['amex_password'])
      .accounts

    # Prepare a Redis object for performing storage operations later
    @datastore = Redis::Namespace.new(:amex_alerts, :redis => Redis.new)
  end

  def detect_changes
    @accounts.each do |account|
      # We'll only look at the first loyalty balance, since as far as I'm
      # aware, one American Express card can only have one
      loyalty_programme = account.loyalty_programmes.first

      if !@datastore[account.card_number_suffix]
        # We haven't stored anything about this account before
        puts "New account #{account.card_number_suffix} - balance " +
        "is #{loyalty_programme.balance}."

        # Store the current balance in Redis under the card number
        @datastore[account.card_number_suffix] = loyalty_programme.balance

        # Send a Notification Centre alert about this new loyalty programme
        TerminalNotifier.notify(
          "#{loyalty_programme.name} on account" +
          "-#{account.card_number_suffix}: #{loyalty_programme.balance}.",
          { title: "American Express" }
        )
      elsif @datastore[account.card_number_suffix] == loyalty_programme.balance.to_s
        # The balance is the same as last time we looked, so do nothing.
        puts "No change on account #{account.card_number_suffix} - balance " +
        "is #{loyalty_programme.balance}."

        TerminalNotifier.notify(
          "#{loyalty_programme.name} on account " +
          "-#{account.card_number_suffix}: no change at " +
          "#{loyalty_programme.balance}",
          { title: "American Express" }
        )

      else
        # There balance has actually changed - let's fire off a new alert!
        old_balance = @datastore[account.card_number_suffix].to_i
        new_balance = loyalty_programme.balance

        puts "The balance on account #{account.card_number_suffix} has " +
        "changed from #{old_balance} to #{new_balance}."

        # Store the new balance so we don't keep sending these alerts forever
        @datastore[account.card_number_suffix] = new_balance

        # Let's build a textual representation of the change, whether positive
        # or negative, for putting into the alert
        if old_balance > new_balance
          # There has been a reduction in the loyalty balance
          change = "-#{old_balance - new_balance}"
        else
          change = "+#{new_balance - old_balance}"
        end

        TerminalNotifier.notify(
          "#{loyalty_programme.name} on account " +
          "-#{account.card_number_suffix}: #{change} to #{new_balance}",
          { title: "American Express" }
        )
      end
    end
  end
end

alerts = AmexAlerts.new
alerts.detect_changes