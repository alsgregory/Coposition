window.COPO = window.COPO || {};
window.COPO.permissions = {
  check_disabled: function(){
    $('[name=disallowed]').each(function(){
      if ($(this).children().prop('checked')){
        var permission_id = $(this).parents('div.permission').data().permission;
        element = $("div[data-permission='"+ permission_id +"']>.disable>label>input")
        element.prop("disabled", !element.prop("disabled"));
      }
    });
  },

  switch_change:function(){
    $(".switch").change(function( event ) {
      var permission_id = $(event.target).parents('div.permission').data().permission;
      var attribute = $(this).children().attr('class');
      var switch_type = $(this).children().attr('name');

      var new_state = null;
      gon.permissions.forEach(function(perm){
        if (perm.id === permission_id){
          new_state = perm[attribute] = COPO.permissions.new_state(perm[attribute], switch_type);
        }
      });

      if (switch_type === "disallowed") {
        $("div[data-permission='"+ permission_id +"']>.disable>.privilege>input").prop("checked", false);
        element = $("div[data-permission='"+ permission_id +"']>.disable>label>input")
        element.prop("disabled", !element.prop("disabled"));
      }

      var device_id = null;
      gon.permissions.forEach(function(perm){
        if (perm.id === permission_id){ device_id = perm.device_id; }
      });
      var data = COPO.permissions.set_data(attribute, new_state);
      $.ajax({
        url: "/users/"+gon.current_user_id+"/devices/"+device_id+"/permissions/"+permission_id+"",
        type: 'PUT',
        data: { permission : data }
      });
    })
  },

  new_state: function(current_state, switch_type){
    if(current_state === "disallowed"){
      return "complete"
    } else if(switch_type === "disallowed"){
      return "disallowed"
    } else if(current_state === "complete"){
      return "last_only"
    } else if(current_state === "last_only"){
      return "complete"
    } else {
      return !current_state
    }
  },

  set_data: function(attribute, value){
    if (attribute === 'privilege'){
      return { privilege: value };
    } else if (attribute === 'bypass_fogging'){
      return { bypass_fogging: value };
    } else {
      return { bypass_delay: value };
    }
  },
};
