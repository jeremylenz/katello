module Katello
  module Util
    class DefaultEnablementMigratorTest < ActiveSupport::TestCase
      def setup
        @migrator = Katello::Util::DefaultEnablementMigrator.new
      end

      def test_execute!
        @migrator.expects(:create_disabled_overrides_for_non_sca_org_hosts)
        @migrator.expects(:create_disabled_overrides_for_non_sca_org_activation_keys)
        @migrator.expects(:create_activation_key_overrides)
        @migrator.expects(:create_consumer_overrides)
        @migrator.expects(:update_enablement_in_candlepin)
        @migrator.expects(:update_enablement_in_katello)
        Rails.logger.expects(:info).with("Finished updating custom products enablement; no errors")
        @migrator.execute!
      end

      def test_execute_with_errors
        @migrator.expects(:create_disabled_overrides_for_non_sca_org_hosts).returns(1)
        @migrator.expects(:create_disabled_overrides_for_non_sca_org_activation_keys).returns(2)
        @migrator.expects(:create_activation_key_overrides).returns(3)
        @migrator.expects(:create_consumer_overrides).returns(4)
        @migrator.expects(:update_enablement_in_candlepin).returns(5)
        @migrator.expects(:update_enablement_in_katello).returns(6)
        Rails.logger.expects(:info).with("Finished updating custom products enablement; 21 errors")
        Rails.logger.expects(:info).with("1 error updating disabled overrides for unsubscribed content; see log messages above")
        Rails.logger.expects(:info).with("2 errors updating disabled overrides for unsubscribed content in activation keys; see log messages above")
        Rails.logger.expects(:info).with("3 errors updating activation key overrides; see log messages above")
        Rails.logger.expects(:info).with("4 errors updating consumer overrides; see log messages above")
        Rails.logger.expects(:info).with("5 errors updating default enablement in Candlepin; see log messages above")
        Rails.logger.expects(:info).with("6 errors updating default enablement in Katello; see log messages above")
        @migrator.execute!
      end
  end