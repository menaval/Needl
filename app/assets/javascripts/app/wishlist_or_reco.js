$(document).ready(function() {
  $('#wishlist').click(function () {
    $('.recommendation_ambiences, .recommendation_strengths, .recommendation_price_ranges, .recommendation_review').hide();
  });
  $('#reco').click(function () {
    $('.recommendation_ambiences, .recommendation_strengths, .recommendation_price_ranges, .recommendation_review').show();
  });

  // juste si on vient depuis la page d'un restaurant, enlève la classe border
  // var redirected = (window.location.search.charAt(0) === '?');
  // if (redirected) {
  //   $('.recommendation_wishlist, .recommendation_name').hide();
  //   $('.recommendation_ambiences .title').removeClass('border');
  // }
})