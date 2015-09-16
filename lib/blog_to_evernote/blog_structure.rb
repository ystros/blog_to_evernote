require_relative 'post'

module BlogToEvernote
  class BlogStructure
    def initialize(config)
      @config = config
    end

    def id_column
      @config["id_column"]
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

    def base_url
      @config["base_url"]
    end

    def posts_query_sql
      "SELECT * FROM #{@config["table_name"]} WHERE #{@config["where_clause"] || 1}"
    end

    def convert_post_from_row(row)
      Post.new(
        id: row[id_column],
        title: row[title_column],
        body: row[body_column],
        created_at: row[created_at_column]
      )
    end
  end
end
