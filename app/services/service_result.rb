class ServiceResult
  attr_reader :value, :errors

  def self.success(value)
    new(value:, errors: {})
  end

  def self.failure(errors)
    new(value: nil, errors: normalize_errors(errors))
  end

  def initialize(value:, errors:)
    @value = value
    @errors = errors
  end

  def success?
    errors.empty?
  end

  def failure?
    !success?
  end

  def self.normalize_errors(errors)
    case errors
    when ActiveModel::Errors then errors.messages
    when Hash then errors
    else {}
    end
  end
  private_class_method :normalize_errors
end
