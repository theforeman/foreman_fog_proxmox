function cdromSelected(item) {
  var selected = $(item).val();
  var cdrom_image_form = $('#cdrom_image_form');

  switch (selected) {
    case 'none':
      initStorage();
      initOptions('iso');
      cdrom_image_form.hide();
      break;
    case 'cdrom':
      initStorage();
      initOptions('iso');
      cdrom_image_form.hide();
      break;
    case 'image':
      initStorage();
      initOptions('iso');
      cdrom_image_form.show();
      break;
    default:
      break;
  }
  return false;
}

function initStorage(){
  var select = '#host_compute_attributes_config_attributes_cdrom_storage';
  $(select + ' option:selected').prop('selected',false);
  $(select).val('');
}

function initOptions(name){
  var select = '#host_compute_attributes_config_attributes_cdrom_'+name;
  $(select).empty();
  $(select).append($("<option></option>").val('').text(''));
  $(select).val('');
}

  function storageIsoSelected(item) {
    var storage = $(item).val();
    if (storage != '') {
      tfm.tools.showSpinner();
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
          initOptions('iso');
          $.each(isos, function(i,iso){
            $('#host_compute_attributes_config_attributes_cdrom_iso').append($("<option></option>").val(iso.volid).text(iso.volid));
          });
        }
      });
    } else {
      initOptions('iso');
    }
  }

function controllerSelected(item){
  var controller = $(item).val();
  var id = $(item).attr('id');
  var pattern = /(\w+)(\d+)(\w+)/i;
  var index =  pattern.exec(id)[2];
  var max = computeControllerMaxDevice(controller);
  $('#host_compute_attributes_volumes_attributes_' + index + '_device').attr('data-soft-max',max);
  tfm.numFields.initAll();
}

function computeControllerMaxDevice(controller){
  switch (controller) {
    case 'ide':
      return 3;
      break;
    case 'sata':
      return 5;
      break;
    case 'scsi':
      return 13;
      break;
    case 'virtio':
      return 15;
      break;
    default:
      return 1;
      break;
  }
}

function imageProxmoxSelected(item) {
  var volid = $(item).val();
  console.log('volid='+volid);
  disableProxmoxConfig();
}

function disableProxmoxConfig(){
  var ids = ['config_options','memory','cpu','cdrom','config_os']
  for (i=0;i< ids.length;i++){
    $(id[i]).disabled();
    $(id[i]).hide();
  }
}
