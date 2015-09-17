require 'mysql2'
require_relative 'config'
require_relative 'evernote_sanitizer'
require_relative 'evernote_client'

module BlogToEvernote
  # Loads posts from the configured database and adds them as notes to Evernote.
  class Importer
    def initialize(config = Config.load_file)
      @structure = config.blog_structure
      @client = create_db_client(config.database_connection)
      @evernote = EvernoteClient.new(config.evernote, EvernoteSanitizer.new(config.blog_structure.base_url, config.blog_structure.insert_paragraphs))
    end

    def import
      @evernote.request_oauth_token
      puts "Importing: "
      imported_posts = posts_for_import.map do |post|
        result = @evernote.create_note_from_post(post)
        putc result[0] ? "." : "x"
        result
      end
      puts "\n\n"

      succeeded, failed = imported_posts.partition { |result| result[0] }
      puts "Successfully imported posts: #{succeeded.length}"
      failed.each do |result|
        puts "Unable to import post ID #{result[1].id} due to error: #{result[2].inspect}"
      end
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
