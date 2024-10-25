if ::Foreman::Cast.to_bool(params.fetch(:include_permissions, false))
  user = User.current # current_user is not available here
  node do
    node(:can_create) { |resource| resource.creatable? }
    node(:can_edit) { |resource| resource.editable? }
    node(:can_delete) { |resource| resource.deletable? }
    node(:can_view) { |resource| resource.readable? }
  end
end