# I can use this to update the bot through commands.
# You'll need to adjust these to match the directories & commands you need.
module Update
  extend Discordrb::Commands::CommandContainer

  attrs = {
    permission_level: 2,
    permission_message: false,
    usage: 'update <--hard>',
    description: 'Updates the bot. The --hard flag means that local changes will be discarded.'
  }
  command :update, attrs do |event, flag|
    event.respond 'Goodbye :)'
    Dir.chdir('../../shrkbot') do
      # Update the files
      if flag.casecmp?('--hard')
        `git fetch --all`
        `git reset --hard origin/develop`
      else
        `git pull`
      end
      # Restart the bot
      `svc -du ~/service/shrkbot`
    end
  end
end
