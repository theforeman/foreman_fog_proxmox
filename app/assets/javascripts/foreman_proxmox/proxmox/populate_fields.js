function proxmoxPopulateNetworks(network_list){
    $('#host_compute_attributes_network_id').children().remove();
    for (var i = 0; i < network_list.length; i++) {
        result = results[i];
        $('#host_compute_attributes_network_id').append('<option id=' + result['id'] + '>' + result['name'] + '</option>');
    }
}

function proxmoxPopulateStorages(results){
    $('#host_compute_attributes_storages_id').children().remove();
    for (var i = 0; i < results.length; i++) {
        result = results[i];
        $('#host_compute_attributes_storages_id').append('<option id=' + result['id'] + '>' + result['name'] + '</option>');
    }
}

function proxmoxPopulateBuses(results){
    $('#host_compute_attributes_buses_id').children().remove();
    for (var i = 0; i < results.length; i++) {
        result = results[i];
        $('#host_compute_attributes_buses_id').append('<option id=' + result['id'] + '>' + result['name'] + '</option>');
    }
}

function proxmoxPopulateDevices(results){
    $('#host_compute_attributes_devices_id').children().remove();
    for (var i = 0; i < results.length; i++) {
        result = results[i];
        $('#host_compute_attributes_devices_id').append('<option id=' + result['id'] + '>' + result['name'] + '</option>');
    }
}

function proxmoxPopulateCaches(results){
    $('#host_compute_attributes_caches_id').children().remove();
    for (var i = 0; i < results.length; i++) {
        result = results[i];
        $('#host_compute_attributes_caches_id').append('<option id=' + result['id'] + '>' + result['name'] + '</option>');
    }
}
