$(document).ready(function() {
  $(".friends-show").on("click", function() {
    var id = $(this).attr('id');
    var array = id.split('-');
    $('#' + array[0] + '-friends-' + array[1]).toggleClass("hidden-friend");
  });
})