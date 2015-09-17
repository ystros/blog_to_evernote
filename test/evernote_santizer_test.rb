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

  it "converts object elements with embed sub-elements into URLs" do
    html = <<HTML
      <object width="560" height="340">
        <param name="movie" value="http://www.youtube.com/v/ta-Z_psXODw&hl=en&fs=1&"></param>
        <param name="allowFullScreen" value="true"></param>
        <param name="allowscriptaccess" value="always"></param>
        <embed src="http://www.youtube.com/v/ta-Z_psXODw&hl=en&fs=1&" type="application/x-shockwave-flash" allowscriptaccess="always" allowfullscreen="true" width="560" height="340"></embed>
      </object>
HTML
    actual = @sanitizer.sanitize(html).strip
    expected = Nokogiri::HTML::DocumentFragment.parse("<p><strong>Embed:</strong> <a href=\"http://www.youtube.com/v/ta-Z_psXODw&amp;hl=en&amp;fs=1&amp;\">http://www.youtube.com/v/ta-Z_psXODw&amp;hl=en&amp;fs=1&amp;</a></p>").to_xml
    actual.must_equal expected
  end

  it "converts object elements with param@src sub-elements into URLs" do
    html = '<object width="425" height="344" data="http://www.youtube.com/v/-Psfn6iOfS8&amp;hl=en&amp;fs=1&amp;" type="application/x-shockwave-flash"><param name="allowFullScreen" value="true" /><param name="allowscriptaccess" value="always" /><param name="src" value="http://www.youtube.com/v/-Psfn6iOfS8&amp;hl=en&amp;fs=1&amp;" /><param name="allowfullscreen" value="true" /></object>'
    actual = @sanitizer.sanitize(html).strip
    expected = Nokogiri::HTML::DocumentFragment.parse("<p><strong>Embed:</strong> <a href=\"http://www.youtube.com/v/-Psfn6iOfS8&amp;hl=en&amp;fs=1&amp;\">http://www.youtube.com/v/-Psfn6iOfS8&amp;hl=en&amp;fs=1&amp;</a></p>").to_xml
    actual.must_equal expected
  end

  it "inserts paragraphs when desired" do
    sanitizer = BlogToEvernote::EvernoteSanitizer.new("file://", true)
    html = "The quick brown fox\njumps over\n\nthe lazy dog"
    expected = Nokogiri::HTML.fragment("<p>The quick brown fox<br/>jumps over</p><p>the lazy dog</p>").to_xml
    sanitizer.sanitize(html).must_equal expected
  end
end
