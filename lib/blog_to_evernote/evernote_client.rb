require 'uri'
require 'cgi'
require 'evernote_oauth'

module BlogToEvernote
  class EvernoteClient
    def initialize(evernote_config, sanitizer = EvernoteSanitizer.new)
      @auth_token = evernote_config['auth_token']
      @tags = evernote_config['tags'] || []
      @client = EvernoteOAuth::Client.new(token: @auth_token, consumer_key: evernote_config['key'], consumer_secret: evernote_config['secret'], sandbox: evernote_config['sandbox'])
      @sanitizer = sanitizer
    end

    def request_oauth_token
      return if @auth_token
      callback_url = "http://ystros.com"
      request_token = @client.request_token(:oauth_callback => callback_url)
      puts "Go to this URL:"
      puts request_token.authorize_url
      puts "Once you've authorized the app, paste in the URL you were redirected to:"
      return_url = URI.parse(gets)
      callback_params = CGI::parse(return_url.query)
      access_token = request_token.get_access_token(oauth_verifier: callback_params['oauth_verifier'][0])
      puts "Please save the following to your config under evernote as auth_token: #{access_token.token}"
      @auth_token = access_token.token
      puts "Once you've done this, rerun `rake run`"
      exit
    end

    def create_note_from_post(post)
      our_note = convert_post_to_edam(post)
      begin
        handle_rate_limit(3) do
          note = @client.note_store.createNote(our_note)
          [true, post, note]
        end
      rescue => e
        [false, post, e]
      end
    end

    def handle_rate_limit(retries_left, &block)
      begin
        block.call
      rescue Evernote::EDAM::Error::EDAMSystemException => e
        if e.errorCode == Evernote::EDAM::Error::EDAMErrorCode::RATE_LIMIT_REACHED && retries_left > 0
          puts ""
          puts "Currently rate limited for #{e.rateLimitDuration} seconds"
          sleep e.rateLimitDuration + 1
          handle_rate_limit(retries_left - 1, &block)
        else
          raise
        end
      end
    end

    def convert_post_to_edam(post)
      n_body = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
      n_body += "<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">"
      n_body += "<en-note>#{@sanitizer.sanitize(post.body)}</en-note>"

      ## Create note object
      our_note = Evernote::EDAM::Type::Note.new
      our_note.title = post.title
      our_note.content = n_body
      our_note.created = post.created_at.to_time.to_i * 1000
      our_note.tagNames = @tags
      our_note
    end
  end
end
