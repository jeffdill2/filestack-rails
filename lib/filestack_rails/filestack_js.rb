require 'net/http'

class Picker
  attr_reader :url

  def initialize
    raise 'Incorrect config.filestack_rails.version' unless url_exists?(filestack_js_url)
    @url = filestack_js_url
  end

  def version
    ::Rails.application.config.filestack_rails.version
  end

  def security(signature, policy)
    { security: { signature: signature, policy: policy } }.to_json
  end

  def filestack_js_url
    "https://static.filestackapi.com/filestack-js/#{version}/filestack.min.js"
  end

  def picker(client_name, api_key, options, callback, other_callbacks = nil)
    options_string = options[1..-2] # removed curly brackets help to generate pickerOptions in js

    <<~HTML
      (function(){
        #{client_name}.picker({ onUploadDone: data => #{callback}(data)#{other_callbacks}, #{options_string} }).open()
      })()
    HTML
  end

   def url_exists?(url)
     uri = URI(url)
     request = Net::HTTP.new(uri.host)
     response = request.request_head(uri.path)
     response.code.to_i == 200
   rescue
     false
   end
end

class OutdatedPicker < Picker
  def filestack_js_url
    'https://static.filestackapi.com/v3/filestack.js'
  end

  def picker(client_name, api_key, options, callback, other_callbacks = nil)
    <<~HTML
      (function(){
        #{client_name}.pick(#{options}).then(function(data){#{callback}(data)})
      })()
    HTML
  end

  def security(signature, policy)
    { signature: signature, policy: policy }.to_json
  end
end

module FilestackRails
  module FilestackJs
    OUTDATED_VERSION = '0.11.5'

    def get_filestack_js
      if ::Rails.application.config.filestack_rails.version == OUTDATED_VERSION
        OutdatedPicker.new
      else
        Picker.new
      end
    end
  end
end