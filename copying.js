//ToolTip
$('.copy-step1-button').tooltip({
  trigger: 'click',
  placement: 'bottom'
});

function setTooltip(message) {
  $('.copied').tooltip('hide')
    .attr('data-original-title', message)
    .tooltip('show');
}

function hideTooltip() {
  setTimeout(function() {
    $('.copied').tooltip('hide');
  }, 5000);
}

// Clipboard
var clipboard = new ClipboardJS('.copy-button');

clipboard.on('success', function(e) {
  setTooltip('Copied!');
  hideTooltip();
  console.log(e);
});

clipboard.on('error', function(e) {
  console.log(e);
});
