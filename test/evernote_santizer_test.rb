require 'test_helper'
require 'blog_to_evernote/evernote_sanitizer'

describe BlogToEvernote::EvernoteSanitizer do
  before do
    @sanitizer = BlogToEvernote::EvernoteSanitizer.new
  end

  it "filters out prohibited elements" do
    @sanitizer.sanitize("<p>Foo <object>baz</object> bar</p>").must_equal "<p>Foo  bar</p>"
  end

  it "filters out prohibited attributes" do
    @sanitizer.sanitize("<p class=\"myclass\" id=\"myid\" alt=\"myalt\">Foo bar</p>").must_equal "<p alt=\"myalt\">Foo bar</p>"
  end

  it "converts to XML notation" do
    @sanitizer.sanitize("<p>Foo<br>bar</p>").must_equal "<p>Foo<br/>bar</p>"
  end

  it "prefixes relative URLs" do
    actual = @sanitizer.sanitize("<a href=\"/hello\"><img src=\"/world\"/></a>")
    expected = Nokogiri::HTML::DocumentFragment.parse("<a href=\"file:///hello\"><img src=\"file:///world\"/></a>").to_xml
    actual.must_equal expected
  end
end
