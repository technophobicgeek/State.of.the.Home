(function() {
  $(function() {
    $(".task_container").sortable();
    $(".task_container").disableSelection();
    $("nav a").button();
  });
}).call(this);
