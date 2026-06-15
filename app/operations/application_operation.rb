# Base for operations — the shared business-logic seam called by BOTH bot
# handlers and web controllers. Callers stay thin (parse → call op → present).
#
# Convention: subclass implements #call and returns #ok(value) or #failure(*msgs).
# Operations run INSIDE the caller's connection context (bot = with_connection
# wrapper, web = request) and don't manage connections; wrap multi-write work in
# #transaction.
class ApplicationOperation
  Result = Struct.new(:success, :value, :errors) do
    def success? = success

    def failure? = !success
  end

  def self.call(...) = new(...).call

  private

  def ok(value = nil) = Result.new(true, value, [])

  def failure(*errors) = Result.new(false, nil, errors.flatten)

  def transaction(&) = ActiveRecord::Base.transaction(&)
end
