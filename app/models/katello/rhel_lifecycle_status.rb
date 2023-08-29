module Katello
  class RhelLifecycleStatus < HostStatus::Status
    UNKNOWN = 0
    FULL_SUPPORT = 1
    MAINTENANCE_SUPPORT = 2
    EXTENDED_SUPPORT = 3
    APPROACHING_END_OF_SUPPORT = 4
    SUPPORT_ENDED = 5

    def self.end_of_day(date)
      DateTime.parse(date.to_s).end_of_day.utc
    end

    RHEL_EOS_SCHEDULE = { # dates that each support category ends
      'RHEL9' => {
        'full_support' => end_of_day('2027-05-31'),
        'maintenance_support' => end_of_day('2032-05-31'),
        'extended_support' => end_of_day('2035-05-31')
      },
      'RHEL8' => {
        'full_support' => end_of_day('2024-05-31'),
        'maintenance_support' => end_of_day('2029-05-31'),
        'extended_support' => end_of_day('2032-05-31')
      },
      'RHEL7' => {
        'full_support' => end_of_day('2019-08-06'),
        'maintenance_support' => end_of_day('2024-06-30'),
        'extended_support' => end_of_day('2028-06-30')
      },
      'RHEL7 (System z (Structure A))' => {
        'full_support' => end_of_day('2019-08-06'),
        'maintenance_support' => end_of_day('2021-05-31')
      },
      'RHEL7 (ARM)' => {
        'full_support' => end_of_day('2019-08-06'),
        'maintenance_support' => end_of_day('2020-11-30')
      },
      'RHEL7 (POWER9)' => {
        'full_support' => end_of_day('2019-08-06'),
        'maintenance_support' => end_of_day('2021-05-31')
      },
      'RHEL6' => {
        'full_support' => end_of_day('2016-05-10'),
        'maintenance_support' => end_of_day('2020-11-30'),
        'extended_support' => end_of_day('2024-06-30')
      },
      'RHEL5' => {
        'full_support' => end_of_day('2013-01-08'),
        'maintenance_support' => end_of_day('2017-03-31'),
        'extended_support' => end_of_day('2020-11-30')
      }
    }.freeze

    EOS_WARNING_THRESHOLD = 1.year

    def self.status_map
      map = {
        full_support: FULL_SUPPORT,
        maintenance_support: MAINTENANCE_SUPPORT,
        extended_support: EXTENDED_SUPPORT,
        approaching_end_of_support: APPROACHING_END_OF_SUPPORT,
        support_ended: SUPPORT_ENDED
      }

      map.default = UNKNOWN
      map
    end

    def self.to_status(operatingsystem: nil)
      return UNKNOWN unless operatingsystem.is_a?(::Operatingsystem)
      release = operatingsystem.rhel_eos_schedule_index
      approach_date = warn_date(eos_schedule_index: release)
      end_of_support_date = eos_date(eos_schedule_index: release)
      return UNKNOWN unless release
      return UNKNOWN if RHEL_EOS_SCHEDULE[release].nil?
      return FULL_SUPPORT if Date.today <= RHEL_EOS_SCHEDULE[release]['full_support']
      return MAINTENANCE_SUPPORT if Date.today <= RHEL_EOS_SCHEDULE[release]['maintenance_support']
      if approach_date.present? && Date.today >= approach_date && Date.today <= end_of_support_date
        return APPROACHING_END_OF_SUPPORT
      end
      return EXTENDED_SUPPORT if Date.today <= end_of_support_date
      return SUPPORT_ENDED
    end

    def self.status_name
      N_('RHEL lifecycle')
    end

    def self.humanized_name
      'rhel_lifecycle'
    end

    def self.full_support_end_date(eos_schedule_index: nil)
      return nil unless eos_schedule_index
      RHEL_EOS_SCHEDULE[eos_schedule_index]&.[]('full_support')
    end

    def self.maintenance_support_end_date(eos_schedule_index: nil)
      return nil unless eos_schedule_index
      RHEL_EOS_SCHEDULE[eos_schedule_index]&.[]('maintenance_support')
    end

    def self.extended_support_end_date(eos_schedule_index: nil)
      return nil unless eos_schedule_index
      RHEL_EOS_SCHEDULE[eos_schedule_index]&.[]('extended_support')
    end

    def self.eos_date(eos_schedule_index: nil)
      return nil unless eos_schedule_index
      RHEL_EOS_SCHEDULE[eos_schedule_index]&.[]('extended_support') ||
        RHEL_EOS_SCHEDULE[eos_schedule_index]&.[]('maintenance_support')
    end

    def self.warn_date(eos_schedule_index: nil)
      return nil unless eos_schedule_index
      end_of_support_date = eos_date(eos_schedule_index: eos_schedule_index)
      return nil unless end_of_support_date
      eos_date(eos_schedule_index: eos_schedule_index) - EOS_WARNING_THRESHOLD
    end

    def self.to_label(status, eos_date: nil)
      case status
      when FULL_SUPPORT
        N_('Full support')
      when MAINTENANCE_SUPPORT
        N_('Maintenance support')
      when EXTENDED_SUPPORT
        N_('Extended support')
      when APPROACHING_END_OF_SUPPORT
        if eos_date.present?
          N_('Approaching end of support (%s)') % eos_date.strftime('%Y-%m-%d')
        else
          N_('Approaching end of support')
        end
      when SUPPORT_ENDED
        N_('Support ended')
      else
        N_('Unknown')
      end
    end

    def to_label(_options = {})
      self.class.to_label(status, eos_date: eos_date)
    end

    def eos_date
      self.class.eos_date(eos_schedule_index: rhel_eos_schedule_index)
    end

    def warn_date
      self.class.warn_date(eos_schedule_index: rhel_eos_schedule_index)
    end

    def rhel_eos_schedule_index
      host&.operatingsystem&.rhel_eos_schedule_index(arch_name: host&.arch&.name)
    end

    def to_global(_options = {})
      if [FULL_SUPPORT, MAINTENANCE_SUPPORT, EXTENDED_SUPPORT].include?(status)
        ::HostStatus::Global::OK
      elsif [APPROACHING_END_OF_SUPPORT].include?(status)
        ::HostStatus::Global::WARN
      elsif [SUPPORT_ENDED].include?(status)
        ::HostStatus::Global::ERROR
      else
        ::HostStatus::Global::OK
      end
    end

    def to_status(operatingsystem: nil)
      self.class.to_status(operatingsystem: operatingsystem || self.host&.operatingsystem)
    end

    # this status is only relevant for RHEL
    def relevant?(_options = {})
      host&.operatingsystem&.rhel_eos_schedule_index
    end
  end
end
