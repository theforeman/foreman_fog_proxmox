function cdromSelected(item) {
  var selected = $(item).val();
  var cdrom_image_form = $('#cdrom_image_form');
  var cdrom_image_form = $('#cdrom_image_form');

  switch (selected) {
    case 'none':
      $('#host_compute_attributes_config_attributes_cdrom_iso').empty();
      cdrom_image_form.hide();
      break;
    case 'cdrom':
      $('#host_compute_attributes_config_attributes_cdrom_iso').empty();
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

  function storageIsoSelected(item) {
    tfm.tools.showSpinner();
    var storage = $(item).val();
    $.getJSON({
      type: 'get',
      url: '/foreman_proxmox/isos/'+storage,
      complete: function(){
        tfm.tools.hideSpinner();
      },
      error: function(j,status,error){
        console.log("Error=" + error +", status=" + status + " loading isos for storage=" + storage);
      },
      success: function(isos) {
        $('#host_compute_attributes_config_attributes_cdrom_iso').empty();
        console.log('isos='+isos);
        $.each(isos, function(i,iso){
          console.log('iso='+iso);
          $('#host_compute_attributes_config_attributes_cdrom_iso').append($("<option></option>").val(iso.volid).text(iso.volid));
        });
      }
    });
  }
