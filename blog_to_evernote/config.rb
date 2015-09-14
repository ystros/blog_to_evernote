require 'yaml'
require_relative 'blog_structure'

module BlogToEvernote
  class Config
    attr_reader :database_connection, :blog_structure

    def initialize(options)
      @database_connection = options["database_connection"]
      @blog_structure = BlogStructure.new(options["blog_structure"])
    end

    def self.load_file
      Config.new(YAML.load_file("config.yml"))
    end
  end
end
