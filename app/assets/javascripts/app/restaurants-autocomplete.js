$(document).ready(function(){
  if ($('.restaurants-autocomplete').length) {
    var input = $('.restaurants-autocomplete');

    var restaurants = new Bloodhound({
      datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
      queryTokenizer: Bloodhound.tokenizers.whitespace,
      remote: {
        url: $(input).data("url") + '.json?query=%QUERY',
        wildcard: '%QUERY'
      }
    });

    $('.restaurants-autocomplete').typeahead(null, {
      name: 'best-pictures',
      display: 'name',
      minLength: 3,
      source: restaurants
    }).on('typeahead:selected', function($e, restaurant) {
      $(".restaurants-autocomplete--id").val(restaurant.id);
      $(".restaurants-autocomplete--origin").val(restaurant.origin);
    });
  }
});