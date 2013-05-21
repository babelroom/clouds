<<__
  belongs_to :conference
  belongs_to :user, :creator => true
#  belongs_to    :owner, :class_name => "User", :creator => true

  # when changing this to use the correct directories, then also 
  # enhance thumbnails -- for file / presentation preview?
  has_attached_file :upload,
                    :bucket => 'bblr-uploads',
                    :storage => :s3,
#                    :path => "/:attachment/:id/:style/:filename",
                    :path => ":key_:id.:extension",
                    :s3_credentials => Rails.root.join("config/s3.yml")

  after_upload_post_process :aupp
  after_save :fixup_url

  # paperclip stuff
  Paperclip.interpolates :key do |attachment, style|
# dont use random or time, as method must deterministically recreate the same file name
#    Digest::SHA1.hexdigest("-#{attachment.instance.id.to_s}-#{rand(1000).to_s}-#{Time.now.to_s}-")
# -- TODO make this more secure? -- noted
    Digest::SHA1.hexdigest("-#{attachment.instance.id.to_s}-b3e11057c6531df07271f73785ba00f5ca-")
  end
  def aupp
    self.name = self.upload_file_name
    self.content_type = self.upload_content_type
    self.size = self.upload_file_size
  end
  def fixup_url
    if self.url.nil? and not self.id.nil?
      self.url = self.upload.url
      self.save
    end
  end 

  # --- Permissions --- #
  def create_permitted?
    acting_user.administrator?
  end

  def update_permitted?
    acting_user.administrator?
  end

  def destroy_permitted?
    return false if acting_user.guest?
    return true if self.user_id.eql? acting_user.id     # you created the file
    if (self.conference.present?) 
        return true if self.conference.owner_id.eql? acting_user.id # you own the conference that the file is assigned to
        # ad hoc SQL to test if this person is currently a conference host
        return true if Invitation.first( :conditions => {:user_id => acting_user.id, :role => 'Host', :conference_id => self.conference.id} ).present?
    end
    false
  end

  def view_permitted?(field)
    true
  end__>>
