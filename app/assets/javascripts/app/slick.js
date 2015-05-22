$(document).ready(function(){
  $('.carousel').slick({
    arrows: true
  });
  $('.multiple-carousel').slick({
    infinite: true,
    slidesToShow: 3,
    slidesToScroll: 3,
    arrows: true
  });
  $('.slick-prev').addClass('pulse')
  $('.slick-next').addClass('pulse')
});

