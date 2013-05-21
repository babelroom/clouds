var BRDynamic = {

    populateHTML: function(id, json_options) {
        var html = '';
        var tree = {};
        var map = {};
        jQuery.each(json_options.fields, function(idx,f){
            var d = {};
            switch(f.type) {
                case 'boolean':
                    var cls = f['class'] || 'br-dyn'
                        , fid=id+f.name
                        , yes_title = f.title && f.title.yes && 'title="'+f.title.yes+'" ' || ''
                        , no_title = f.title && f.title.no && 'title="'+f.title.no+'" ' || ''
                        , indent = f.child_of ? '&#x2514;&#x2500;&#x2500; ' : ''
                        ;
                    html += '\
<tr id="'+fid+'_row" class="'+cls+'"><td class="'+cls+'">'+indent+f.desc+'</td><td class="'+cls+'"><div id="'+fid+'">\
<input type="radio" name="'+f.name+'" id="'+fid+'_yes" value="true" disabled /><label '+yes_title+'for="'+fid+'_yes">Yes</label>\
<input type="radio" name="'+f.name+'" id="'+fid+'_no" value="false" disabled /><label '+no_title+'for="'+fid+'_no">No</label>\
</div></td></tr>\
';
                    d = {id: fid, widget: 'buttonset'/*, opts: {disabled: true} -- this doesn't work */
                        ,   set: function(val){ jQuery('#'+this.id+(val?'_yes':'_no')).prop('checked',true).button('refresh').change();}
                        ,   get: function(){ return jQuery('#'+this.id+'_yes').is(':checked'); }
                        ,   enable: function(val){ jQuery('#'+this.id).buttonset(val?"enable":"disable"); }
                        ,   show: function(val) { if(val) jQuery('#'+this.id+'_row').show(); else jQuery('#'+this.id+'_row').hide(); }
                        };
                    break;
                case 'fieldset_on': html += '<fieldset class="ui-widget ui-widget-content br-dyn">\
<legend class="ui-widget-header ui-corner-all br-dyn">'+f.desc+'</legend><table class="br-dyn">';
                    break;
                case 'fieldset_off': html += '</table></fieldset>'; break;
                }
            tree[idx] = {dom: d, field: f};
            map[f.name] = tree[idx];
            /* returning false with early abort the iteration -- http://api.jquery.com/jQuery.each/ */
            });
        //return {html: '<table width="100%">'+html+'</table>', tree: tree, map: map};
        return {html: html, tree: tree, map: map};
    },

    addLogic: function(tree) {
        jQuery.each(tree.tree, function(idx,t){
            if (!t.dom.id) return true;
            var obj = jQuery('#'+t.dom.id),
                widget = t.dom.widget;
            var w=obj[widget].call(obj, t.dom.opts).change(function(){
                t.new_value = t.dom.get();
                });
            if (t.field.child_of) {
                var pdom = tree.map[t.field.child_of.name].dom
                    , psel = '#'+pdom.id
                    , pobj = jQuery(psel)
                    , pwidget = pdom.widget
                    ;
                pobj[pwidget].call(pobj).change(function(){
                    t.dom.show((!!t.field.child_of.hide_on)!==(!!pdom.get()));
                    });
                }
            //t.field.parent_yes
            t.dom.enable(false);
            /* returning false will early abort the iteration -- http://api.jquery.com/jQuery.each/ */
            });
    },

    modified: function(tree) {
        var t = tree.tree;
        for(var i in t)
            if (t.hasOwnProperty(i))
                if (typeof(t[i].new_value)!=="undefined" && t[i].new_value!==t[i].orig_value)
                    return true;
        return false;
    },

/*
    clearModified: function (tree) {
        jQuery.each(tree.tree, function(idx,t){
            delete t.new_value;
            });
    },
*/

    set /* or reset */: function(tree, values) {
        jQuery.each(tree.tree, function(idx,t){
            if (!t.dom.id) return true;
            delete t.new_value;
            var disabled = t.field.disabled;
            if (typeof(values[t.field.name])!=="undefined")
                t.dom.set(t.orig_value=values[t.field.name]);
            else if (typeof(t.field.default_value)!=="undefined") {
                t.dom.set(t.orig_value=t.field.default_value);
/*                if (!disabled) -- no I think be more strict here, only see a change if we've actively made one, we can always update the fields en mass
                    t.new_value = t.field.default_value; */
                }
            if (!disabled)
                t.dom.enable(true);
            /* returning false with early abort the iteration -- http://api.jquery.com/jQuery.each/ */
            });
    },

    get: function(tree) {
        var changed = {};
        jQuery.each(tree.tree, function(idx,t){
            if (typeof(t.new_value)!=="undefined" && t.new_value!==t.orig_value)
                changed[t.field.name] = t.new_value;
            /* returning false with early abort the iteration -- http://api.jquery.com/jQuery.each/ */
            });
//console.log('changed',changed);
        return changed;
    },

    readDefaults: function(json_options) {
        var defaults = {};
        jQuery.each(json_options.fields, function(idx,f){
            if (typeof(f.default_value)!=="undefined")
                defaults[f.name] = f.default_value;
            });
        return defaults;
    },

    readOptions: function(json_string_or_null, json_options_defaults) {
        var json = null;
        try { json = (json_string_or_null && JSON.parse(json_string_or_null)) || {}; }
        catch(e) {};
        return jQuery.extend({}, BRDynamic.readDefaults(json_options_defaults), json);
    }
};

