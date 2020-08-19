# shrkbot

My general purpose Discord bot. Now written in [Crystal](https://crystal-lang.org/).

## Usage

When the bot joins your server you should receive a long message with instructions. Most importantly, all of the bot's features besides logging are disabled per default, and can then be turned on on a per-guild basis. To see what you can enable, simply use the `.plugins` command. Sooner or later a list of all the major features will be added to this README.

Use the `help` command to see what's available to use for you - the bot filters out commands that a user has insufficient permissions to use, or that are currently disabled.

You can set a custom prefix on a per-guild basis for the bot. The default prefix for everything is `.`.

There is no GUI or website to go along with the bot. Everything can and has to be configured through Discord itself, via chat commands.

If there's any features you'd like to request, simply contact me - badBlackShark#6987 - on Discord.

## Installation

To run the bot yourself, you only need Docker with Compose. Simply run `docker-compose up`, and everything should set itself up. The app might need a few retries to connect to the database while that starts up, but eventually it'll connect.

## Contributing

1. Fork it (<https://github.com/badBlackShark/shrkbot/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

-   [badBlackShark](https://github.com/badBlackShark) - creator and maintainer
