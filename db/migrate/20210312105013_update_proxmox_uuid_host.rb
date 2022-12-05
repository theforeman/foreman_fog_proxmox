include ProxmoxVmUuidHelper
class UpdateProxmoxUuidHost < ActiveRecord::Migration[6.0]
  def up
    execute(sql(:concat))
  end

  def down
    execute(sql(:substring))
  end

  private

  def concat
    "concat(h.compute_resource_id, '_', h.uuid) "
  end

  def substring
    "substring(h.uuid, position('_' in h.uuid) + 1, length(h.uuid)) "
  end

  def sql(func_type)
    sql = 'update hosts h set uuid = '
    sql += send(func_type)
    sql += 'from compute_resources cr '
    sql += "where cr.id = h.compute_resource_id and cr.type = 'ForemanFogProxmox::Proxmox';"
    sql
  end
end
