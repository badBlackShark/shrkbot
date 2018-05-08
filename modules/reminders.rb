require 'rufus-scheduler'

# Let the bot remind you of something.
module Reminders
  extend Discordrb::Commands::CommandContainer

  @scheduler = Rufus::Scheduler.new

  def self.init
    DB.create_table(
      'shrk_reminders',
      user: :bigint,
      message: :text,
      at: String,
      scheduled: String,
      channel: :bigint,
      pm: :boolean,
      job_id: String
    )
    reschedule
  end

  # Reschedules reminders that are still in the database. Will immediately trigger reminders
  # which are scheduled for a time in the past.
  private_class_method def self.reschedule
    reminders = DB.read_all(:shrk_reminders)
    reminders.each do |reminder|
      if Time.parse(reminder[:at]) < Time.now
        send_reminder(
          SHRK.user(reminder[:user]),
          SHRK.channel(reminder[:channel]),
          Time.parse(reminder[:scheduled]),
          reminder[:message],
          reminder[:pm]
        )
        DB.delete_value(:shrk_reminders, :job_id, reminder[:job_id])
      else
        schedule_reminder(
          SHRK.user(reminder[:user]),
          SHRK.channel(reminder[:channel]),
          reminder[:at],
          reminder[:message],
          reminder[:pm]
        )
      end
    end
  end

  attrs = {
    usage: 'remind <time> <message> <--pm>',
    description: "You will be reminded of <message> after <time>. Argument order doesn't matter. "\
                 'Set the `--pm` flag to be reminded in a PM.'
  }
  command :remind, attrs do |event, *args|
    time = args.select { |a| a =~ /^((\d+)[smhdwMy]{1})+$/ }.join
    msg  = args.reject { |a| a =~ /^((\d+)[smhdwMy]{1})+$/ || a.casecmp?('--pm') }.join(' ')
    pm = args.include?('--pm')
    time = '1d' if time.empty?

    event.respond "I will remind you about `#{msg}` in #{time}."
    job = schedule_reminder(event.user, event.channel, time, msg, pm)
    DB.insert_row(:shrk_reminders, [event.user.id, msg, job.next_time.to_s, job.scheduled_at.to_s, event.channel.id, pm, job.id])
    nil
  end

  private_class_method def self.schedule_reminder(user, channel, time, msg, pm)
    @scheduler.schedule time, job: true do |j|
      DB.delete_value(:shrk_reminders, :job_id, j.id)
      send_reminder(user, channel, j.scheduled_at, msg, pm)
    end
  end

  private_class_method def self.send_reminder(user, channel, time, msg, pm)
    if pm
      user.pm "On #{time.strftime(TIME_FORMAT)} you wanted to be reminded about `#{msg}`."
    else
      channel.send "#{user.mention}, on #{time.strftime(TIME_FORMAT)} you wanted to be reminded about `#{msg}`."
    end
  end
end
