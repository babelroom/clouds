class FrontController < ApplicationController

  hobo_controller

  def landing
    if current_user.signed_up?
      redirect_to "/home"
    else
      redirect_to $babelroom[:marcom_url] + '/'
    end
  end

  def go_landing; landing; end
  def tm_landing; landing; end

  def summary
    if !current_user.administrator?
      redirect_to user_login_path
    end
  end

  def search
    if params[:query]
      site_search(params[:query])
    end
  end

  def aq_depreciated
    klass = nil
    cmd = nil
    sql = nil
    result = nil
    args = nil
    if request.post?
        begin
            model = nil
            if not params[:act].nil?
                str = [
                    "0",
                    "user/select/SELECT phone FROM users WHERE id = ?",
                    "user/sql/UPDATE users SET phone = ? WHERE id = ?",
                    "user/update",
                    "media_file/select/SELECT * FROM media_files WHERE user_id = ? OR conference_id = ?",
                    "invitation/select/SELECT i.pin, i.user_id, u.name, u.last_name, CONCAT(u.name,' ',u.last_name) AS full_name, i.role, u.phone, u.email_address FROM invitations i, users u WHERE i.user_id = u.id AND i.conference_id = ?",
                    "user/select/SELECT id FROM users WHERE email_address=? LIMIT 1",
                    "skin/select/SELECT id,name,immutable,preview_url FROM skins",            # 7
#                    "skin/sql/INSERT INTO skins (name) VALUES (?)",     # 8
                    "skin/insert",     # 8
                    "skin/copy",
                    "skin/update",                                      # 10 
                    "conference/update",                                # 11
#                    "skin/select/SELECT body FROM skins WHERE id = ? -- ignore name param = ?", -- leave as example of using comment for unwanted parameters
                    "skin/delete",            # 12
                    "skin/select/SELECT id,name,body FROM skins WHERE id=?",
                    "media_file/select/SELECT * FROM media_files WHERE ((user_id=? OR conference_id=?) AND slideshow_pages>0)", # AND access permissions ...
# note, no need to exclude 1 or 2 letter words as the length is too short in any case ...
                    "conference/select/SELECT id FROM conferences WHERE uri=:uri UNION SELECT 0 FROM DUAL WHERE :uri IN (\
'login','logout','plugin','home','admin2548','admin_set_current_user2548','byid',\
'users',\
'blog','support','legal','contact','info','demos','faq','pricing','tour','wp-content','wp-admin','wp-includes',\
'sex','fuck','god',\
'') LIMIT 1",
                    ][Integer(params[:act])]
                model, cmd, sql = str.split('/',3)
            else
                model = params[:model]
            end
            klass = model.camelize.constantize if defined? params[:model]
        rescue
        end
        if not (klass.nil?)
            begin
                case cmd
                    when 'select'
                        sql_args = []
                        if (defined? params[:args] and not (params[:args].nil?))        # TODO need to research, this checking ...
                            sql_args = params[:args][:ah]
                        end
                        if not sql.nil? and defined? sql_args and not sql_args.nil?
                            query = nil
                            # OK, the following tested and works when sql_args is a: 1.list 2.single_element and 3.hash
                            if sql_args.kind_of?(Array)
                                query = [sql] + sql_args
                            else
                                query = [sql, sql_args]
                            end
                            result = klass.find_by_sql query
                        end
                    when 'insert'
                        raise "invalid authentication token" unless params[:auth]==form_authenticity_token
                        begin
                            klass.create(params[:args][:f])
                            result = [{:status => 'OK'}]
                        rescue
                            # TODO
                        end
                    when 'update'
                        raise "invalid authentication token" unless params[:auth]==form_authenticity_token
                        object = nil
                        object = klass.find_by_id(params[:args][:id])   # doesn't throw an exception
                        if not object.nil? 
                            begin
                                object.update_attributes(params[:args][:f])
                                result = [{:status => 'OK'}];
                            rescue
                                result = nil
                            end
                        end
                    when 'delete'
                        raise "invalid authentication token" unless params[:auth]==form_authenticity_token
                        object = nil
                        object = klass.find_by_id(params[:args][:id])   # doesn't throw an exception
                        if not object.nil? 
                            begin
                                #object.update_attributes(params[:args][:f])
                                object.destroy
                                result = [{:status => 'OK'}];
                            rescue
                                result = nil
                            end
                        end
                    when 'copy'
                        raise "invalid authentication token" unless params[:auth]==form_authenticity_token
                        old = nil
                        old = klass.find_by_id(params[:args][:id])   # doesn't throw an exception
                        if not old.nil?
                            object = old.clone
                            if not object.nil?
                                params[:args][:f].each{|key,value| object[key] = value}
                                if (object.save())
                                    result = [{:status => 'OK'}]
                                end
                            end
                        end
                    when 'sql'
                        raise "invalid authentication token" unless params[:auth]==form_authenticity_token
                        if not sql.nil?
                            begin
                                klass.find_by_sql sql
                                result = [{:status => 'OK'}]
                            rescue
                                result = [{:status => 'OK'}]
                            end;
                        end
                    else
                        result = nil
                end
            rescue
            end
        end
    end
    respond_to do |wants|
      wants.html    { render }
      wants.js      {
        if result.nil?
            render :json => [{:error => "error"}], :status => 500
        else
            render :json => result
        end
        }
    end
  end

end
