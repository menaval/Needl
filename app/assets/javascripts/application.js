//= require jquery
//= require jquery_ujs
//= require bootstrap-sprockets

//= require_tree ./app


// Please do not put any code in here. Create a new .js file in
// app/assets/javascripts/app instead, and put your code there

$(document).ready(function() {
  $("#form-reco .checkbox label").on("click", function(e) {
    var checkboxGroup = $(e.currentTarget).parents(".form-group.check_boxes");
    var max = parseInt(checkboxGroup.data("max"));
    var checkedCount = checkboxGroup.find("input[type=checkbox]:checked").length;

    if (checkedCount <= max) {
      return true;
    } else {
      return false;
    }
  });
})


