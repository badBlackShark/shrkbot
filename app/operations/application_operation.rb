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

    NO_DEFAULT = Object.new.freeze
    private_constant :NO_DEFAULT

    class << self
      def receives(*names, optional: false, default: NO_DEFAULT)
        has_default = !default.equal?(NO_DEFAULT)
        if (optional || has_default) && names.size != 1
          raise ArgumentError, "receives with optional:/default: takes a single keyword"
        end

        names.each do |name|
          receive_declarations[name] = {required: !optional && !has_default, has_default: has_default, default: default}
          attr_reader(name)
        end
      end

      def receive_declarations
        @receive_declarations ||= {}
      end

      def call(...)
        new(...).execute
      end
    end

    def initialize(**kwargs)
      declarations = self.class.receive_declarations

      missing = declarations.select { |_name, spec| spec[:required] }.keys - kwargs.keys
      raise ArgumentError, "missing keyword#{"s" if missing.size > 1}: #{missing.map(&:inspect).join(", ")}" if missing.any?

      unknown = kwargs.keys - declarations.keys
      raise ArgumentError, "unknown keyword#{"s" if unknown.size > 1}: #{unknown.map(&:inspect).join(", ")}" if unknown.any?

      declarations.each do |name, spec|
        value =
          if kwargs.key?(name)
            kwargs[name]
          elsif spec[:has_default]
            spec[:default]
          end
        instance_variable_set("@#{name}", value)
      end
    end

    def execute
      return call unless self.class.transactional

      transaction do
        call
      end
    end

    def call
      raise AbstractMethodError, "#{self.class} must implement #call"
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
