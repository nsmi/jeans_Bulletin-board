
javascript:
  $(function() {

    $("#button").on("click", function(){
        var $newText = $("#text").val();
        $(".box1").append('<div class="e"><p class="a pp" ><img class="o t" src="' + $newText + '" width="760px" height="760px"></p></div>');
    
          });
    
    



    $(".box1").append('<div class="e"><p class="pp a" ><img class="t o" src =  width="760px" height="760px"></p></div>');

      $('.e').click(function() {
      var $answer = $(this).find('.o');
      var $kaki = $(this).find('.a');
      if($kaki.hasClass('pp')) {
        $kaki.removeClass('pp');
        $answer.removeClass('t');

      
    } else {
      $kaki.addClass('pp');
      $answer.addClass('t');


    }});



 



});