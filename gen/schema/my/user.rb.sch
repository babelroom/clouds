<<__
  has_many :phones, :dependent => :destroy, :class_name => "Phone", :foreign_key => "owner_id"
  has_many :accounts, :class_name => "Account", :foreign_key => "owner_id", :dependent => :destroy
  has_many :conferences, :class_name => "Conference", :foreign_key => "owner_id"
  has_many :emails, :dependent => :destroy, :class_name => "Email", :foreign_key => "owner_id"
  has_many :invitations, :dependent => :destroy
  has_many :conference_invitations, :through => :invitations, :source => :conference, :conditions => ['is_deleted IS NULL']
  has_many :tokens, :dependent => :destroy
  has_many :media_files, :dependent => :destroy

  # JR -- this is profile related
#  belongs_to :conference, :class_name => "Conference"

  # paperclip
  has_attached_file :photo,
                    :bucket => 'cs-photos',
                    :storage => :s3,
                    :path => "photos/:id/:style/:filename",
                    #:path => ":id",
#                    :url => "photos/:id/:style_:basename.:extension",
                    :default_url => "missing_:style.png",
                    :s3_credentials => Rails.root.join("config/s3.yml"),
                    :styles => { :thumb=> "50x50#", :normal  => "128x128>" }
#  after_upload_post_process :aupp

  # ---
  def full_name
    ((self.name.nil?)?'':self.name) + ' ' + ((self.last_name.nil?)?'':self.last_name)
  end

  # --- Signup lifecycle --- #

  lifecycle do

# to force activation email:
# comment out next line
    state :active, :default => true
# the uncomment next
#    state :active


    state :inactive, :default => true

    create :signup, :available_to => "Guest",
           :params => [:name, :last_name, :email_address, :timezone, :company, :password, :password_confirmation],
# to force activation email:
# comment out next line
           :become => :active
# then uncomment these 5
#           :become => :inactive do
##host = Hobo::Controller.request_host
#        req = Token.new(:template => 'activate', :user_id => self.id)
#        req.save()
#    end




#    transition :activate, { :inactive => :active }, :available_to => :key_holder




             
    transition :request_password_reset, { :active => :active }, :new_key => true do
#      UserMailer.deliver_forgot_password(self, lifecycle.key)
        req = Token.new(:template => 'forgot_password', :user_id => self.id)
        req.save()
    end




    transition :request_password_reset, { :inactive => :inactive }, :new_key => true do
#      UserMailer.deliver_activation(self, lifecycle.key)
        req = Token.new(:template => 'forgot_password', :user_id => self.id)
        req.save()
    end

#    transition :reset_password, { :active => :active }, :available_to => :key_holder,
#               :params => [ :password, :password_confirmation ]

  end
  

  # --- Permissions --- #

  def create_permitted?
    false
  end

  def update_permitted?
    acting_user.signed_up?
#    acting_user.administrator? || 
#      (acting_user == self && only_changed?(:email_address, :crypted_password,
#                                            :current_password, :password, :password_confirmation))
    # Note: crypted_password has attr_protected so although it is permitted to change, it cannot be changed
    # directly from a form submission.
  end

  def destroy_permitted?
    acting_user.administrator?
  end

  def view_permitted?(field)
    true
  end

__>>
