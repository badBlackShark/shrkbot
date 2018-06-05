require 'rufus-scheduler'

# Let the bot remind you of something.
module Reminders
  extend Discordrb::Commands::CommandContainer
  extend self

  @scheduler = Rufus::Scheduler.new

  def init
    DB.create_table(
      'shrk_reminders',
      job_id: String,
      user: :bigint,
      message: :text,
      at: String,
      scheduled: String,
      channel: :bigint
    )
    reschedule
  end

  attrs = {
    usage: 'remind <time> <message> <--pm>',
    description: "You will be reminded of <message> after <time>. Argument order doesn't matter. "\
                 "Set the `--pm` flag to be reminded in a PM. Time defaults to 1 day.\n"\
                 'Supported time formats: s, m, d, w, M, y. Mixing formats (e.g. 1d10h) is supported.'
  }
  command :remind, attrs do |event, *args|
    time = args.select { |a| a =~ /^((\d+)[smhdwMy]{1})+$/ }.join
    msg  = args.reject { |a| a =~ /^((\d+)[smhdwMy]{1})+$/ || a.casecmp?('--pm') }.join(' ')
    pm = args.include?('--pm')
    time = '1d' if time.empty?

    next "Please tell me what to remind you of." if msg.empty?
    event.respond "I will remind you about `#{msg}` in #{time}."
    channel = pm ? event.user.pm : event.channel
    job = schedule_reminder(event.user, channel, time, msg)
    DB.insert_row(:shrk_reminders, [job.id, event.user.id, msg, job.next_time.to_s, job.scheduled_at.to_s, channel.id])
    nil
  end

  private

  # Reschedules reminders that are still in the database. Will immediately trigger reminders
  # which are scheduled for a time in the past.
  def reschedule
    reminders = DB.read_all(:shrk_reminders)
    reminders.each do |reminder|
      begin
        if Time.parse(reminder[:at]) <= Time.now
          send_reminder(
            SHRK.user(reminder[:user]),
            SHRK.channel(reminder[:channel]),
            Time.parse(reminder[:scheduled]),
            reminder[:message],
          )
          DB.delete_value(:shrk_reminders, :job_id, reminder[:job_id])
        else
          schedule_reminder(
            SHRK.user(reminder[:user]),
            SHRK.channel(reminder[:channel]),
            reminder[:at],
            reminder[:message],
            renew: true
          )
        end
      rescue Exception
        # Bot doesn't have the permissions to send a reminder somewhere.
        DB.delete_value(:shrk_reminders, :job_id, reminder[:job_id])
      end
    end
  end

  # Schedules a reminder, returns the scheduling job
  def schedule_reminder(user, channel, time, msg, renew: false)
    job = @scheduler.schedule time, job: true do |j|
      DB.delete_value(:shrk_reminders, :job_id, j.id)
      send_reminder(user, channel, j.scheduled_at, msg)
    end
    if renew
      DB.select_rows(:shrk_reminders, :user, user.id).each do |reminder|
        if reminder[:message].eql?(msg) && reminder[:channel] == channel.id
          DB.delete_value(:shrk_reminders, :job_id, reminder[:job_id])
          DB.insert_row(:shrk_reminders, [job.id, user.id, msg, reminder[:at], reminder[:scheduled], channel.id])
          break
        end
      end
    end
    job
  end

  def send_reminder(user, channel, time, msg)
    channel.send "#{user.mention}, on #{time.strftime(TIME_FORMAT)} you wanted to be reminded about `#{msg}`."
  rescue Exception
    # The bot probably left the server this channel was in.
  end
end
