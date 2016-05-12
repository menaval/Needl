$('#no_account').click(function() {
  $('#no_account').addClass('hidden');
  $('#already_account').removeClass('hidden');
  $('#signup').removeClass('hidden');
  $('#facebook-signup').removeClass('hidden');
  $('#login').addClass('hidden');
  $('#facebook-login').addClass('hidden');
  $('#title_login').addClass('hidden');
  $('#title_signup').removeClass('hidden');
});

$('#already_account').click(function() {
  $('#no_account').removeClass('hidden');
  $('#already_account').addClass('hidden');
  $('#signup').addClass('hidden');
  $('#facebook-signup').addClass('hidden');
  $('#login').removeClass('hidden');
  $('#facebook-login').removeClass('hidden');
  $('#title_login').removeClass('hidden');
  $('#title_signup').addClass('hidden');
});