// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery_ujs
//= require twitter/bootstrap
//= require_tree .

$(function () {
  var flg = true;

  $('.search').on('click',function(){
    if (flg) {
      flg = false;

      var $this = $(this);
      var $search_results = $this.parent().prev();
      flg = true;

      $.ajax({
        url: '/cellar_files/' + $this.data().id + '/search',
        type: 'get',
        dataType: 'json',
        timespan:1000,
      }).done(function(data) {
        if (data.run == true) {
          $search_results.text('検索中');
          $this.remove();
        }
      }).fail(function(jqXHR, textStatus, errorThrown ) {
        $search_results.text('通信エラー')
      });
    }

    return false
  });
});