function refreshCache(item, on_success) {
    tfm.tools.showSpinner();
    attribute_name = $(item).data('attribute')
    data = {
        type: attribute_name,
        compute_resource_id: $(item).data('compute-resource-id')
    }
    $.ajax({
            type:'post',
            url: $(item).data('url'),
            data: data,
            complete: function(){
                tfm.tools.hideSpinner();
            },
            error: function(){
                notify(__("Error refreshing cache for " + attribute_name), 'error', true);
            },
            success: on_success
        })
}
