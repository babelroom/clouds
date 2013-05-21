
# not actually a proper schema as the template parser won't recognize the top level keys
# we use it to generate json only

#$var=#val
#$ws=##my Super Website

{
fields: [
    {name:#_, type: #fieldset_on, desc: "Public or Private"},
    {name:#is_public, type: #boolean, default_value: true, desc: "Allow public access", title: {yes: "Everyone can find and enter the room", no: "Only designated invitees can find and enter the room"}},
    {name:#hide_details, type: #boolean, default_value: false, desc: "Hide conference name and introduction", title: {yes: "Conference name and introduction will be hidden", no: "Conferenece name and introduction will not be hidden"}, child_of:{name:#is_public, hide_on:true}},
    {name:#_, type: #fieldset_off},
    {name:#_, type: #fieldset_on, desc: "Authentication"},
    {name:#require_login, type: #boolean, default_value: false, desc: "Require participants be authenticated", title: {yes: "Participants must login to enter the room", no: "Unauthenticated participants will be assigned a temporary logic"}},
    {name:#require_nickname, type: #boolean, default_value: true, desc: "Require a nickname", title: {yes: "Unauthenticated participants must enter a nickname", no: "Unauthenticated participants will be assigned an anonymous name"}, child_of:{name:#require_login, hide_on:true}},
    {name:#is_locked, type: #boolean, default_value: false, desc: "Locked. Only allow hosts to enter room", title: {yes:"Only host can enter the room", no: "Everyone can enter the room"}},
    {name:#_, type: #fieldset_off},
    {name:#_, type: #fieldset_on, desc: "Miscellanious"},



# --- not so easy    {name:#mute_participants, type: #boolean, default_value: false, desc: "Mute participants on entry", title: {yes:"Non-hosts will be muted automatically on entry", no: "Non-hosts will not be automatically muted on entry"}},
# --- not so easy    {name:#participants_can_unmute, type: #boolean, default_value: true, desc: "Can participants unmute themselves", title: {yes: "Participants can unmute themselves", no: "Only hosts can unmute participants"}, child_of:{name:#mute_participants}},



    {name:#wait_for_host, type: #boolean, default_value: false, desc: "Participants must wait for host to start", title: {yes: "Participants must wait for host to enter conference", no: "Participants can enter conference without host"}},
#    {name:#example2, type: #boolean, disabled: true, default_value: false, desc: "She sells sea shells", title: {yes:"Yes", no: "No"}},
#    {name:#example3, type: #boolean, disabled: false, default_value: true, desc: "Don't enable this", title: {yes:"Ja", no: "Nein"}},
    {name:#_, type: #fieldset_off},
    {name:#_, type: #fieldset_on, desc: "Permissions"},
    {name:#participants_can_call, type: #boolean, default_value: false, desc: "All participants can make calls", title: {yes: "All participants can make calls", no: "Only hosts can make calls"}},
    {name:#_, type: #fieldset_off},
]}

