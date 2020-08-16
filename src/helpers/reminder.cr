class Shrkbot::Reminder
  getter job : Tasker::OneShot(Nil)
  getter time : Time
  getter created_at : Time
  getter channel : Discord::Snowflake
  getter user : Discord::Snowflake
  getter message : String
  getter id : Int32
  getter dm : Bool
  getter guild : Discord::Snowflake?

  def initialize(
    @job : Tasker::OneShot,
    @time : Time,
    @created_at : Time,
    @channel : Discord::Snowflake,
    @user : Discord::Snowflake,
    @message : String,
    @id : Int32,
    @dm : Bool,
    @guild : Discord::Snowflake?
  )
  end

  def cancel
    @job.cancel
  end

  def to_embed_field
    time_left = self.time - Time.local
    time_string = String.build do |str|
      if time_left.days == 1
        str << "#{time_left.days} day, "
      elsif time_left.days > 1
        str << "#{time_left.days} days, "
      end
      if time_left.hours == 1
        str << "#{time_left.hours} hour, "
      elsif time_left.hours > 1
        str << "#{time_left.hours} hours, "
      end
      if time_left.minutes == 1
        str << "#{time_left.minutes} minute, "
      elsif time_left.minutes > 1
        str << "#{time_left.minutes} minutes, "
      end
      if time_left.seconds == 1
        str << "#{time_left.seconds} second, "
      elsif time_left.seconds > 1
        str << "#{time_left.seconds} seconds, "
      end
      str.back(2)
    end

    return Discord::EmbedField.new(name: "##{self.id} - Triggers in #{time_string}", value: self.message)
  end
end
