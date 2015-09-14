module BlogToEvernote
  class Post
    attr_reader :title, :body, :created_at

    def initialize(title, body, created_at)
      @title, @body, @created_at = title, body, created_at
    end
  end
end
