module Tags
  class Write
    def self.call(tag:, attributes:)
      new(tag:, attributes:).call
    end

    def initialize(tag:, attributes:)
      @tag = tag
      @attributes = attributes.to_h.symbolize_keys
    end

    def call
      @tag.assign_attributes(@attributes.slice(:name))

      @tag.save ? ServiceResult.success(@tag) : ServiceResult.failure(@tag.errors)
    end
  end
end
