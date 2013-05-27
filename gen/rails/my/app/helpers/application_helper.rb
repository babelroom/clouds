# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def disable_accounts
    true
  end

#  def time_intervals
#    [
#      { :code => "", :time => "--" },
#      { :code => "0", :time => "12:00am" },
#      { :code => "15", :time => "12:15am" },
#      { :code => "30", :time => "12:30am" },
#      { :code => "45", :time => "12:45am" },
#      { :code => "100", :time => "1:00am" },
#      { :code => "115", :time => "1:15am" },
#      { :code => "130", :time => "1:30am" },
#      { :code => "145", :time => "1:45am" },
#      { :code => "200", :time => "2:00am" },
#      { :code => "215", :time => "2:15am" },
#      { :code => "230", :time => "2:30am" },
#      { :code => "245", :time => "2:45am" },
#      { :code => "300", :time => "3:00am" },
#      { :code => "315", :time => "3:15am" },
#      { :code => "330", :time => "3:30am" },
#      { :code => "345", :time => "3:45am" },
#      { :code => "400", :time => "4:00am" },
#      { :code => "415", :time => "4:15am" },
#      { :code => "430", :time => "4:30am" },
#      { :code => "445", :time => "4:45am" },
#      { :code => "500", :time => "5:00am" },
#      { :code => "515", :time => "5:15am" },
#      { :code => "530", :time => "5:30am" },
#      { :code => "545", :time => "5:45am" },
#      { :code => "600", :time => "6:00am" },
#      { :code => "615", :time => "6:15am" },
#      { :code => "630", :time => "6:30am" },
#      { :code => "645", :time => "6:45am" },
#      { :code => "700", :time => "7:00am" },
#      { :code => "715", :time => "7:15am" },
#      { :code => "730", :time => "7:30am" },
#      { :code => "745", :time => "7:45am" },
#      { :code => "800", :time => "8:00am" },
#      { :code => "815", :time => "8:15am" },
#      { :code => "830", :time => "8:30am" },
#      { :code => "845", :time => "8:45am" },
#      { :code => "900", :time => "9:00am" },
#      { :code => "915", :time => "9:15am" },
#      { :code => "930", :time => "9:30am" },
#      { :code => "945", :time => "9:45am" },
#      { :code => "1000", :time => "10:00am" },
#      { :code => "1015", :time => "10:15am" },
#      { :code => "1030", :time => "10:30am" },
#      { :code => "1045", :time => "10:45am" },
#      { :code => "1100", :time => "11:00am" },
#      { :code => "1115", :time => "11:15am" },
#      { :code => "1130", :time => "11:30am" },
#      { :code => "1145", :time => "11:45am" },
#      { :code => "1200", :time => "12:00pm" },
#      { :code => "1215", :time => "12:15pm" },
#      { :code => "1230", :time => "12:30pm" },
#      { :code => "1245", :time => "12:45pm" },
#      { :code => "1300", :time => "1:00pm" },
#      { :code => "1315", :time => "1:15pm" },
#      { :code => "1330", :time => "1:30pm" },
#      { :code => "1345", :time => "1:45pm" },
#      { :code => "1400", :time => "2:00pm" },
#      { :code => "1415", :time => "2:15pm" },
#      { :code => "1430", :time => "2:30pm" },
#      { :code => "1445", :time => "2:45pm" },
#      { :code => "1500", :time => "3:00pm" },
#      { :code => "1515", :time => "3:15pm" },
#      { :code => "1530", :time => "3:30pm" },
#      { :code => "1545", :time => "3:45pm" },
#      { :code => "1600", :time => "4:00pm" },
#      { :code => "1615", :time => "4:15pm" },
#      { :code => "1630", :time => "4:30pm" },
#      { :code => "1645", :time => "4:45pm" },
#      { :code => "1700", :time => "5:00pm" },
#      { :code => "1715", :time => "5:15pm" },
#      { :code => "1730", :time => "5:30pm" },
#      { :code => "1745", :time => "5:45pm" },
#      { :code => "1800", :time => "6:00pm" },
#      { :code => "1815", :time => "6:15pm" },
#      { :code => "1830", :time => "6:30pm" },
#      { :code => "1845", :time => "6:45pm" },
#      { :code => "1900", :time => "7:00pm" },
#      { :code => "1915", :time => "7:15pm" },
#      { :code => "1930", :time => "7:30pm" },
#      { :code => "1945", :time => "7:45pm" },
#      { :code => "2000", :time => "8:00pm" },
#      { :code => "2015", :time => "8:15pm" },
#      { :code => "2030", :time => "8:30pm" },
#      { :code => "2045", :time => "8:45pm" },
#      { :code => "2100", :time => "9:00pm" },
#      { :code => "2115", :time => "9:15pm" },
#      { :code => "2130", :time => "9:30pm" },
#      { :code => "2145", :time => "9:45pm" },
#      { :code => "2200", :time => "10:00pm" },
#      { :code => "2215", :time => "10:15pm" },
#      { :code => "2230", :time => "10:30pm" },
#      { :code => "2245", :time => "10:45pm" },
#      { :code => "2300", :time => "11:00pm" },
#      { :code => "2315", :time => "11:15pm" },
#      { :code => "2330", :time => "11:30pm" },
#      { :code => "2345", :time => "11:45pm" },
#    ]
#  end
#
#  def choice_list
#    [
##        { :table_field => '_', :code => '', :description => '' },
#        { :table_field => 'phones_phone_type', :code => '1', :description => 'Phone Number' },
#        { :table_field => 'phones_phone_type', :code => '2', :description => 'SIP URI' },
#        { :table_field => 'phones_phone_type', :code => '3', :description => 'Registered SIP' },
#        { :table_field => 'phones_phone_type', :code => '4', :description => 'IP Phone' },
#        { :table_field => 'phones_dial_options', :code => '3', :description => 'Both' },
#        { :table_field => 'phones_dial_options', :code => '2', :description => 'Auto-ID' },
#        { :table_field => 'phones_dial_options', :code => '1', :description => 'Call-Me' },
#        { :table_field => 'phones_dial_options', :code => '0', :description => 'None' },
#        { :table_field => 'phones_call_options', :code => '0', :description => 'Normal -- Other Callsping users dialing this number will ring only this phone' },
#        { :table_field => 'phones_call_options', :code => '1', :description => 'Enhanced -- Other Callspring users dialing this number will ring all my Call-Me phones' },
#        { :table_field => 'phones_sms_carrier', :code => '0', :description => 'Disabled -- click to select a carrier' },
#        { :table_field => 'phones_sms_carrier', :code => '1', :description => 'messaging.sprintpcs.com (Sprint)' },
#        { :table_field => 'phones_sms_carrier', :code => '2', :description => 'tmomail.net (T-Mobile)' },
#        { :table_field => 'phones_sms_carrier', :code => '3', :description => 'vtext.com (Verizon)' },
#        { :table_field => 'phones_sms_carrier', :code => '4', :description => 'txt.att.net (AT&T)' },
#        { :table_field => 'phones_sms_carrier', :code => '5', :description => 'Other' },
#        { :table_field => 'users_call_host', :code => '0', :description => 'Don\'t call me' },
#        { :table_field => 'users_call_host', :code => '1', :description => 'Call me 1 to 2 minutes before scheduled start time' },
#        { :table_field => 'users_call_non_host', :code => '0', :description => 'Don\'t call me' },
#        { :table_field => 'users_call_non_host', :code => '1', :description => 'Call me 1 to 2 minutes before scheduled start time' },
#        { :table_field => 'users_call_summary_dest', :code => '0', :description => 'my email address' },
##        { :table_field => 'users_call_summary_dest', :code => '1', :description => 'my email address plus this alternate' },
##        { :table_field => 'users_call_summary_dest', :code => '2', :description => 'only this alternate email address' },
#        { :table_field => 'users_call_summary_dest', :code => '3', :description => 'nobody (not recommended)' },
#        { :table_field => 'accounts_rec_notification', :code => '-1', :description => 'No Automatic Announcements' },
#        { :table_field => 'accounts_rec_notification', :code => '1', :description => 'Always Announce When Recording' },
#        { :table_field => 'accounts_rec_policy', :code => '-1', :description => 'Conference Organizer Decides' },
#        { :table_field => 'accounts_rec_policy', :code => '0', :description => 'Never Record Conferences' },
#        { :table_field => 'accounts_rec_policy', :code => '1', :description => 'Always Record Conferences' },
##        { :table_field => 'accounts_transcription_options', :code => '0', :description => 'Not Allowed' },
##        { :table_field => 'accounts_transcription_options', :code => '1', :description => 'Organizer can enable Scribble' },
##        { :table_field => 'accounts_transcription_options', :code => '2', :description => 'Organizer can enable Scribble or Scribe' },
#        { :table_field => 'accounts_suppress_charges_col', :code => '0', :description => 'No' },
#        { :table_field => 'accounts_suppress_charges_col', :code => '1', :description => 'Yes' },
#        { :table_field => 'conferences_who_can_invite', :code => '2', :description => 'Yes, all participants can invite others' },
#        { :table_field => 'conferences_who_can_invite', :code => '1', :description => 'People designated as hosts can invite others' },
#        { :table_field => 'conferences_who_can_invite', :code => '0', :description => 'No, only organizer can add/remove people' },
#        { :table_field => 'conferences_meeting_type', :code => '0', :description => 'Audio & WebShare' },
#        { :table_field => 'conferences_meeting_type', :code => '1', :description => 'WebShare Only' },
#        { :table_field => 'conferences_meeting_type', :code => '2', :description => 'Audio Only' },
#        { :table_field => 'conferences_play_chimes', :code => '0', :description => 'No' },
#        { :table_field => 'conferences_play_chimes', :code => '1', :description => 'Yes' },
#        { :table_field => 'conferences_announce_participants', :code => '1', :description => 'Yes, play names when arriving and leaving' },
#        { :table_field => 'conferences_announce_participants', :code => '0', :description => 'No, do not play names' },
#        { :table_field => 'conferences_announce_participants', :code => '2', :description => 'No, but record them for use in host functions' },
#        { :table_field => 'conferences_waiting_room', :code => '1', :description => 'No, conference starts without host' },
#        { :table_field => 'conferences_waiting_room', :code => '0', :description => 'Yes, until host arrives' },
#        { :table_field => 'conferences_waiting_room', :code => '2', :description => 'Yes, host must move participants into meeting' },
#        { :table_field => 'conferences_waiting_room', :code => '3', :description => 'Yes, only for those using a Conf. Code or duplicate identity' },
#
##<select id="host_exits" name="host_exits">
##	<option value="0">None; disconnect if host not present</option>
##	<option value="5">5 minutes</option>
##	<option value="10" selected="selected">10 minutes</option>
##	<option value="15">15 minutes</option>
##	<option value="30">30 minutes</option>
##	<option value="60">1 hour</option>
##	<option value="120">2 hours</option>
##	<option value="180">3 hours</option>
##	<option value="240">4 hours</option>
##</select>
#        { :table_field => 'conferences_initial_mute', :code => '0', :description => 'No, participants are not muted' },
#        { :table_field => 'conferences_initial_mute', :code => '2', :description => 'Yes, participants are "soft muted" and can unmute themselves with *6' },
#        { :table_field => 'conferences_initial_mute', :code => '1', :description => 'Yes, participants are "hard muted"; only a host can unmute' },
#        { :table_field => 'conferences_dashboard_access', :code => '2', :description => 'Normal: see status of all in Dashboard, control self' },
#        { :table_field => 'conferences_dashboard_access', :code => '1', :description => 'Limited: see Hosts; control self (no roll call or room changes)' },
#        { :table_field => 'conferences_dashboard_access', :code => '0', :description => 'None: no access to Dashboard' },
#        { :table_field => 'conferences_host_advance_start', :code => '0', :description => 'No advance' },
#        { :table_field => 'conferences_host_advance_start', :code => '5', :description => '5 minutes' },
#        { :table_field => 'conferences_host_advance_start', :code => '10', :description => '10 minutes' },
#        { :table_field => 'conferences_host_advance_start', :code => '15', :description => '15 minutes' },
#        { :table_field => 'conferences_host_advance_start', :code => '20', :description => '20 minutes' },
#        { :table_field => 'conferences_host_advance_start', :code => '25', :description => '25 minutes' },
#        { :table_field => 'conferences_host_advance_start', :code => '30', :description => '30 minutes' },
#        { :table_field => 'conferences_host_advance_start', :code => '35', :description => '35 minutes' },
#        { :table_field => 'conferences_host_advance_start', :code => '40', :description => '40 minutes' },
#        { :table_field => 'conferences_host_advance_start', :code => '45', :description => '45 minutes' },
#        { :table_field => 'conferences_host_advance_start', :code => '50', :description => '50 minutes' },
#        { :table_field => 'conferences_host_advance_start', :code => '55', :description => '55 minutes' },
#        { :table_field => 'conferences_host_advance_start', :code => '60', :description => '1 hour' },
#        { :table_field => 'conferences_record', :code => '0', :description => 'No' },
#        { :table_field => 'conferences_record', :code => '1', :description => 'Yes' },
#        { :table_field => 'conferences_transcription', :code => '0', :description => 'No' },
#        { :table_field => 'conferences_transcription', :code => '1', :description => 'Yes, with Scribble (extra charge $)' },
#        { :table_field => 'conferences_transcription', :code => '2', :description => 'Yes, with Scribe (extra charge $$$)' },
#        { :table_field => 'conferences_transcription_access', :code => '0', :description => 'Only the Organizer' },
#        { :table_field => 'conferences_transcription_access', :code => '1', :description => 'Conference Participants' },
#        { :table_field => 'conferences_transcription_access', :code => '2', :description => 'Anybody (with the link)' },
#        { :table_field => 'conferences_schedule', :code => '', :description => '- Draft -' },
#        { :table_field => 'conferences_schedule', :code => 's', :description => 'Standing' },
#        { :table_field => 'conferences_schedule', :code => 'o', :description => 'Once only' },
#        { :table_field => 'conferences_schedule', :code => 'e', :description => 'Every Day' },
##        { :table_field => 'conferences_schedule', :code => 'd', :description => 'Every Weekday' }, -- not currently supported in netops TODO
#        { :table_field => 'conferences_schedule', :code => 'w', :description => 'Weekly' },
#        { :table_field => 'conferences_schedule', :code => 'b', :description => 'Bi-weekly' },
#        { :table_field => 'conferences_schedule', :code => 'm', :description => 'Monthly' },
#        { :table_field => 'conferences_schedule', :code => 'q', :description => 'Quarterly' },
#    ]
#  end

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

