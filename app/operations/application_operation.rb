# Runs inside the caller's connection context (doesn't manage connections);
# wrap multi-write work in #transaction.
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
