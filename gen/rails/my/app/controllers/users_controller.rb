class UsersController < ApplicationController

  hobo_user_controller

  auto_actions :all, :except => [ :index, :new, :create ]

  # ---
  # override default logged_in? to exclude ephemerally logged in users
  # not so sure this is the correct place to override this method ...
  # actually that was a disaster (defining logged_in? here).
  # that **** hobo couldn't even decide where to take it's obligatory cluster-dump
  # we >>NEED<< to dump hobo and maybe rails
  # ... trying this ...
  def ephemerally_logged_in?
    !current_user.guest? and current_user.email_address?
  end

  # --- these methods for hidden admin access only (disabled now from routes)
  def admin
    @users = []
    render :layout => false
  end
  def admin_set_current_user
    model = params[:model] || Hobo::User.default_user_model
    self.current_user = if params[:login]
                          model.find(:first, :conditions => {model.login_attribute => params[:login]})
                        else
                          model.find(params[:id])
                        end
    redirect_to(request.env["HTTP_REFERER"] ? :back : home_page)
  end
  # --- end admin special action

  def edit
    @alt_emails = Email.find(:all, :conditions => [ "owner_id = ?", params[:id]])
    hobo_show
  end

  def password
    if current_user.encrypt("").eql? current_user.crypted_password
        @no_current_password = true
    end
    hobo_show
  end

  def update
    if request.put? and params[:user][:password].present? and !params[:user][:current_password].present?
        if current_user.encrypt("").eql? current_user.crypted_password
            params[:user][:current_password] = '';
        end
    end
    @alt_emails = Email.find(:all, :conditions => [ "owner_id = ?", params[:id]])
    if current_user.encrypt("").eql? current_user.crypted_password
        @no_current_password = true
    end
    hobo_update
  end

  def contact
    @user = current_user
  end

  def social
    if request.get?
      hobo_show
    else
      hobo_update
    end
  end 

  def show
    @alt_emails = Email.find(:all, :conditions => [ "owner_id = ?", params[:id]])
    @phones = Phone.find(:all, :conditions => [ "owner_id = ?", params[:id]])
    hobo_show
  end

  def go
# changed this 6.4.2013 -- 
#    req = Token.find(:all, :conditions => ["user_id=? AND user_id IS NOT NULL AND is_deleted IS NULL AND (expires>? OR expires IS NULL) AND link_key=?",
#            params[:id], Time.now(), params[:key]]).first
    req = Token.find(:all, :conditions => ["user_id=? AND user_id IS NOT NULL AND is_deleted IS NULL AND (expires>NOW() OR expires IS NULL) AND link_key=?",
            params[:id], params[:key]]).first
    user = User.find(params[:id])
    if req.nil? or user.nil?
        flash[:error] = "Invalid or expired link. Activation or password reset links may only be used once. "
        redirect_to :login
        return
    end

    if req.template.eql? 'activate' and user.account_active?
        flash[:error] = "This account has already been activated, please login using your username and password"
        redirect_to :login
        return
    end

    # --- if account not active then make it so
    if not user.account_active?  and not user.lifecycle.become(:active,false) 
        flash[:error] = "Internal error ...(1)"
        redirect_to :login
        return
    end

    # --- active and reset password requests can only be used once => delete 'em
    if not req.template.eql? 'invite'
        req.is_deleted = true
        if not req.save()
            puts "ERROR: failed to save token (i.e. mark as deleted): " << req.inspect
        end 
    end

    # --- login as that user
    old_user = current_user
    self.current_user = user

    # --- create default user account/template conference, if they don't exist
    # --- formerly not doing this for "forgot_password" but then realized users may use forgot_password
    # if the invite email got lost, therefore .. do this in all cases
    if current_user.accounts.count()==0
        create_master_records(current_user,nil)
    end

    case req.template
    when 'invite'
#        flash[:notice] = "Your password has been reset, please set a new password"
    when 'activate'
        flash[:notice] = "Your account has been activated."
    when 'forgot_password'
        user = User.find(current_user.id)
        if !user.nil?
            user.crypted_password = user.encrypt("")
            if !user.save()
                flash[:error] = "Internal error ...(2)"
            else
                flash[:notice] = "Your password has been reset, please set a new password"
            end
        else
            flash[:error] = "Internal error ...(3)"
        end
    else
        flash[:error] = "Internal error ...(4)"
        puts "ERROR: unknown template: " << req.template
    end
    redirect_to "/home"
  end

  def self_register
    invitation = Invitation.new(params[:invitation])
    no_pretoken = invitation[:token].empty?
#p no_pretoken.inspect
    user = params[:user]
    if not no_pretoken
        found_invitation = invitation_find_new_guest(invitation)
        if found_invitation.nil?
            no_pretoken = true
        else
            invitation = found_invitation
        end
    end
    if no_pretoken
        invite_string = invitation_create_invite_string(invitation,user)
        invitation = invitation_precreate(invitation,user,invite_string)
        invite_string = invitation_create_invite_string(invitation,user)
        invitation = invitation_do_add_guest(invitation,user,invite_string)
    end
    if not invitation.nil?
        user = User.find_by_id(invitation.user_id)
        if not user.nil?
            old_user = current_user
            self.current_user = user
            if (not no_pretoken) and params[:user].present? and params[:user][:name].present?
                user.update_attribute(:name,params[:user][:name])
            end
        else
            invitation = nil
        end
    end
    # note -- right now, this is only used by html POST, not js
    if invitation.nil?
        respond_to do |wants|
            wants.html { redirect_to params[:page_path] }
            wants.js { render :json => [{:error => "error"}], :status => 500 }
        end
    else 
        respond_to do |wants|
            wants.html { redirect_to params[:after_submit] }
            wants.js { render :json => [ invitation ] }
        end
    end
  end

  def create_master_records(user,uri)
    id = user.id
    new_account_code = nil
    name = (user.name.nil?) ? '' : user.name
    last_name = (user.last_name.nil?) ? '' : user.last_name

    # account
    account = Account.find(1).clone
    account.owner_id = id
    account.name = name + "'s " + account.name
    return new_account_code unless account.save()
    new_account_code = $babelroom[:new_account_prefix] + account.id.to_s()

    # do we already have at least one conference?
    return new_account_code if Conference.count(:conditions => 'owner_id = '+id.to_s)>0

    # original clone setup created a template conference
    conference = Conference.find(1).clone
    conference.name = name + "'s " + conference.name
    conference.owner_id = id
    conference.account_id = account.id
    conference.uri = uri if defined? uri and uri.present?   # leave nil if empty string ...

    # for the present pre-create a standing conference
    conference.name = name + "'s Standing Conference"
    conference.schedule = 's'
    # should escape next (if so then escape also in conference form)
    # don't this anymore, as the participant_emails based approach has been depreciated
    #conference.participant_emails = "Host:" + name + ":" + last_name + ":" + email + "::\r\n"
    #but we do have to make an invitation record for the host
    return new_account_code unless conference.save()

    new_invitation(id, conference.id, true)

    return new_account_code
  end
 
  def conversion_tracker_js
    return <<__EOT__
<!-- Google Code for Complete Signup Conversion Page -->
</div>
<script type="text/javascript">
/* <![CDATA[ */
var google_conversion_id = 00000000000;
var google_conversion_language = "en";
var google_conversion_format = "2";
var google_conversion_color = "ffffff";
var google_conversion_label = "dHQaaaaaaaaaaIQkYT40QM";
var google_conversion_value = 0;
/* ]]> */
</script>
<script type="text/javascript" src="http://www.googleadservices.com/pagead/conversion.js">
</script>
<noscript>
<div style="display:inline;">
<img height="1" width="1" style="border-style:none;" alt="" src="http://www.googleadservices.com/pagead/conversion/00000000/?label=daaaaaaaaT40QM&amp;guid=ON&amp;script=0"/>
</div>
</noscript>
<div>
__EOT__
  end

  # override default
  def signup
    render
  end

  # these 2 are private helper methods
  def ue(p); (params[:user][p].blank?) ? '' : CGI::escape(params[:user][p]); end
  def up(p,n); (params[:user][p].blank?) ? '' : '&' + n + '=' + CGI::escape(params[:user][p]); end

  def do_signup
    if logged_in? and request.post?
      logout_current_user
    end
    params[:user][:email] = params[:user][:email_address]
    hobo_do_signup do
        if valid?
            force_activation = false    # force the user to activate via email
            if this.errors.blank?
                if (force_activation)
                    # conversion tracker js
                    flash[:notice] = "An activation link has been sent to " << this.email_address << ". Please click the link to activate your account."
                else
                    flash[:notice] = "Welcome! You have signed-up as " << this.email_address << conversion_tracker_js
                end
            end
            if (force_activation)
                redirect_to :login
            else
                self.current_user = this if this.account_active?
                new_account_code = create_master_records(this,params[:room_url])
                plan_code = params[:plan_code]
                if plan_code.present?
                    redirect_to $babelroom[:subscribe_url]+'/'+plan_code+'/'+new_account_code +'/' + ue('email_address') + '?quantity=1' + up('name','first_name') + up('last_name','last_name') + up('email_address','email')
                elsif params[:welcome].present?
                    redirect_to params[:welcome]
                else
                    redirect_to '/home'
                end
            end
        else
#            puts "XX NOT SIGNED UP!"
        end
    end
  end

  # --- b/c the hobo login mechanism is pretty inconsistent on what it does with errors
  def login

    # why?, ==> because hobo is a(n uber) crock
#    if logged_in? and request.get?
#p 'logging out user'
##      logout_current_user
#      options = {:notice => nil}
#      hobo_logout(options)
#    end

    # why?, ==> because hobo is a crock
#    if logged_in?
#    if false
#p 'logged in'
#      respond_to do |wants|
##        wants.html { redirect_to home_page }
#        wants.html { render }
#        wants.js { hobo_ajax_response }
#      end
#      return
#    end

#    if request.get?
#      redirect_to "/"
#      return
#    end

# was playing with this ..
#    was_logged_in = logged_in?
#    if was_logged_in and request.get?   # and maybe also if ephemeral?
#      logout_current_user
#    end

    if !ephemerally_logged_in? and request.post?
      if params[:password].eql? ''
        # disallow regular login on empty password (such as when a user clicks on reset link in email)
        flash[:error] = 'Invalid username or password'
        respond_to do |wants|
          wants.html { redirect_to params[:page_path] }
          wants.js { hobo_ajax_response } # test this (ajax response)?
        end
        return
      end
      # --- this actually duplicates what hobo_login will do, but ...
      user = model.authenticate(params[:login], params[:password])
      if user.nil?
        flash[:error] = 'Invalid username or password'
        respond_to do |wants|
          wants.html { redirect_to params[:page_path] }
          wants.js { hobo_ajax_response }
        end
        return
      else
        if !user.account_active?
          flash[:error] = 'Your account requires activation.<p>Please check your e-mail for the activation link. We recommend you also check your e-mail "spam" folder.<p>If you do not have the activation e-mail, or if the activation key has expired you can request a new one via the "Forgot Password?" link below.'
          respond_to do |wants|
            wants.html { render params[:page_path] }
            wants.js { hobo_ajax_response }
          end
          return
        end
      end
    end
    hobo_login({:redirect_to => params[:after_submit], :success_notice => nil})
  end

  def logout
    options = {:notice => nil}
    options |= {:redirect_to => params[:after_submit]} if params[:after_submit].present?
    hobo_logout(options)
  end
  
  # --- again overriding the default b/c it hard-codes the response tag
  def hobo_forgot_password
    if request.post?
      params[:email_address] = params[:login] if params[:email_address].nil?
      user = model.find_by_email_address(params[:email_address])
      if user && (!block_given? || yield(user))
        user.lifecycle.request_password_reset!(:nobody)
      end

      if user
        flash[:notice] = "A password reset link has been sent to " << params[:email_address]
      else
        flash[:error] = "No user for email address " << params[:email_address]
      end
      redirect_target = (defined? params['page_path']) ? params['page_path'] : "/login"
      respond_to do |wants|
        wants.html { redirect_to redirect_target }
        wants.js { hobo_ajax_response}
      end
    end
  end

  def search
    if not request.get?
      return
    end
    users = User.find(:all, :select => "id, name, email_address AS label, last_name", :conditions => [ "email_address LIKE ?", params[:term] + '%'])
    respond_to do |wants|
      wants.html    { render }
      wants.js      { render :json => users }
    end
  end

end

