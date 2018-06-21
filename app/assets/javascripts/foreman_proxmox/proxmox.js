import $ from 'jquery';
import { showSpinner } from '../foreman_tools';

export function cdromSelected(item) {
  const selected = $(item).val();
  const cdrom_image = $(item).parentsUntil('.fields').parent().find('#cdrom_image');

  switch (selected) {
    case 'none':
      cdrom_image.hide();
      break;
    case 'physical':
      cdrom_image.hide();
      break;
    case 'image':
      cdrom_image.show();
      break;
    default:
      break;
  }
  return false;
}
