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
  $('.search').on('click',function(){
    $this = $(this);
    $.ajax({
      url: '/cellar_files/' + $this.data().id + '/search',
      type: 'get',
      dataType: 'json',
      timespan:1000,
    }).done(function(data) {
      if (data.run == true) {
        $this.remove();
        $('.search-results').text('検索中')
      }
    }).fail(function(jqXHR, textStatus, errorThrown ) {
      $('.search-results').text('通信エラー')
    });

    return false
  });
});