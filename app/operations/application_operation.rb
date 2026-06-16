module Ops
  class ApplicationOperation
    Result = Struct.new(:success, :value, :errors) do
      def success?
        success
      end

      def failure?
        !success
      end
    end

    def self.call(...)
      new(...).call
    end

    private

    def ok(value = nil)
      Result.new(true, value, [])
    end

    def failure(*errors)
      Result.new(false, nil, errors.flatten)
    end

    def transaction(&)
      ActiveRecord::Base.transaction(&)
    end
  end
end
