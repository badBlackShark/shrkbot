# Unlike Ruby's NotImplementedError, this descends from StandardError so it can
# be rescued. Raise it from a method a subclass is required to implement.
class AbstractMethodError < StandardError
end
