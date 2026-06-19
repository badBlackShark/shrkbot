module Ops
  class ApplicationOperation
    Result = Struct.new(:success, :value, :errors, :warnings) do
      def success?
        success
      end

      def failure?
        !success
      end
    end

    class_attribute :transactional, default: true, instance_writer: false

    class << self
      def receives(*required, optional: [], default: {})
        @required_keywords = required
        @optional_keywords = optional
        @default_keywords = default
        attr_reader(*(required + optional + default.keys))
      end

      def required_keywords
        @required_keywords ||= []
      end

      def optional_keywords
        @optional_keywords ||= []
      end

      def default_keywords
        @default_keywords ||= {}
      end

      def call(...)
        new(...).call
      end
    end

    def initialize(**kwargs)
      permitted = self.class.required_keywords + self.class.optional_keywords + self.class.default_keywords.keys

      missing = self.class.required_keywords - kwargs.keys
      raise ArgumentError, "missing keyword#{"s" if missing.size > 1}: #{missing.map(&:inspect).join(", ")}" if missing.any?

      unknown = kwargs.keys - permitted
      raise ArgumentError, "unknown keyword#{"s" if unknown.size > 1}: #{unknown.map(&:inspect).join(", ")}" if unknown.any?

      values = self.class.default_keywords.merge(kwargs)
      permitted.each do |name|
        instance_variable_set("@#{name}", values[name])
      end
    end

    def call
      return execute unless self.class.transactional

      transaction do
        execute
      end
    end

    def execute
      raise AbstractMethodError, "#{self.class} must implement #execute"
    end

    private

    def ok(value = nil, warnings: [])
      Result.new(true, value, [], warnings)
    end

    def failure(*errors)
      Result.new(false, nil, errors.flatten, [])
    end

    def transaction(&)
      ActiveRecord::Base.transaction(&)
    end
  end
end
