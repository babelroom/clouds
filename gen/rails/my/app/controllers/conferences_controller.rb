class ConferencesController < ApplicationController

  hobo_model_controller

  auto_actions :all

  skip_before_filter :verify_authenticity_token, :only => [:lobby]  # allow recurly post to /home after signup

  def new
    if !params.nil? && !(params[:_tid].nil?) 
        @conference = Conference.find(params[:_tid], :conditions => [ "is_deleted IS NULL"])
    else
        @conference = Conference.new
    end
    @accounts = Account.find(:all, :conditions => [ "owner_id = ?", current_user.id])
    @users = User.find(:all, :order => "email_address" )  # TODO: not good long term
  end

  def edit
    @accounts = Account.find(:all, :conditions => [ "owner_id = ?", current_user.id])
    @conference = Conference.find(params[:id], :conditions => [ "is_deleted IS NULL"])
    @users = User.find(:all, :order => "email_address" )  # TODO: not good long term
  end

  def show
    @callees = Callee.find(:all, :conditions => ["conference_id = ?", params[:id]])
    @media_files = MediaFile.find(:all, :conditions => ["conference_id = ?", params[:id]])
    hobo_show
  end

  def account; hobo_show; end

  def dashboard
    @conference = Conference.find(params[:id])
#    render :layout => 'null'   # override default layout
    render :layout => false
  end

  def cs_d(a)
    result = {}
    begin
        result = (ActiveSupport::JSON.decode a) if a.present?
    end
    return result
  end

  # ---
  # somewhat complicated logic, but we'll try to lay it out ...
  # ** depreciated **
  # ---
  def can_enter_room(params,conference,invitation,user)
    access = cs_d conference[:access_config]
    is_public = access["public"]
    do_enter = params[:door_check_access].nil? || params[:door_check_access].eql?('0')
    @door_vars = {}
    # public
    if user.signed_up?
        #@door_vars[:signed_in] = true
        @door_vars[:signed_in] = false
        if invitation.nil?
            if is_public
                # no invitation, but hey, it's public ...
                @door_vars[:can_invite_self] = true
            else
                # sorry, you are not invited ...
                @door_vars[:not_invited] = true
            end
        else
            # just press the button
            return true if do_enter;
            @door_vars[:go_right_in] = true
        end
    else
        if is_public
            # OK, either login (/pin????) or *enter a nickname*
            @door_vars[:can_invite_self] = true
            @door_vars[:token] = invitation_door_precreate(conference,'New user...')
        else
            # it's private, *login* to see if you have an invite or *pin* ??????
        end
    end
    # show the door
    render "door", :layout => 'plugin'
#    render "door"
    return false
  end

  def workspace
    @conference = nil
    if @conference.nil? and not params[:id].nil?
      begin
        @conference = Conference.find(params[:id])
      rescue
        @conference = nil
      end
    end
    if @conference.nil? and not params[:uri].nil?
      uri = params[:uri].join('/')
# this is how we test for reserved names (get the reserved names from routing file)
#    if ['login','logout'].include? params[:uri]
#    end
# actually reserved names should come first, so they'll be mapped first 
# where we need to test this is when a uri is assigned ...
# but in any case here they are .. (good at the time of writing)
      @conference = Conference.find(:all, :conditions => ["uri = ?", uri]).first # further qualify
    end

    # what to do if conference not found?
    if @conference.nil?
      flash[:error] = "Conference not found"
      redirect_to "/"
      return
    end

    @invitation = nil
    # under hobo, there will always be a user, albeit "guest" -- this is how we check if they are actually "real"
    @invitation = Invitation.find(:all, :conditions => ["conference_id = ? AND user_id = ?", @conference.id, current_user.id]).first if current_user.signed_up?
    if not can_enter_room(params,@conference,@invitation,current_user)
        return
    end
    @countries = [
        { 1 => 'United States' },
        { 212 => 'Morocco' },
        { 33 => 'France' },
        { 34 => 'Spain' },
        { 351 => 'Portugal' },
        { 353 => 'Ireland' },
        { 39 => 'Italy' },
        { 44 => 'United Kingdom' },
        { 49 => 'Germany' }
        ];
    hobo_show   # Q: why are we doing this?
    render :layout => false
  end

  def home
    # --- get conferences I own *union* conferences I've been invited to
    @conferences = Conference.find(:all, :conditions=>["owner_id=? AND is_deleted IS NULL", current_user.id], :order=>"actual_end DESC") | current_user.conference_invitations
    
    # --- then split them up based on when they are happening
    @happening = Array.new
    @pending = Array.new
    @standing = Array.new
    @templates = Array.new
    @completed = Array.new
    @conferences.each do |c|
      if !c.schedule.nil?
        if c.actual_start.nil?
            if c.schedule.eql? 's'
              @standing << c
            else
              @pending << c
            end
        else
          if c.actual_end.nil?
            @happening << c # actually started, but not yet ended, therefore in progress
           else
            @completed << c # been there, seen that, done that
          end
        end
      else
        @templates << c     # not enabled, just a template
      end
    end
  end

  def lobby
    my_params = params  # -- see below ...
    @account_external_url = nil
    @account = nil
    begin
        @account = current_user.accounts[0]
        @account_external_url =$babelroom[:hosted_billing_url] + '/account/' + @account.external_token
    rescue
    end
    if request.post? 
        my_params = {}
        begin
            if params[:account_code].present? # recurly postback
                #@account.changing_flag = true -- creates a race that may leave this flag set
                # --- code below does the same but avoids the race
                conn = ActiveRecord::Base.connection();
                conn.update( "UPDATE accounts SET changing_flag=1 WHERE id = #{@account.id} AND (plan_code IS NULL OR plan_code <> '#{params[:plan_code]}')" );
                conn = nil
            elsif params[:plan_code].present? # user wants to change plan
                @account.change_to_plan_code = params[:plan_code] if ["free","solo_plan","pro_plan","flex_plan","unsubscribe"].include? params[:plan_code] 
                @account.changing_flag = true if @account.changed?
                @account.save()
            elsif params[:api_action].present? # user wants to do something with the api_key
                if (params[:api_action].to_i>0)
                    set_api_key(true)
                    flash.now[:notice] = "A new API key has been established"
                else
                    set_api_key(false)
                    flash.now[:notice] = "API access has been disabled"
                end
            end
        rescue
        end
    end
    params = my_params
    if params[:nav].eql? 'call_log'
        rows_per_page = 20
        pagination_half = 4
        page = params[:page].nil? ? 1 : [params[:page].to_i,1].max
        sort = params[:sort].present? ? params[:sort] : 'ended'
        order = params[:order].present? ? params[:order] : 'DESC'
        offset = (page-1) * rows_per_page
        limit = rows_per_page
        #account = Account.find(:all, :conditions => [ "owner_id = ?", current_user.id]).first
        account_id = -1
        if @account.present?
            account_id = @account.id
        end
        @callees = Callee.find(:all, :select => 'id,participant,started,ended,(ended-started) AS duration,accounting_desc,notes,number,external_id', :conditions => [ "account_id = ?", account_id ], :offset => offset, :limit => limit, :order => sort + ' ' + order )
        record_count = Callee.count(:conditions => [ "account_id = ?", account_id ])
        total_pages = (record_count.to_f / rows_per_page).ceil
        @summary = {
            :count => record_count,
            :last_page => total_pages,
            :first_record_on_page => offset+1,
            :last_record_on_page => offset+@callees.length,
            :paginate_first => [1,page-pagination_half].max,
            :paginate_last => [total_pages,page+pagination_half].min,
            :prev => [page-1,1].max,
            :next => [page+1,total_pages].min,
            :page => page,
            :sort => sort,
            :order => order,
            :order_inverted => (order.upcase.eql? 'ASC') ? 'DESC' : 'ASC',
            }
    elsif params[:nav].eql? 'files'
        rows_per_page = 20
        pagination_half = 4
        page = params[:page].nil? ? 1 : [params[:page].to_i,1].max
        sort = params[:sort].present? ? params[:sort] : 'created_at'
        order = params[:order].present? ? params[:order] : 'DESC'
        bucket = params[:bucket].present? ? params[:bucket] : ''
        bucket_condition = params[:bucket].blank? ? '' : " AND bucket='#{bucket}'"
        offset = (page-1) * rows_per_page
        limit = rows_per_page
        user_id = current_user.id
        @files = MediaFile.find(:all, :conditions => ["(user_id = ? OR conference_id IN (SELECT id FROM conferences WHERE owner_id = ?))#{bucket_condition}", user_id, user_id], :offset => offset, :limit => limit, :order => sort + ' ' + order )
        record_count = MediaFile.count(:conditions => ["(user_id = ? OR conference_id IN (SELECT id FROM conferences WHERE owner_id = ?))#{bucket_condition}", user_id, user_id])
        total_pages = (record_count.to_f / rows_per_page).ceil
        @summary = {
            :count => record_count,
            :last_page => total_pages,
            :first_record_on_page => offset+1,
            :last_record_on_page => offset+@files.length,
            :paginate_first => [1,page-pagination_half].max,
            :paginate_last => [total_pages,page+pagination_half].min,
            :prev => [page-1,1].max,
            :next => [page+1,total_pages].min,
            :page => page,
            :sort => sort,
            :order => order,
            :order_inverted => (order.upcase.eql? 'ASC') ? 'DESC' : 'ASC',
            :bucket => bucket,
            }
    elsif params[:nav].eql? 'api'
        flash.now[:warn] = "API access is currently disabled" if !request.post? and current_user.api_key.nil?
    end
    # home for rooms
    #render :layout => 'rooms'
    conferences = Conference.find(:all, :conditions => ["owner_id = ? AND is_deleted IS NULL AND schedule = 's'", current_user.id], :order => 'uri DESC', :limit => 1)
    @conference = nil
    if (conferences.length)
        @conference = conferences[0]
    end
    render :layout => false
  end

  def start
    @templates = Conference.find(:all, :conditions => ["owner_id = ? AND is_deleted IS NULL AND schedule IS NULL", current_user.id])
  end

  def destroy
    @conference = Conference.find(params[:id], :conditions => [ "is_deleted IS NULL"])
    @conference.is_deleted = true
    if @conference.save() 
        flash[:notice] = "Conference deleted"
        respond_to do |format|
          format.html   { redirect_to params[:after_submit] }
          format.xml    { head :ok }
        end
    else
        # TODO was not able to definitely test this is right ...
        flash[:error] = @conference.errors
        respond_to do |format|
          format.html   { redirect_to "/home" }
          format.xml    { render :xml => @conference.errors, :status => :unprocessable_entity }
        end
    end
  end

  def create
    params[:conference][:schedule] = nil if params[:conference][:schedule].eql? ''
    params[:conference][:skin_id] = 1
    hobo_create
  end

  def update
    params[:conference][:schedule] = nil if params[:conference][:schedule].eql? ''
    hobo_update
  end

  def invitation
    for retries in 1 .. 15 do
      Invitation.uncached do
        @invitation = Invitation.find(:all, :conditions => ["conference_id = ? AND user_id = ?", params[:id], current_user.id]).first
      end
      break if not @invitation.nil?
      sleep 1
    end
    if @invitation.nil?
      flash[:error] = "The conference invitation is not yet available. Please try again in a few moments."
      respond_to do |format|
        format.html   { redirect_to "/home" }
        format.xml    { head :ok }
      end
    else
      respond_to do |format|
        format.html   { redirect_to(@invitation) }
        format.xml    { head :ok }
      end
    end
  end

end
