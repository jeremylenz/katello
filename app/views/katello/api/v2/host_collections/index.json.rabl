object false

extends "katello/api/v2/common/metadata"
extends "katello/api/v2/host_collections/permissions"

child @collection[:results] => :results do
  extends "katello/api/v2/host_collections/base"
end
