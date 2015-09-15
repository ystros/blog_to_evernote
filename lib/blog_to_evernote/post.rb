module BlogToEvernote
  class Post
    attr_reader :id, :title, :body, :created_at

    def initialize(id:, title:, body:, created_at:)
      @id, @title, @body, @created_at = id, title, body, created_at
    end
  end
end
