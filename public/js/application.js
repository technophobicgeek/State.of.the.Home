(function() {
  $(function() {
    $(".task_list").sortable({
      delay: 300
    });
    $(".task_list").disableSelection();
    $("nav a").button();
  });
}).call(this);
