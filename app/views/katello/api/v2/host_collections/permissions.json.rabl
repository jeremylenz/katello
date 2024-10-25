# collection @host_collections, :object_root => false
if ::Foreman::Cast.to_bool(params.fetch(:include_permissions, false))
  user = User.current # current_user is not available here
  node do
    node(:can_create) { user.can?("create_host_collections") }
    node(:can_edit) { user.can?("edit_host_collections") }
    node(:can_delete) { user.can?("destroy_host_collections") }
    node(:can_view) { user.can?("view_host_collections") }
  end
end
