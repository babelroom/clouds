# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
#class ApplicationController < ActionController::Base
class ApplicationController < GridApplicationController
  layout :which_layout

  before_filter :login_required, :except => [ :login, :tm_login, :go_landing, :tm_landing, :signup, :do_signup, :reset_password, :guest, :go, :tm_login, :contact, :admin, :aq, :self_register, :workspace ]

  def login_required
    if current_user.guest?
      redirect_to login_invite_url
    end
  end

  before_filter :set_timezone

  def set_timezone
    if !current_user.guest?
      Time.zone = current_user.timezone
    end
  end

  def which_layout
    params[:plugin]==true ? "plugin" : (params[:layout].present? ? params[:layout] : "application")
  end

  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  def new_invitation(user_id, conference_id, is_host)
    invite = Invitation.new({:user_id => user_id, :conference_id => conference_id})
    invite.save()
    res = Pin.update_all({:invitation_id => invite.id}, 'invitation_id IS NULL', :limit => 1)
    invite[:pin] = Pin.find(:first, :conditions => {:invitation_id => invite.id}).pin
    invite[:role] = 'Host' if is_host
    invite[:dialin] = '(415) 449 8899' if is_host
    invite.save()
  end

  def random_filler_no_colon(fillerLen)
    #colon = ':'[0].ord; filler = SecureRandom.random_bytes(fillerLen).each_byte.map{|b| ((b==colon)?'j':b.chr) }.join   # bytes, therefore 1:1
    #filler = '-------------------------------------------------------------------------------------'
    filler = SecureRandom.base64((fillerLen/4)*3)   # base64 doesn't contain colons
    return filler
  end
  def api_key_encrypt(s)
    secret = ActionController::Base.session_options[:secret]
    cipher = OpenSSL::Cipher::AES.new(128,:CFB)
    cipher.encrypt
    cipher.key = secret[16..31]
    cipher.iv = secret[48..63]
    e = cipher.update(s) + cipher.final
    return e
  end
  def set_api_key(set_or_unset)
    new_key = nil
    if (set_or_unset)
        s = ":%x:" % current_user.id
        byteLen = 16  # multiple of 4 and 1/2 final (ascii - hex) length
        fillerLen = byteLen / 2
        filler = random_filler_no_colon(fillerLen)
        s = filler[0..((byteLen-s.length)/2)]+s
        filler = random_filler_no_colon(fillerLen)
        s += filler[0..((byteLen-s.length)-1)]
        s = api_key_encrypt(s)
        s = s.each_byte.map {|b| "%02x" % b }.join
        new_key = s
    end
    rec = User.find_by_id(current_user.id)
    rec[:api_key] = new_key
    rec.update() and current_user[:api_key] = new_key;
  end

end

