require 'rubygems'
require 'bundler/setup'
Bundler.setup(:default)

require_relative 'blog_to_evernote/importer'

importer = BlogToEvernote::Importer.new
importer.import
