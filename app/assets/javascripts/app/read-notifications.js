$(document).ready(function(e){
  $("#activities-notif").on("click", function() {
   e.preventDefault()
   $.ajax({
      type: "post"
      url: '/recommendations_controller/read_all_notification'
      dataType: "json"
      beforeSend: (xhr) ->
      xhr.setRequestHeader "X-CSRF-Token", $("meta[name=\"csrf-token\"]").attr("content")
      cache: false
    });
  });
})