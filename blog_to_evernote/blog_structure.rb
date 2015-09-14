require_relative 'post'

module BlogToEvernote
  class BlogStructure
    def initialize(config)
      @config = config
    end

    def title_column
      @config["title_column"]
    end

    def body_column
      @config["body_column"]
    end

    def created_at_column
      @config["created_at_column"]
    end

    def posts_query_sql
      "SELECT * FROM #{@config["table_name"]}"
    end

    def convert_post_from_row(row)
      Post.new(
        row[title_column],
        row[body_column],
        row[created_at_column]
      )
    end
  end
end
