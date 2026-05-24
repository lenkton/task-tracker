class TagSerializer
  def self.collection(tags)
    tags.map { |tag| call(tag) }
  end

  def self.call(tag)
    {
      id: tag.id,
      name: tag.name,
      system: tag.system_tag?,
      created_at: tag.created_at,
      updated_at: tag.updated_at
    }
  end
end
