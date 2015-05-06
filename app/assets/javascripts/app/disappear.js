$(document).ready(function() {
  $(".friends-show").on("click", function() {
    var id = $(this).attr('id');
    var array = id.split('-');
    $('#' + array[0] + '-friends-' + array[1]).toggleClass("hidden-friend");
    $(this).find('.arrow-desc').toggleClass('fa fa-sort-asc fa fa-sort-desc');
  });
})