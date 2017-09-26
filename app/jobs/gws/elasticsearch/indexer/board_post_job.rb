class Gws::Elasticsearch::Indexer::BoardPostJob < Gws::ApplicationJob
  include Gws::Elasticsearch::Indexer::BoardBase

  self.model = Gws::Board::Post

  def enum_es_docs
    topic = Gws::Board::Topic.find(item.topic_id)

    Enumerator.new do |y|
      y << self.class.convert_to_doc(self.site, topic, item)
      item.files.each do |file|
        y << self.class.convert_file_to_doc(self.site, topic, item, file)
      end
    end
  end
end