# This one is only used for the commands used to set and get a guild's prefix.
# Since I want those two commands to always use the `.` prefix a seperate middleware is used.
class SetPrefixCommand
  getter names : Array(String)

  # Array in case of aliases
  def initialize(names : String | Array(String))
    @names = if names.is_a?(String)
               [names.downcase]
             else
               names.map { |name| name.downcase }
             end
  end

  def call(payload : Discord::Message, ctx : Discord::Context)
    cmd = payload.content.downcase
    @names.each do |name|
      yield if cmd.starts_with?("#{name} ") || cmd == name
    end
  end
end
