require 'nokogiri'

module BlogToEvernote
  # Evernote's note XML format accepts only a subset of HTML.
  class EvernoteSanitizer
    PROHIBITED_HTML_ELEMENTS = [
      "applet", "base", "basefont", "bgsound", "blink", "button", "dir",
      "embed", "fieldset", "form", "frame", "frameset", "head", "iframe",
      "ilayer", "input", "isindex", "label", "layer", "legend", "link", "marquee",
      "menu", "meta", "noframes", "noscript", "object", "optgroup", "option",
      "param", "plaintext", "script", "select", "style", "textarea", "xml"
    ]

    PROHIBITED_HTML_ATTRIBUTES = [
      'id', 'class', 'onclick', 'ondblclick', 'accesskey', 'data', 'dynsrc',
      'tabindex'
    ]

    URL_ATTRIBUTES = [
      'href', 'src'
    ]

    def initialize(base_url = "file://")
      @base_url = base_url
    end

    # Removes prohibited HTML elements and attributes and converts the result to
    # XML that will be accepted by Evernote.
    def sanitize(text)
      document = Nokogiri::HTML.parse(text)
      convert_embeds(document)
      sanitize_elements(document)
      sanitize_attributes(document)
      update_relative_urls(document)
      convert_to_xml(document.at("body").inner_html)
    end

    private
    # Evernote does not allow object elements in notes. To preserve embedded
    # videos within blog posts (e.g. YouTube), these embeds should be replaced
    # with a link to the embedded media.
    def convert_embeds(document)
      convert_embed_xpath_to_url(document, "//embed[@src]") do |matching_element|
        matching_element['src']
      end
      convert_embed_xpath_to_url(document, "//param[@name='movie' or @name='src']") do |matching_element|
        matching_element['value']
      end
    end

    def convert_embed_xpath_to_url(document, xpath, &block)
      document.xpath(xpath).each do |matching_element|
        url = block.call(matching_element)
        parent_object_element = matching_element.parent
        parent_object_element.add_next_sibling(create_embed_replacement("Embed", url))
        parent_object_element.remove
      end
    end

    def create_embed_replacement(type, url)
      Nokogiri::HTML.fragment("<p><strong>#{type}:</strong> <a href=\"#{url}\">#{url}</a></p>")
    end

    def sanitize_elements(document)
      PROHIBITED_HTML_ELEMENTS.each do |element|
        document.xpath("//#{element}").each do |matching_element|
          matching_element.remove
        end
      end
    end

    def sanitize_attributes(document)
      PROHIBITED_HTML_ATTRIBUTES.each do |attribute|
        document.xpath("//*[@#{attribute}]").each do |matching_element|
          matching_element.remove_attribute(attribute)
        end
      end
    end

    def update_relative_urls(document)
      URL_ATTRIBUTES.each do |attribute|
        document.xpath("//*[@#{attribute}]").each do |matching_element|
          matching_element[attribute] = @base_url + matching_element[attribute] unless matching_element[attribute].match(/^(http|https)/)
        end
      end
    end

    def convert_to_xml(html)
      Nokogiri::HTML::DocumentFragment.parse(html).to_xml
    end
  end
end
