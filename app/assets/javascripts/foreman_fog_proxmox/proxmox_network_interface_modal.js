$(document)
  .on('show.bs.modal', '#interfaceModal', function () {
    var modal = $(this);
    modal.toggleClass(
      'proxmox-interface-modal',
      modal.find('.proxmox-interface-form').length > 0
    );
  })
  .on('hidden.bs.modal', '#interfaceModal', function () {
    $(this).removeClass('proxmox-interface-modal');
  });
