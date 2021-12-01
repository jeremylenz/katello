class AddUniqueIndexes < ActiveRecord::Migration[6.0]
  include ActionView::Helpers::TextHelper
  def up
    clean_unindexed_tables
    add_index :katello_capsule_lifecycle_environments, [:capsule_id, :lifecycle_environment_id], unique: true, name: 'katello_capsule_lifecycle_environments_unique_index'
    add_index :katello_content_view_erratum_filter_rules, [:errata_id, :content_view_filter_id], unique: true, name: 'katello_content_view_erratum_filter_rules_unique_index'
    add_index :katello_content_view_module_stream_filter_rules, [:module_stream_id, :content_view_filter_id], unique: true, name: 'katello_content_view_module_stream_filter_rules_unique_index'
    add_index :katello_content_view_package_group_filter_rules, [:uuid, :content_view_filter_id], unique: true, name: 'katello_content_view_package_group_filter_rules_unique_index'
    add_index :katello_content_view_repositories, [:content_view_id, :repository_id], unique: true, name: 'katello_content_view_repositories_unique_index'
    add_index :katello_content_views, [:name, :organization_id], unique: true, name: 'katello_content_views_name_unique_index'
  end

  def down
    remove_index :katello_capsule_lifecycle_environments, name: 'katello_capsule_lifecycle_environments_unique_index'
    remove_index :katello_content_view_erratum_filter_rules, name: 'katello_content_view_erratum_filter_rules_unique_index'
    remove_index :katello_content_view_module_stream_filter_rules, name: 'katello_content_view_module_stream_filter_rules_unique_index'
    remove_index :katello_content_view_package_group_filter_rules, name: 'katello_content_view_package_group_filter_rules_unique_index'
    remove_index :katello_content_view_repositories, name: 'katello_content_view_repositories_unique_index'
    remove_index :katello_content_views, name: 'katello_content_views_name_unique_index'
  end

  def clean_unindexed_tables
    models_to_clean = [
      {
        :model => ::Katello::CapsuleLifecycleEnvironment,
        :fields => [:lifecycle_environment_id, :capsule_id]
      },
      {
        :model => ::Katello::ContentViewErratumFilterRule,
        :fields => [:errata_id, :content_view_filter_id]
      },
      {
        :model => ::Katello::ContentViewModuleStreamFilterRule,
        :fields => [:module_stream_id, :content_view_filter_id]
      },
      {
        :model => ::Katello::ContentViewPackageGroupFilterRule,
        :fields => [:uuid, :content_view_filter_id]
      },
      {
        :model =>
        ::Katello::ContentViewRepository,
        :fields => [:content_view_id, :repository_id]
      }
    ]
    # example ---- (IDs 1/7 and 6/8 are duplicates ) ::Katello::CapsuleLifecycleEnvironment.all
    # => [#<Katello::CapsuleLifecycleEnvironment:0x0000000017e11060 id: 1, capsule_id: 1, lifecycle_environment_id: 1>,
    # #<Katello::CapsuleLifecycleEnvironment:0x0000000017e10f98 id: 2, capsule_id: 1, lifecycle_environment_id: 2>,
    # #<Katello::CapsuleLifecycleEnvironment:0x0000000017e10ed0 id: 3, capsule_id: 1, lifecycle_environment_id: 3>,
    # ...
    # #<Katello::CapsuleLifecycleEnvironment:0x0000000017e10c78 id: 6, capsule_id: 1, lifecycle_environment_id: 6>,
    # #<Katello::CapsuleLifecycleEnvironment:0x0000000017e10bb0 id: 7, capsule_id: 1, lifecycle_environment_id: 1>,
    # #<Katello::CapsuleLifecycleEnvironment:0x0000000017e10ac0 id: 8, capsule_id: 1, lifecycle_environment_id: 6>]

    models_to_clean.each do |model_to_clean|
      rows_deleted = 0
      model = model_to_clean[:model]
      cleaning_queries(model_to_clean).each { |query| rows_deleted += clean_duplicates(query, model) }
      if rows_deleted > 0
        Rails.logger.info("Deleted #{pluralize(rows_deleted, 'duplicate table row')} from #{model.table_name}")
      end
    end
    Rails.logger.info("Finished cleaning duplicate table rows")

    models_to_rename = [
      {
        :model => ::Katello::ContentView,
        :fields => [:name, :organization_id]
      }
    ]
    models_to_rename.each do |model_to_rename|
      rows_renamed = 0
      model = model_to_rename[:model]
      cleaning_queries(model_to_rename).each { |query| rows_renamed += rename_duplicates(query, model) }
      if rows_renamed > 0
        Rails.logger.info("Renamed #{pluralize(rows_renamed, 'duplicate table row')} from #{model.table_name}")
      end
    end
    Rails.logger.info("Finished renaming duplicate table rows")
  end

  def cleaning_queries(model_to_clean)
    model = model_to_clean[:model]
    fields = model_to_clean[:fields]
    dup_query = model.group(fields).having("count(*) > 1")
    duplicate_entries = dup_query.count.keys #  [[1, 1], [6, 1]] - the set of duplicate combinations
    return [] if duplicate_entries.blank?
    min_ids = dup_query&.pluck('min(id)') # [1, 6] - the ids of the duplicate entries with the lowest id, in the same order as duplicate_entries
    duplicate_entries.map.with_index do |entry, idx|
      # [{:lifecycle_environment_id=>1, :capsule_id=>1, :min_id=>1},
      # {:lifecycle_environment_id=>6, :capsule_id=>1, :min_id=>6}]
      Hash[fields.zip(entry)].merge({ min_id: min_ids[idx] })
    end
  end

  def clean_duplicates(query, model)
    min_id = query.delete(:min_id)
    model.where(query).where.not(id: min_id).delete_all # returns quantity deleted
  end

  def rename_duplicates(query, model)
    min_id = query.delete(:min_id)
    counter = 0
    model.where(query).where.not(id: min_id).each do |duplicate|
      counter += 1
      old_name = duplicate.name
      new_name = "#{duplicate.name}_#{duplicate.id}"
      duplicate.name = new_name
      duplicate.save(validate: false) # skip validation since migrations should never fail
      Rails.logger.info("Content view #{old_name} (id #{duplicate.id}) renamed to #{new_name}")
    end
    counter
  end
end
