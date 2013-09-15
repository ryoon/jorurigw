class Gw::Public::AdminSettingsController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold
  end

  def index
    uid = Site.user.id
    @role_developer    = System::User.is_dev?
    @role_admin        = System::Model::Role.get(1,uid,'_admin','admin')
    editor_users       = System::Model::Role.get(1, uid,'system_users','editor')
    editor_tabs        = System::Model::Role.get(1, uid ,'edit_tab', 'editor')
    editor_rss         = System::Model::Role.get(1, uid ,'rss_reader', 'admin')
    editor_blogparts   = System::Model::Role.get(1, uid ,'blog_part', 'admin')
    editor_ind_portals = System::Model::Role.get(1, uid ,'ind_portal', 'admin')
    @role_editor = editor_users || editor_tabs || editor_rss || editor_blogparts || editor_ind_portals
    @u_role = @role_developer || @role_admin || @role_editor
    return authentication_error(403) unless @u_role == true
  end

end
