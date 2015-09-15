require 'uri'
require 'cgi'
require 'evernote_oauth'

module BlogToEvernote
  class EvernoteClient
    def initialize(evernote_config)
      @auth_token = evernote_config['auth_token']
      @tags = evernote_config['tags'] || []
      @client = EvernoteOAuth::Client.new(token: @auth_token, consumer_key: evernote_config['key'], consumer_secret: evernote_config['secret'], sandbox: evernote_config['sandbox'])
    end

    def request_oauth_token
      return if @auth_token
      callback_url = "http://ystros.com"
      request_token = evernote.request_token(:oauth_callback => callback_url)
      puts "Go to this URL:"
      puts request_token.authorize_url
      puts "Once you've authorized the app, paste in the URL you were redirected to:"
      return_url = URI.parse(gets)
      callback_params = CGI::parse(return_url.query)
      access_token = request_token.get_access_token(oauth_verifier: callback_params['oauth_verifier'][0])
      puts "Please save the following to your config under evernote as auth_token: #{access_token.token}"
      @auth_token = access_token.token
    end

    def create_note_from_post(post)
      our_note = convert_post_to_edam(post)

      begin
       note = @client.note_store.createNote(our_note)
       [true, post, note]
      rescue Evernote::EDAM::Error::EDAMUserException => edue
       ## Something was wrong with the note data
       ## See EDAMErrorCode enumeration for error code explanation
       ## http://dev.evernote.com/documentation/reference/Errors.html#Enum_EDAMErrorCode
       [false, post, edue]
      rescue Evernote::EDAM::Error::EDAMNotFoundException => ednfe
       ## Parent Notebook GUID doesn't correspond to an actual notebook
       [false, post, ednfe]
      end
    end

    def convert_post_to_edam(post)
      n_body = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
      n_body += "<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">"
      n_body += "<en-note>#{post.body}</en-note>"

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
