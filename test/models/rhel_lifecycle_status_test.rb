require 'katello_test_helper'

module Katello
  class RhelLifecycleStatusTest < ActiveSupport::TestCase
    let(:host) do
      FactoryBot.create(:host, :with_content, :content_view => katello_content_views(:library_dev_view),
                         :lifecycle_environment => katello_environments(:library))
    end

    let(:os) do
      Operatingsystem.create!(:name => "RedHat", :major => "7", :minor => "3")
    end

    let(:status) { host.get_status(Katello::RhelLifecycleStatus) }

    let(:release) { 'RHEL9' }

    def test_get_status
      assert host.get_status(Katello::RhelLifecycleStatus)
    end

    def test_eos_schedule_constants
      eos_schedule_data = Katello::RhelLifecycleStatus::RHEL_EOS_SCHEDULE_INDEXES
      assert eos_schedule_data.is_a?(Hash)
      [
        'RHEL6',
        'RHEL7',
        'RHEL8',
        'RHEL9',
        'RHEL7 (System z (Structure A))',
        'RHEL7 (ARM)',
        'RHEL7 (POWER9)',
        'RHEL5'
      ].each do |rhel_version|
        assert eos_schedule_data.key?(rhel_version)
        assert eos_schedule_data[rhel_version].is_a?(Hash)
      end
      eos_schedule_data.each do |_, schedule|
        assert schedule.is_a?(Hash)
        %w[full_support maintenance_support].each { |support_category| assert schedule.key?(support_category) }
        schedule.each do |support_category, end_time|
          assert end_time.is_a?(Time)
          assert_includes %w[full_support maintenance_support extended_support], support_category
        end
      end
    end

    def test_to_status
      assert_equal Katello::RhelLifecycleStatus::UNKNOWN, status.to_status
    end

    def test_to_status_non_rhel
      os.hosts << host
      host.operatingsystem.update(:name => "CentOS_Stream")
      assert_equal Katello::RhelLifecycleStatus::UNKNOWN, status.to_status
    end

    def fake_full_support_end_date(date)
      Katello::RhelLifecycleStatus::RHEL_EOS_SCHEDULE_INDEXES[release].expects(:[]).with("full_support").at_least_once.returns(date)
    end

    def fake_maintenance_support_end_date(date)
      Katello::RhelLifecycleStatus::RHEL_EOS_SCHEDULE_INDEXES[release].expects(:[]).with("maintenance_support").at_least_once.returns(date)
    end

    def fake_extended_support_end_date(date)
      Katello::RhelLifecycleStatus::RHEL_EOS_SCHEDULE_INDEXES[release].expects(:[]).with("extended_support").at_least_once.returns(date)
    end

    def test_to_status_full_support
      os.hosts << host
      host.operatingsystem.update(:name => "RedHat", :major => "9", :minor => "0")
      host.operatingsystem.expects(:rhel_eos_schedule_index).returns(release)
      fake_full_support_end_date(Date.today + 2.years)
      fake_extended_support_end_date(Date.today + 10.years)
      assert_equal Katello::RhelLifecycleStatus::FULL_SUPPORT, status.to_status
    end

    def test_to_status_maintenance_support
      os.hosts << host
      host.operatingsystem.update(:name => "RedHat", :major => "9", :minor => "0")
      host.operatingsystem.expects(:rhel_eos_schedule_index).returns(release)
      fake_full_support_end_date(Date.today - 1.year)
      fake_maintenance_support_end_date(Date.today + 1.year)
      fake_extended_support_end_date(Date.today + 10.years)
      assert_equal Katello::RhelLifecycleStatus::MAINTENANCE_SUPPORT, status.to_status
    end

    def test_to_status_approaching_end_of_support
      os.hosts << host
      host.operatingsystem.update(:name => "RedHat", :major => "9", :minor => "0")
      host.operatingsystem.expects(:rhel_eos_schedule_index).returns(release)
      fake_full_support_end_date(Date.today - 5.years)
      fake_maintenance_support_end_date(Date.today - 3.years)
      fake_extended_support_end_date(Date.today + 10.days)
      assert_equal Katello::RhelLifecycleStatus::APPROACHING_END_OF_SUPPORT, status.to_status
    end

    def test_to_status_extended_support
      os.hosts << host
      host.operatingsystem.update(:name => "RedHat", :major => "9", :minor => "0")
      host.operatingsystem.expects(:rhel_eos_schedule_index).returns(release)
      fake_full_support_end_date(Date.today - 5.years)
      fake_maintenance_support_end_date(Date.today - 3.years)
      fake_extended_support_end_date(Date.today + 2.years)
      assert_equal Katello::RhelLifecycleStatus::EXTENDED_SUPPORT, status.to_status
    end

    def test_to_status_support_ended
      os.hosts << host
      host.operatingsystem.update(:name => "RedHat", :major => "9", :minor => "0")
      host.operatingsystem.expects(:rhel_eos_schedule_index).returns(release)
      fake_full_support_end_date(Date.today - 5.years)
      fake_maintenance_support_end_date(Date.today - 3.years)
      fake_extended_support_end_date(Date.today - 1.year)
      assert_equal Katello::RhelLifecycleStatus::SUPPORT_ENDED, status.to_status
    end

    def test_full_support_end_date
      fake_full_support_end_date(Date.today + 2.years)
      assert_equal Date.today + 2.years, Katello::RhelLifecycleStatus.full_support_end_date(eos_schedule_index: release)
    end

    def test_maintenance_support_end_date
      fake_maintenance_support_end_date(Date.today + 2.years)
      assert_equal Date.today + 2.years, Katello::RhelLifecycleStatus.maintenance_support_end_date(eos_schedule_index: release)
    end

    def test_extended_support_end_date
      fake_extended_support_end_date(Date.today + 2.years)
      assert_equal Date.today + 2.years, Katello::RhelLifecycleStatus.extended_support_end_date(eos_schedule_index: release)
    end

    def test_eos_date
      fake_extended_support_end_date(Date.today + 2.years)
      assert_equal Date.today + 2.years, Katello::RhelLifecycleStatus.eos_date(eos_schedule_index: release)
    end

    def test_eos_date_no_extended_support
      fake_maintenance_support_end_date(Date.today + 2.years)
      Katello::RhelLifecycleStatus::RHEL_EOS_SCHEDULE_INDEXES[release].expects(:[]).with("extended_support").returns(nil)
      assert_equal Date.today + 2.years, Katello::RhelLifecycleStatus.eos_date(eos_schedule_index: release)
    end

    def test_warn_date
      fake_extended_support_end_date(Date.today + 2.years)
      assert_equal Date.today + 2.years - Katello::RhelLifecycleStatus::EOS_WARNING_THRESHOLD, Katello::RhelLifecycleStatus.warn_date(eos_schedule_index: release)
    end

    def test_relevant
      os.hosts << host
      assert status.relevant?
    end

    def test_relevant_non_rhel
      os.update(:name => "CentOS_Stream")
      os.hosts << host
      refute status.relevant?
    end
  end
end
