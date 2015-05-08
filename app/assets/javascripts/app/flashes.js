$(document).ready(function() {
  if ($('.alert').length > 0) {
    $(function() {
      setTimeout(function(){
        $('.alert').fadeOut(800);
      }, 4000);
    });
  ;}
});