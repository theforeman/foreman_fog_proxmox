function cdromSelected(item) {
  var selected = $(item).val();
  var cdrom_image_form = $('#cdrom_image_form');

  switch (selected) {
    case 'none':
      cdrom_image_form.hide();
      break;
    case 'cdrom':
      cdrom_image_form.hide();
      break;
    case 'image':
      cdrom_image_form.show();
      break;
    default:
      break;
  }
  return false;
}
