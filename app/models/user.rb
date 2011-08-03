#
# Copyright 2011 Red Hat, Inc.
#
# This software is licensed to you under the GNU General Public
# License as published by the Free Software Foundation; either version
# 2 of the License (GPLv2) or (at your option) any later version.
# There is NO WARRANTY for this software, express or implied,
# including the implied warranties of MERCHANTABILITY,
# NON-INFRINGEMENT, or FITNESS FOR A PARTICULAR PURPOSE. You should
# have received a copy of GPLv2 along with this software; if not, see
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.

require 'ldap'
require 'util/threadsession'
require 'util/password'

class User < ActiveRecord::Base
  has_and_belongs_to_many :roles
  belongs_to :own_role, :class_name => 'Role'
  has_many :help_tips
  has_many :user_notices
  has_many :notices, :through => :user_notices
  has_many :search_favorites, :dependent => :destroy
  has_many :search_histories, :dependent => :destroy
  has_and_belongs_to_many :organizations


  validates :username, :uniqueness => true, :presence => true, :username => true
  validate :own_role_included_in_roles

  # check if the role does not already exist for new username
  validates_each :username do |model, attr, value|
    if model.new_record? and Role.find_by_name(value)
      model.errors.add(:username, "role with the same name '#{value}' already exists")
    end
  end


  scoped_search :on => :username, :complete_value => true, :rename => :name
  scoped_search :in => :roles, :on => :name, :complete_value => true, :rename => :role

  # validate the password length before hashing
  validates_each :password do |model, attr, value|
    if model.password_changed?
      model.errors.add(attr, "at least 5 characters") if value.length < 5
    end
  end

  # hash the password before creating or updateing the record
  before_save do |u|
    u.password = Password::update(u.password) if u.password.length != 192
  end

  # create own role for new user
  after_create do |u|
    if u.own_role.nil?
      # create the own_role where the name will be a string consisting of username and 20 random chars
      r = Role.create!(:name => "#{u.username}_#{Password.generate_random_string(20)}")
      u.roles << r unless u.roles.include? r
      u.own_role = r
      u.save!
    end
  end

  # destroy own role for user
  before_destroy do |u|
    u.own_role.destroy
    unless u.own_role.destroyed?
      Rails.logger.error error.to_s
    end
  end

  # support for session (thread-local) variables
  include Katello::ThreadSession::UserModel
  include Ldap

  # return the special "nobody" user account
  def self.anonymous
    find_by_username('anonymous')
  end

  def self.authenticate!(username, password)
    u = User.where({:username => username}).first
    # check if user exists
    return nil unless u
    # check if not disabled
    return nil if u.disabled
    # check if hash is valid
    return nil unless Password.check(password, u.password)
    u
  end

  def self.authenticate_using_ldap!(username, password)
    if Ldap.valid_ldap_authentication? username, password
      User.new :username => username
    else
      nil
    end
  end

  # Return true if the user is allowed to do the specified action for a resource type
  # verb/action can be:
  # * a parameter-like Hash (eg. :controller => 'projects', :action => 'edit')
  # * a permission Symbol (eg. :edit_project)
  #
  # This method is called by every protected controller.
  def allowed_to?(verbs, resource_type, tags = nil, org = nil)
    Rails.logger.debug "Checking if user #{username} is allowed to #{verbs} in #{resource_type.inspect} scoped #{tags.inspect} in organization #{org}"
    return false if roles.empty?

    verbs = [] if verbs.nil?
    verbs = [verbs] unless verbs.is_a? Array
    verbs = verbs.collect {|verb| action_to_verb(verb, resource_type)}
    org_clause = "permissions.organization_id is null"
    org_clause = org_clause + " OR permissions.organization_id = :organization_id " if org
    org_hash = {}
    org_hash = {:organization_id => org.id} if org
    org_permissions = Permission.joins(:role).joins(
                  "INNER JOIN roles_users ON roles_users.role_id = roles.id").joins(
                  "left outer join permissions_verbs on permissions.id = permissions_verbs.permission_id").joins(
                  "left outer join verbs on verbs.id = permissions_verbs.verb_id").where(
                      org_clause, org_hash).where({"roles_users.user_id" => id})

    clause_all_resources_or_tags = %{permissions.resource_type_id is null OR
          (permissions.resource_type_id = (select id from resource_types where resource_types.name = :resource_type) AND
           (permissions.all_verbs=:true OR verbs.verb in (:verbs)) AND
            permissions.all_tags = :true
          )}.split.join(" ")
    clause_params = {:true => true, :resource_type=>resource_type, :verbs=> verbs}
    return true  unless org_permissions.where(clause_all_resources_or_tags, clause_params ).count == 0


    tags = [] if tags.nil?
    tags = [tags] unless tags.is_a? Array

    clause = %{permissions.resource_type_id = (select id from resource_types where resource_types.name = :resource_type) AND
    (permissions.all_verbs=:true OR verbs.verb in (:verbs))}.split.join(" ")

    if tags.empty?
      to_count = "verbs.verb"
    else
      to_count = "tags.name"
    end
    query = org_permissions.joins("left outer join permissions_tags on permissions.id = permissions_tags.permission_id").joins(
                    "left outer join tags on tags.id = permissions_tags.tag_id").where(clause, clause_params)

    query = query.where({:tags=> {:name=> tags.collect{|tg| tg.to_s}}}) unless tags.empty?
    count = query.count(to_count, :distinct => true)
    if tags.empty?
      return count > 0
    else
      return tags.length == count
    end
  end

  # Class method that has the same functionality as allowed_to? method but operates
  # on the current logged user. The class attribute User.current must be set!
  # If the current user is not set (is nil) it treats it like the 'anonymous' user.
  def self.allowed_to?(verb, resource_type = nil, tags = nil)
    u = User.current
    u = User.anonymous if u.nil?
    raise ArgumentError, "current user is not set" if u.nil? or not u.is_a? User
    u.allowed_to?(verb, resource_type, tags)
  end

  # Class method with the very same functionality as allowed_to? but throws
  # SecurityViolation exception leading to the denial page.
  def self.allowed_to_or_error?(verb, resource_type = nil, tags = nil)
    u = User.current
    raise ArgumentError, "current user is not set" if u.nil? or not u.is_a? User
    unless u.allowed_to?(verb, resource_type, tags)
      msg = "User #{u.username} is not allowed to #{verb} in #{resource_type} using #{tags}"
      Rails.logger.error msg
      raise Errors::SecurityViolation, msg
    end
  end

  # Create permission for the user's own role - for more info see Role.allow
  def allow(verb, resource_type, tags = nil)
    raise ArgumentError, "user has no own role" if own_role.nil? or not own_role.is_a? Role
    own_role.allow(verb, resource_type, tags)
  end

  # Delete permission for the user's own role - for more info see Role.allow
  def disallow(verb, resource_type, tags)
    raise ArgumentError, "user has no own role" if own_role.nil? or not own_role.is_a? Role
    own_role.disallow(verb, resource_type, tags)
  end

  def disable_helptip(key)
    return if !self.helptips_enabled? #don't update helptips if user has it disabled
    return if not HelpTip.where(:key => key, :user_id => self.id).empty?
    help = HelpTip.new
    help.key = key
    help.user = self
    help.save
  end

  #Remove up to 5 un-viewed notices
  def pop_notices
    to_ret = user_notices.where(:viewed=>false).limit(5)
    to_ret.each{|item| item.update_attributes!(:viewed=>false)}
    to_ret.collect{|notice| {:text=>notice.notice.text, :level=>notice.notice.level}}
  end

  def enable_helptip(key)
    return if !self.helptips_enabled? #don't update helptips if user has it disabled
    help =  HelpTip.where(:key => key, :user_id => self.id).first
    return if help.nil?
    help.destroy
  end

  def clear_helptips
    HelpTip.destroy_all(:user_id=>self.id)
  end

  def helptip_enabled?(key)
    return self.helptips_enabled && HelpTip.where(:key => key, :user_id => self.id).first.nil?
  end

  def defined_roles
    self.roles - [self.own_role]
  end

  def defined_role_ids
    self.role_ids - [self.own_role_id]
  end

  def cp_oauth_header
    { 'cp-user' => self.username }
  end

  def pulp_oauth_header
    { 'pulp-user' => self.username }
  end


  def self.list_verbs
    {
    :create => N_("Create Users"),
    :read => N_("Access Users"),
    :update => N_("Update Users"),
    :delete => N_("Delete Users")
    }.with_indifferent_access
  end

  protected

  def own_role_included_in_roles
    unless own_role.nil?
      errors.add(:own_role, 'own role must be included in roles') unless roles.include? own_role
    end
  end

  DEFAULT_VERBS = {
    :destroy => 'delete', :destroy_favorite => 'delete'
  }.with_indifferent_access

  ACTION_TO_VERB = {
    :owners => {:import_status => 'read'},
  }.with_indifferent_access

  def action_to_verb(verb, type)
    return ACTION_TO_VERB[type][verb] if ACTION_TO_VERB[type] and ACTION_TO_VERB[type][verb]
    return DEFAULT_VERBS[verb] if DEFAULT_VERBS[verb]
    return verb
  end

end
