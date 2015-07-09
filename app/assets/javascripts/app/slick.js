$(document).ready(function(){
  $('.carousel').slick({
    arrows: false,
  });
  $('.multiple-carousel').slick({
    infinite: true,
    slidesToShow: 3,
    slidesToScroll: 3,
    arrows: false,
    centerPadding: true,
    mobileFirst: true,
    centerMode: true
  });
   $('.slider-for').slick({
    slidesToShow: 1,
    slidesToScroll: 1,
    arrows: false,
    fade: true,
    asNavFor: '.slider-nav'
  });
  $('.slider-nav').slick({
    slidesToShow: 3,
    slidesToScroll: 1,
    asNavFor: '.slider-for',
    centerMode: true,
    focusOnSelect: true,
    centerPadding: true,
    mobileFirst: true,
    arrows: false,
  });
});

