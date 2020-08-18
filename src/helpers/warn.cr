class Shrkbot::Warn
  getter job : Tasker::OneShot(Nil)
  getter time : Time
  getter user : Discord::Snowflake
  getter guild : Discord::Snowflake

  def initialize(@job : Tasker::OneShot, @time : Time, @user : Discord::Snowflake, @guild : Discord::Snowflake, @phrase : String)
  end

  def cancel
    @job.cancel
  end

  def phrase
    @phrase.gsub("\\s*", "")
  end
end
