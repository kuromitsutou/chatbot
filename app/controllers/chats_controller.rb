require 'net/http'
require 'uri'
require 'json'
require 'docomoru'

class ChatsController < ApplicationController
  protect_from_forgery except: :index

  @@botname = ENV["BOT_NAME"]
  @@t = 0
  @@mode = ""

  def post_to_typetalk(message,post_id)

      # typetalk setting
      typetalk_topic_id = ENV["TYPETALK_TOPIC_ID"]
      typetalk_token = ENV["TYPETALK_TOKEN"]
      typetalk_url = URI.parse(URI.escape("/api/v1/topics/#{typetalk_topic_id}?typetalkToken=#{typetalk_token}"))

      # post to typetalk
      http = Net::HTTP.new('typetalk.in', 443)
      http.use_ssl = true
      request = Net::HTTP::Post.new(typetalk_url.to_s)
      request.set_form_data(message: message, replyTo: post_id)
      response = http.request(request)

  end

  def post_to_docomo_api(message,last_dialogue)

      docomo_client = Docomoru::Client.new(api_key: ENV["DOCOMO_API_KEY"])
      docomo_api_param = {}

      if !last_dialogue.nil?
          docomo_api_param["t"] = last_dialogue.t
          docomo_api_param["mode"] = last_dialogue.mode
          docomo_api_param["da"] = last_dialogue.da
          docomo_api_param["context"] = last_dialogue.context
      end

      if @@t != 0
          docomo_api_param["t"] = @@t
      end
      if @@mode != ""
          docomo_api_param["mode"] = @@mode
      end

      return docomo_client.create_dialogue(message,docomo_api_param)
  end

  def set_mode(user_message)
    @@t = 0
    @@mode = ""

    if user_message.include?("デフォルトキャラ")
        @@t = 10
        return "デフォルトキャラ"
    elsif user_message.include?("関西弁キャラ")
        @@t = 20
        return "関西弁キャラ"
    elsif user_message.include?("赤ちゃんキャラ")
        @@t = 30
        return "赤ちゃんキャラ"
    end

    if user_message.include?("雑談モード")
        @@mode = "dialog"
        return "雑談モード"
    elsif user_message.include?("しりとりモード")
        @@mode = "srtr"
        return "しりとりモード"
    end

    return ""
  end

  def save_last_dialogue(last_dialogue_infos,response,user_name)
    if last_dialogue_infos.nil?
        param = {}
        param["user_name"] = user_name
        param["mode"] = response.body['mode']
        param["da"] = response.body['da']
        param["context"] = response.body['context']
        if @@t != 0
            param["t"] = @@t
        end
        last_dialogue_infos = Dialogue.new(param)
    else
      last_dialogue_infos.mode = response.body['mode']
      last_dialogue_infos.da = response.body['da']
      last_dialogue_infos.context = response.body['context']
      if @@t != 0
          last_dialogue_infos.t = @@t
      end
    end
    last_dialogue_infos.save!
  end

  def index
    # get message from typetalk
    post_content = JSON.parse(request.body.read)
    user_message = post_content['post']['message'].delete("@#{@@botname}+ ")
    user_name = post_content['post']['account']['name']
    post_id = post_content['post']['id']
    com_message = '';
    last_dialogue = Dialogue.find_by(user_name: user_name)

    # mode setting
    mode = set_mode(user_message)

    # get message from docomo API
    response = post_to_docomo_api(user_message,last_dialogue)
    com_message = response.body['utt']

    # save last dialogue
    save_last_dialogue(last_dialogue,response,user_name)

    # send message to typetalk
    post_to_typetalk(com_message,post_id)
  end
end
