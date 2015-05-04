$(document).ready(function(){
  $('.caroussel').slick({
    arrows: false
  });
  $('.multiple-caroussel').slick({
    infinite: true,
    slidesToShow: 3,
    slidesToScroll: 3,
    arrows: false
  });
});

