$(document).ready(function(){
  $('.carousel').slick({
    arrows: true,
    dots: true,
  });
  $('.multiple-carousel').slick({
    infinite: true,
    slidesToShow: 3,
    slidesToScroll: 3,
    arrows: true
  });
});

