# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def disable_accounts
    true
  end

  def choice_map(model, field, value)
    table_field = model.pluralize.to_s + '_' + field.to_s
    choice_list.each do |choice|
      if choice[:table_field].eql? table_field and choice[:code].eql? value
        return choice[:description]
      end
    end
    return '--'
  end

  def time_stamp
    Time.zone.now.strftime("%b %d, %I:%M%P").sub(/\s0/,' ')
  end

  def br_unescape(text)
    text.gsub(/\"/, '\"')
  end

  def pretty_time(dt)
    return if dt.nil?
    dt.strftime("%I:%M%P").sub(/\s0/, ' ')
  end

  def pretty_datetime(dt)
    return if dt.nil?
    str = ''
    if Time.zone.now.year!=dt.year
      str += dt.strftime("%b %d, %Y @")
    elsif Time.zone.now.yday!=dt.yday
      str += dt.strftime("%b %d @")
    end
    str += dt.strftime(" %I:%M%P")
    str.sub(/\s0/, ' ')
  end

  def br_server_name
    server_name = request.env['HTTP_X_FORWARDED_SERVER']                    # apache
    server_name = request.env['HTTP_HOST'] if server_name.nil?              # nginx
    server_name = request.env['SERVER_NAME'] if server_name.nil?            # mongrel? / nginx
    server_name
  end

  def google_tracker_js
return # disable tracker
    return $global_tracker_js if defined? $global_tracker_js
    server_name = br_server_name()
    key = 'UA-22860960-' + 
        case server_name
        when 'x.y.z'; '1'
        else; '3'
        end
            
#  _gaq.push(['_setDomainName', '.babelroom.com']); // -- this normalizes subdomains back to the same domain profile
    $global_tracker_js = <<__EOT__
<script type="text/javascript">
  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', '#{key}']); // #{server_name}
  _gaq.push(['_trackPageview']);
  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();
</script>
__EOT__
  end

  def supporttab_js_bad
    widget = <<__EOT__
<script type="text/javascript" charset="utf-8">
  var is_ssl = ("https:" == document.location.protocol);
  var asset_host = is_ssl ? "https://s3.amazonaws.com/getsatisfaction.com/" : "http://s3.amazonaws.com/getsatisfaction.com/";
  document.write(unescape("%3Cscript src='" + asset_host + "javascripts/feedback-v2.js' type='text/javascript'%3E%3C/script%3E"));
</script>
<script type="text/javascript" charset="utf-8">
  var feedback_widget_options = {};
  feedback_widget_options.display = "overlay";  
  feedback_widget_options.company = "babelroom";
  feedback_widget_options.placement = "right";
  feedback_widget_options.color = "#282828";
  feedback_widget_options.style = "question";
  var feedback_widget = new GSFN.feedback_widget(feedback_widget_options);
</script>
__EOT__
  end

  def supporttab_js(options = {})
return # disable support tab
    uname = umail = 'null'
    if defined?(current_user) && current_user.signed_up?
        umail = '"' + current_user.email + '"' if current_user.email.present?
        uname = '"' + current_user.full_name + '"'
    end
    js_options = ''
    options.each do |key,value|
        js_options += "\t#{key}: \"#{value}\",\n"
    end
    widget = <<__EOT__
<script type="text/javascript" src="//assets.zendesk.com/external/zenbox/v2.5/zenbox.js"></script>
<style type="text/css" media="screen, projection">
  @import url(//assets.zendesk.com/external/zenbox/v2.5/zenbox.css);
</style>
<script type="text/javascript">
  if (typeof(Zenbox) !== "undefined") {
    Zenbox.init({
      dropboxID:   "000000",
      url:         "https://babelroom.zendesk.com",
      tabID:       "support",
      tabColor:    "#282828",
      tabPosition: "Right",
#{js_options} requester_name:   #{uname},
      requester_email:  #{umail},
      requester_subject:"Babelroom feedback"
    });
  }
</script>
__EOT__
  end

  def release_version
    '1090'
  end

  def br_environment_stamp
    if not $babelroom_environment.eql?''
      '[' + $babelroom_environment + ': ' + release_version + ']&nbsp;&nbsp;&nbsp;'
    end
  end

  def cstr(str)
    escape_javascript(str)
  end
  def jstr(str)
    ("'" + cstr(str) + "'")
  end
  def qstr(str)
    ('"' + (str.present? ? str.to_s : '') + '"')
  end
end

