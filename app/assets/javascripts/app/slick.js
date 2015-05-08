$(document).ready(function(){
  $('.caroussel').slick({
    arrows: true
  });
  $('.multiple-caroussel').slick({
    infinite: true,
    slidesToShow: 3,
    slidesToScroll: 3,
    arrows: true
  });
});

