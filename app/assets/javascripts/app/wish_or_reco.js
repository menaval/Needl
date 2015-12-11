$(document).ready(function() {
  $('#wish').click(function () {
    $('.recommendation_ambiences, .recommendation_strengths, .recommendation_occasions, .recommendation_review').hide();
  });
  $('#reco').click(function () {
    $('.recommendation_ambiences, .recommendation_strengths, .recommendation_occasions, .recommendation_review').show();
  });

  // juste si on vient depuis la page d'un restaurant, enlève la classe border
  // var redirected = (window.location.search.charAt(0) === '?');
  // if (redirected) {
  //   $('.recommendation_wish, .recommendation_name').hide();
  //   $('.recommendation_ambiences .title').removeClass('border');
  // }
})