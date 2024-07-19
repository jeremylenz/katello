module Katello
  module Concerns
    module Api::V2::HostsControllerExtensions
      extend ActiveSupport::Concern
      include ForemanTasks::Triggers

      module Overrides
        def action_permission
          case params[:action]
          when 'host_collections'
            'edit'
          else
            super
          end
        end
      end

      included do
        prepend Overrides
        before_action :purpose_addon_params, only: [:create, :update]
        before_action :set_content_view_environments, only: [:create, :update]

        def destroy
          Katello::RegistrationManager.unregister_host(@host, :unregistering => false)
          process_response(:object => @host)
        end

        api :PUT, "/hosts/:host_id/host_collections", N_("Alter a host's host collections")
        param :host_id, :number, :required => true, :desc => N_("The id of the host to alter")
        param :host_collection_ids, Array, :required => true, :desc => N_("List of host collection ids to update")
        def host_collections
          @host.host_collection_ids = params[:host_collection_ids]
          @host.save!
          render(:locals => { :resource => @host }, :template => 'katello/api/v2/hosts/show', :status => :ok)
        end

        def purpose_addon_params
          addons = params.dig(:host, :subscription_facet_attributes, :purpose_addons)
          return if addons.nil?
          params[:host][:subscription_facet_attributes][:purpose_addon_ids] = addons.map { |addon_name| ::Katello::PurposeAddon.find_or_create_by(name: addon_name).id }
          params[:host][:subscription_facet_attributes].delete(:purpose_addons)
        end

        def set_content_view_environments
          return if @host.content_facet.blank? || 
            (cve_params[:content_view_id].present? && cve_params[:lifecycle_environment_id].present?)
          new_cve_ids = nil
          if cve_params[:environments].present? && cve_params[:content_view_environment_ids].blank?
            environment_names = cve_params[:environments].split(',').map(&:strip)
            Rails.logger.debug "new environment names: #{environment_names}"
            new_cve_ids = environment_names.map do |name|
              ::Katello::ContentViewEnvironment.with_candlepin_name(name, organization: @host.organization)&.id
            end
          end
          if cve_params[:content_view_environment_ids].present?
            new_cve_ids = ::Katello::ContentViewEnvironment.where(id: cve_params[:content_view_environment_ids]).ids
          end

          @host.content_facet.content_view_environment_ids = new_cve_ids.compact if new_cve_ids.present?
        end

        def cve_params
          params.require(:host).require(:content_facet_attributes).permit(:content_view_id, :lifecycle_environment_id, :environments, content_view_environment_ids: [])
        end
      end
    end
  end
end
