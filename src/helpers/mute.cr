class Shrkbot::Mute
  getter job : Tasker::OneShot(Nil)
  getter time : Time
  getter guild : Discord::Snowflake
  getter user : Discord::Snowflake
  getter message : String

  def initialize(@job : Tasker::OneShot, @time : Time, @guild : Discord::Snowflake, @user : Discord::Snowflake, @message : String)
  end

  def cancel
    @job.cancel
  end
end
