require "./shrkbot"
require "./database/db"

print "Connecting to database..."
db = Db.new
puts "done!"

config = Shrkbot::Config.load("./src/config.yml")
Shrkbot.run(config, db)
sleep
