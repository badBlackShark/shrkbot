class Shrkbot::ArgumentChecker
  class Result
    getter args : Array(String)

    def initialize(@args : Array(String))
    end
  end

  getter min_args : Int32?
  getter max_args : Int32?

  def initialize(@min_args : Int32? = nil, @max_args : Int32? = nil)
  end

  def call(payload : Discord::Message, ctx : Discord::Context)
    client = ctx[Discord::Client]
    # Gets all the args from the commands, leaving quoted substrings as one arg, but removing the quotation marks.
    args = payload.content.split(" ")[1..-1].join(" ").scan(/"[^"]+"|[^ ]+/).map { |matchdata| matchdata[0] }.map { |s| s.gsub(/"/, "") }
    args = Array(String).new if args.nil?

    min_args = @min_args
    max_args = @max_args

    if min_args && args.size < min_args
      client.create_message(payload.channel_id, "You need to call this command with at least #{min_args} argument(s).")
    elsif max_args && args.size > max_args
      client.create_message(payload.channel_id, "You can't call this command with more than #{max_args} argument(s).")
    else
      ctx.put(Result.new(args))
      yield
    end
  end
end
