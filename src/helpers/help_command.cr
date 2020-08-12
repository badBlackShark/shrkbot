class Shrkbot::HelpCommand
  include YAML::Serializable

  getter name : String
  getter aliases : Array(String)?
  getter args : String?
  getter opt_args : String?
  getter description : String
  getter perm_level : Int32

  def initialize(
    @name : String,
    @args : String?,
    @opt_args : String?,
    @description : String,
    @perm_level : Int32
  )
  end

  def to_s(guild : Discord::Snowflake?)
    # Checking if args exist to avoid a double space if there's optional args, but no required ones.
    # Checking for . at the start because of commands that always have the same prefix.
    usage = if @name.starts_with?(".")
              # Assuming that when the command has a fixed prefix, the aliases also do.
              "#{@name}#{@args ? " #{@args}" : ""} #{@opt_args} #{@aliases ? "| aliases: #{@aliases.not_nil!.map { |a| "*#{a}*" }.join(", ")}" : ""}"
            else
              prefix = Prefix.get_prefix(guild)
              "#{prefix}#{@name}#{@args ? " #{@args}" : ""} #{@opt_args} #{@aliases ? "| aliases: #{@aliases.not_nil!.map { |a| "*#{prefix}#{a}*" }.join(", ")}" : ""}"
            end

    return case @perm_level
    when 0
      usage
    when 1
      "**Staff:** #{usage}"
    else
      "**Creator:** #{usage}"
    end
  end

  def long_form(guild : Discord::Snowflake?)
    [self.to_s(guild), @description]
  end
end
