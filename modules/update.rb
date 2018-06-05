# I can use this to update the bot through commands.
# You'll need to adjust these to match the directories & commands you need.
module Update
  extend Discordrb::Commands::CommandContainer

  attrs = {
    permission_level: 2,
    permission_message: false,
    usage: 'update',
    description: 'Updates the bot.'
  }
  command :update, attrs do |event|
    Dir.chdir('../../shrkbot') do
      `git pull`
      `svc -du ~/service/shrkbot`
    end
  end
end
