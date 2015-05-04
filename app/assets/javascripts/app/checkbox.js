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