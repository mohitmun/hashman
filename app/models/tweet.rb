class Tweet < ActiveRecord::Base

  after_create :after_create
  has_many :hashtag_mappings
  has_many :hashtags, :through => :hashtag_mappings, :source => :hashtag
  store_accessor :json_store, :message_id, :chat_id, :visibility, :teamId

  scope :viewable, -> (teamId) {where("json_store ->> 'visibility' = ? OR (json_store ->> 'teamId' = ? AND json_store ->> 'visibility' = ?)", "flock", "#{teamId}", "team")}


  def after_create
    hashtags_string = content.scan(/#\S+/)
    hashtags_string.each do |hashtag|
      hashtags.create(content: hashtag[1..-1])
    end
  end

  def flock_ml
    # <flockml> click <action id='act1' type='openWidget' url='https://83ccbc32.ngrok.io/tweets?hashtag=adas' desktopType='sidebar' mobileType='modal'>here</action> to launch a widget. </flockml>
    root = content
    hashtags.each do |h|
      hashtag_link = "<action id='act1' type='openWidget' url='https://83ccbc32.ngrok.io/tweets?hashtag=#{h.content}' desktopType='sidebar' mobileType='modal'>##{h.content}</action>"
      root = root.gsub("##{h.content}", hashtag_link)
    end
    "<flockml> #{root} </flockml>"
  end

  def html_view
    # <flockml> click <action id='act1' type='openWidget' url='https://83ccbc32.ngrok.io/tweets?hashtag=adas' desktopType='sidebar' mobileType='modal'>here</action> to launch a widget. </flockml>
    root = content
    hashtags.each do |h|
      hashtag_link = "<a href='https://83ccbc32.ngrok.io/tweets?hashtag=#{h.content}'>##{h.content}</a>"
      root = root.gsub("##{h.content}", hashtag_link)
    end
    return root
  end

  def is_mine?(my_id)
    from_id == my_id
  end

  def visibility_message
    case visibility
    when "team"
      "Anyone on Team"
    when "flock"
      "Anyone on Flock"
    when "private", nil
      "Private to this chat"
    end
  end
  
  def next_visibility
    case visibility
    when "team"
      self.visibility = "flock"
    when "flock"
      self.visibility = "private"
    when "private", nil
      self.visibility = "team"
    end
    self.save
  end

  def get_user_info(current_user, userid)
    user = User.find_by(flock_user_id: userid) rescue nil
    if !user
      puts "==== fetching punlic profile ===== "
      public_profile = current_user.get_public_profile(userid)
      user = User.create(firstName: public_profile["firstName"], lastName: public_profile["lastName"], profileImage: public_profile["profileImage"], flock_user_id: public_profile["id"], password: "User1234", email: "#{public_profile['id'].split(':')[1]}@flockgfw.com")
    end
    return {profileImage: user.profileImage, firstName: user.firstName, lastName: user.lastName}
  end

  def from_info(current_user)
    return get_user_info(current_user, from_id)
  end

  def to_info(current_user)
    return get_user_info(current_user, to_id)
    
  end


end
