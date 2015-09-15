require 'mysql2'
require_relative 'config'

module BlogToEvernote
  class Importer
    def initialize
      config = Config.load_file
      @structure = config.blog_structure
      @client = create_db_client(config.database_connection)
    end

    def import
    end

    def posts_for_import
      results = @client.query(@structure.posts_query_sql);
      posts = []
      results.each do |row|
        posts << @structure.convert_post_from_row(row)
      end
      posts
    end

    private
    def create_db_client(database_connection)
      Mysql2::Client.new(database_connection)
    end
  end
end
